//
//  GameScene.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Primary gameplay scene. Orchestrates all game systems — physics, player
//  movement, obstacle spawning, scoring, and the full visual-effects stack —
//  through a four-phase state machine (tutorial → running → paused → gameOver).
//
//  GAME STATE MACHINE
//  .tutorial   — physics paused; ModernStartButton visible; player frozen
//  .running    — full gameplay; all systems active
//  .paused     — physics paused; tap anywhere to resume
//  .gameOver   — effects play, high scores saved, transitions to GameOverScene
//
//  KEY SYSTEMS
//  - ParallaxBackground + NebulaSystem  — 5-layer scrolling backdrop with star streaks
//  - DynamicLighting                    — real-time coloured light sources
//  - EnhancedParticleManager            — multi-intensity explosions and star bursts
//  - CameraEffects                      — screen shake, dash zoom, slow-motion
//  - AnimationController                — ambient UI micro-animations
//  - GameAudio (spatial)                — distance-attenuated sound effects
//  - StatusBar (glass HUD)              — score, lives, stars, tier, power-up, pause
//  - MeteorController                   — tiered obstacle spawning (meteors, swarms, lasers)
//  - PowerUpController                  — shield / magnet / slow-mo power-up lifecycle
//  - AccessibilityManager               — haptic feedback on all gameplay events
//
//  PROGRESSION
//  - Score thresholds 500/1500/3000 advance tiers 1–4
//  - Boss wave triggers every 1000 points (15s, 1.8× speed, +100 survival bonus)
//
//  POWER-UPS
//  - Shield: blocks damage; dash+shield = dash kill (+10 score)
//  - Magnet: stars pulled toward ship each frame
//  - Slow-Mo: physicsWorld.speed = 0.4 for duration
//
//  TOUCH HANDLING
//  - Tutorial phase: tap anywhere in startButton.tapRect to start
//  - Running phase:  tap pauseButton to pause; elsewhere to redirect player
//  - Paused phase:   any tap resumes
//
//  REQUIRES iOS 18.0+  — uses @Observable, @MainActor, and modern concurrency
//

import SpriteKit
import OSLog
import Observation

@available(iOS 18.0, *)
@MainActor
final class GameScene: SKScene, @preconcurrency SKPhysicsContactDelegate {
    
    // MARK: - Game State
    @Observable
    final class GameState {
        enum Phase {
            case tutorial
            case running
            case paused
            case gameOver
        }
        
        var currentPhase: Phase = .tutorial
        var score: Int = 0
        var lives: Int = 3
        var starsCollected: Int = 0
        var isGameActive: Bool { currentPhase == .running }
    }
    
    // MARK: - Properties
    private(set) var gameState = GameState()
    private let gameSettings = GameSettings.shared
    private let audioManager = GameAudio.shared
    private let accessibilityManager = AccessibilityManager.shared
    
    // Enhanced Scene Nodes
    private let gameNode = SKNode()
    private let interfaceNode = SKNode()
    private let effectsNode = SKNode()
    private let lightingNode = SKNode()
    
    // Background System
    private let background = Background()
    private let parallaxBackground = ParallaxBackground()
    private let nebulae = NebulaSystem()
    
    // UI Elements with Modern Design
    private let startButton = ModernStartButton()
    private let player = Player()
    private let meteorController = MeteorController()
    private let starController = StarController()
    private let powerUpController = PowerUpController()
    private var statusBar: StatusBar!

    // Pause overlay
    private var pauseOverlay: SKNode?
    private var pauseResumeRect: CGRect = .zero
    private var pauseMenuRect:   CGRect = .zero

    // Progression & boss wave
    private var currentTier: Int = 1
    private var bossWaveActive: Bool = false
    private var bossWaveTimer: TimeInterval = 0
    private var lastBossScore: Int = 0
    private let bossWaveDuration: TimeInterval = 15.0
    
    // Visual Effects
    private let screenFlash = SKSpriteNode()
    private let dynamicLighting = DynamicLighting()
    private let cameraEffects = CameraEffects()
    
    // Animation Controllers
    private let animationController = AnimationController()
    private let particleManager = EnhancedParticleManager()

    // Motion / tilt navigation
    private let motionController = MotionController.shared
    
    private var lastUpdateTime: TimeInterval = 0.0
    private var frameCount: TimeInterval = 0.0

    // Double-tap tracking for dash
    private var lastTapTime: TimeInterval = 0
    private var lastTapLocation: CGPoint = .zero

    // Touch-circle toggle — tap rect in scene coordinates, active during tutorial
    private var touchToggleRect: CGRect = .zero

    private let logger = Logger(subsystem: "com.todddube.spacerunner", category: "GameScene")
    
    // MARK: - Notification Names
    private enum NotificationName {
        static let pauseGame = Notification.Name("PauseGame")
        static let resumeGame = Notification.Name("ResumeGame")
    }
    
    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(size: CGSize) {
        super.init(size: size)
    }
    
    override func didMove(to view: SKView) {
        setupScene()
        setupNotifications()
        logger.info("GameScene initialized and moved to view")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        logger.info("GameScene deinitialized")
    }
    
    // MARK: - Setup
    private func setupScene() {
        backgroundColor = UIColor(red: 0.039, green: 0.039, blue: 0.102, alpha: 1.0) // #0A0A1A arcade deep blue
        setupPhysics()
        setupNodes()
        setupVisualEffects()
        setupInterface()
        setupAccessibility()

        // Initialize game state
        gameState.lives = player.lives
        gameState.score = player.score
        gameState.starsCollected = 0

        // Skip tutorial — go straight to gameplay; menu already showed controls info
        setCurrentPhase(.running)
    }
    
    private func setupPhysics() {
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        physicsWorld.speed = 1.0
    }
    
    private func setupNodes() {
        // Game world setup
        addChild(gameNode)
        gameNode.zPosition = GameLayer.Background

        // Effects layer for particles and lighting
        addChild(effectsNode)
        effectsNode.zPosition = GameLayer.Background - 1

        // Lighting system
        addChild(lightingNode)
        lightingNode.zPosition = GameLayer.Background + 0.5
        lightingNode.addChild(dynamicLighting)

        // Background layers
        background.zPosition = GameLayer.Background
        gameNode.addChild(background)

        parallaxBackground.setupLayers(for: size)
        parallaxBackground.zPosition = GameLayer.Background + 0.1
        gameNode.addChild(parallaxBackground)

        nebulae.setupNebulae(for: size)
        nebulae.zPosition = GameLayer.Background + 0.2
        gameNode.addChild(nebulae)

        // Player
        player.position = CGPoint(x: kViewSize.width / 2, y: kViewSize.height * 0.15)
        player.zPosition = GameLayer.Player
        player.setupEnhancedEngineEffects()
        let playerLight = dynamicLighting.addLight(at: player.position,
                                                   color: .cyan,
                                                   intensity: 0.8,
                                                   radius: 150)
        playerLight.name = "playerLight"
        gameNode.addChild(player)

        // Controllers
        gameNode.addChild(meteorController)
        gameNode.addChild(starController)
        gameNode.addChild(powerUpController)

        // Audio
        audioManager.playBackgroundMusic()
    }

    private func setupVisualEffects() {
        // Screen flash for dramatic effects
        screenFlash.texture = nil
        screenFlash.color = .white
        screenFlash.alpha = 0.0
        screenFlash.size = size
        screenFlash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        screenFlash.zPosition = GameLayer.Interface + 10
        addChild(screenFlash)
        
        // Setup particle manager
        particleManager.setupForScene(self)
        
        // Initialize camera effects
        cameraEffects.setupForScene(self)
    }
    
    private func setupInterface() {
        // Add interface node
        addChild(interfaceNode)
        interfaceNode.zPosition = GameLayer.Interface
        
        // Setup modern start button with glass effect
        startButton.position = CGPoint(x: kViewSize.width / 2, y: kViewSize.height / 2)
        startButton.zPosition = GameLayer.Interface
        startButton.setupGlassEffect()
        interfaceNode.addChild(startButton)
        
        // Setup status bar — top-of-screen glass HUD
        let safeAreaTop = self.view?.safeAreaInsets.top ?? 44
        statusBar = StatusBar(lives: gameState.lives, score: gameState.score, stars: gameState.starsCollected, safeAreaTop: safeAreaTop)
        statusBar.position  = CGPoint.zero
        statusBar.zPosition = GameLayer.Interface
        statusBar.alpha     = 0  // show() animates it in from above
        interfaceNode.addChild(statusBar)
        
        // Add ambient UI animations
        animationController.startAmbientUIAnimations(for: interfaceNode)
    }
    
    private func setupAccessibility() {
        accessibilityLabel = "SpaceRunner Game Scene"
        isAccessibilityElement = false
        
        // Configure child element accessibility
        gameNode.accessibilityLabel = "Game World"
        interfaceNode.accessibilityLabel = "Game Interface"
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pauseGame),
            name: NotificationName.pauseGame,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(resumeGame),
            name: NotificationName.resumeGame,
            object: nil
        )
    }

    // MARK: - Game State Management
    private func setCurrentPhase(_ phase: GameState.Phase) {
        let previousPhase = gameState.currentPhase
        gameState.currentPhase = phase
        
        switch phase {
        case .tutorial:
            showTutorial()
        case .running:
            // Check if we're resuming from pause or starting fresh
            if previousPhase == .paused {
                resumeGameplay()
            } else {
                startGame()
            }
        case .paused:
            pauseGameplay()
        case .gameOver:
            endGame()
        }
        
        logger.info("Game phase changed from \(String(describing: previousPhase)) to: \(String(describing: phase))")
    }
    
    private func showTutorial() {
        startButton.show(with: .springAnimation)
        statusBar.hide(with: .fadeOut)
        
        // Pause physics
        physicsWorld.speed = 0.0
        
        // Show tutorial elements with enhanced animations
        player.disableMovement()
        
        // Add tutorial visual hints
        showTutorialHints()
    }
    
    private func showTutorialHints() {
        // Create pulsing tutorial hint
        let hint = createTutorialHint()
        hint.position = CGPoint(x: size.width / 2, y: size.height * 0.3)
        hint.name = "tutorialHint"
        interfaceNode.addChild(hint)

        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.8),
            SKAction.scale(to: 0.9, duration: 0.8)
        ])
        hint.run(SKAction.repeatForever(pulse))

        // Touch-circle toggle pill — bottom of screen
        addTouchToggle()
    }

    // MARK: - Touch-Circle Toggle

    private func addTouchToggle() {
        let pill = buildTouchTogglePill()
        let pillY = kViewSize.height * 0.10
        pill.position = CGPoint(x: kViewSize.width / 2, y: pillY)
        pill.name = "touchToggle"
        pill.zPosition = GameLayer.Interface
        pill.alpha = 0
        interfaceNode.addChild(pill)
        pill.run(SKAction.fadeIn(withDuration: 0.35))

        let pillW: CGFloat = 210, pillH: CGFloat = 40
        touchToggleRect = CGRect(
            x: kViewSize.width / 2 - pillW / 2,
            y: pillY - pillH / 2,
            width: pillW, height: pillH
        )
    }

    private func buildTouchTogglePill() -> SKNode {
        let isOn = gameSettings.showTouchCircles
        let w: CGFloat = 210, h: CGFloat = 40, r: CGFloat = h / 2

        let container = SKNode()

        // Background capsule
        let bg = SKShapeNode(rect: CGRect(x: -w / 2, y: -h / 2, width: w, height: h),
                             cornerRadius: r)
        bg.fillColor = isOn
            ? SKColor(red: 0.00, green: 0.90, blue: 1.00, alpha: 0.15)
            : SKColor(white: 1.0, alpha: 0.06)
        bg.strokeColor = isOn
            ? SKColor(red: 0.00, green: 0.90, blue: 1.00, alpha: 0.75)
            : SKColor(white: 1.0, alpha: 0.20)
        bg.lineWidth = 1.2
        container.addChild(bg)

        // Icon dot + label
        let dot   = isOn ? "●" : "○"
        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = "\(dot)  /nTOUCH CIRCLES"
        label.fontSize = 14
        label.fontColor = isOn
            ? SKColor(red: 0.00, green: 0.90, blue: 1.00, alpha: 1.0)
            : SKColor(white: 0.55, alpha: 1.0)
        label.verticalAlignmentMode   = .center
        label.horizontalAlignmentMode = .center
        container.addChild(label)

        return container
    }

    private func refreshTouchToggle() {
        guard let old = interfaceNode.childNode(withName: "touchToggle") else { return }
        let pos = old.position
        old.removeFromParent()

        let pill = buildTouchTogglePill()
        pill.position = pos
        pill.name = "touchToggle"
        pill.zPosition = GameLayer.Interface
        interfaceNode.addChild(pill)

        // Quick bounce
        pill.setScale(0.88)
        pill.run(SKAction.sequence([
            SKAction.scale(to: 1.10, duration: 0.10),
            SKAction.scale(to: 1.00, duration: 0.08)
        ]))
    }
    
    private func createTutorialHint() -> SKNode {
        let container = SKNode()

        // Hand tap icon — emoji label, no image asset required
        let handTap = SKLabelNode(text: "👆")
        handTap.fontSize = kViewSize.width * 0.10
        handTap.horizontalAlignmentMode = .center
        handTap.verticalAlignmentMode = .center
        handTap.alpha = 0.8
        handTap.position = CGPoint(x: 0, y: 30)
        container.addChild(handTap)

        // Glow behind icon
        let glow = SKLabelNode(text: "👆")
        glow.fontSize = handTap.fontSize * 1.2
        glow.horizontalAlignmentMode = .center
        glow.verticalAlignmentMode = .center
        glow.alpha = 0.3
        glow.zPosition = -1
        glow.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 1.0),
            SKAction.fadeAlpha(to: 0.1, duration: 1.0)
        ])))
        container.addChild(glow)

        // "TAP to steer" label
        let tapLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        tapLabel.text = "TAP to steer"
        tapLabel.fontSize = 18
        tapLabel.fontColor = SKColor.white.withAlphaComponent(0.85)
        tapLabel.horizontalAlignmentMode = .center
        tapLabel.position = CGPoint(x: 0, y: -5)
        container.addChild(tapLabel)

        // Divider
        let divider = SKLabelNode(fontNamed: "AvenirNext-Medium")
        divider.text = "— or —"
        divider.fontSize = 14
        divider.fontColor = SKColor.cyan.withAlphaComponent(0.6)
        divider.horizontalAlignmentMode = .center
        divider.position = CGPoint(x: 0, y: -26)
        container.addChild(divider)

        // "TILT phone to navigate" label
        let tiltLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        tiltLabel.text = "TILT phone to navigate"
        tiltLabel.fontSize = 18
        tiltLabel.fontColor = SKColor.cyan.withAlphaComponent(0.85)
        tiltLabel.horizontalAlignmentMode = .center
        tiltLabel.position = CGPoint(x: 0, y: -48)
        container.addChild(tiltLabel)

        // Animate the tilt label with a subtle horizontal sway hint
        let swayRight = SKAction.moveBy(x: 6, y: 0, duration: 0.9)
        swayRight.timingMode = .easeInEaseOut
        let swayLeft = SKAction.moveBy(x: -6, y: 0, duration: 0.9)
        swayLeft.timingMode = .easeInEaseOut
        tiltLabel.run(SKAction.repeatForever(SKAction.sequence([swayRight, swayLeft])))

        return container
    }
    
    private func startGame() {
        // Hide tutorial elements with smooth transitions
        startButton.hide(with: .scaleDown)
        statusBar.show(with: .slideFromTop)
        
        // Remove tutorial hints and toggle
        interfaceNode.children
            .filter { $0.name == "tutorialHint" || $0.name == "touchToggle" }
            .forEach { node in
                node.run(SKAction.sequence([
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.removeFromParent()
                ]))
            }
        touchToggleRect = .zero
        
        // Resume physics with smooth acceleration
        let accelerate = SKAction.customAction(withDuration: 1.0) { [weak self] _, elapsedTime in
            let progress = elapsedTime / 1.0
            self?.physicsWorld.speed = CGFloat(progress)
        }
        run(accelerate)
        
        // Start gameplay with enhanced effects
        player.enableMovement()
        player.startEnhancedEngineEffects()
        meteorController.startSendingMeteors()
        starController.startSendingStars()
        powerUpController.startSpawning()
        motionController.startMotionUpdates()
        currentTier = 1
        lastBossScore = 0
        
        // Update dynamic lighting
        dynamicLighting.transitionToGameplay()
        
        // Start parallax background
        parallaxBackground.startScrolling()
        nebulae.startAnimation()
        
        updateStatusBar()
        
        // Camera shake for dramatic start
        cameraEffects.performGameStartShake()
    }
    
    private func pauseGameplay() {
        physicsWorld.speed = 0.0
        meteorController.stopSendingMetors()
        starController.stopSendingStars()
        powerUpController.stopSpawning()
        motionController.stopMotionUpdates()
        audioManager.pauseBackgroundMusic()
        showPauseOverlay()
    }

    private func resumeGameplay() {
        hidePauseOverlay()

        physicsWorld.speed = 1.0
        player.enableMovement()
        meteorController.startSendingMeteors()
        starController.startSendingStars()
        powerUpController.startSpawning()
        motionController.startMotionUpdates()
        audioManager.playBackgroundMusic()
        updateStatusBar()
    }
    
    // MARK: - Pause Overlay

    private func showPauseOverlay() {
        let overlay = SKNode()
        overlay.zPosition = GameLayer.Interface + 10
        overlay.name = "pauseOverlay"

        // Dimmed backdrop
        let backdrop = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.62), size: kViewSize)
        backdrop.position = CGPoint(x: kViewSize.width / 2, y: kViewSize.height / 2)
        overlay.addChild(backdrop)

        let cx = kViewSize.width / 2
        let cy = kViewSize.height / 2

        // "PAUSED" label
        let titleLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLbl.text      = "⏸  PAUSED"
        titleLbl.fontSize  = 26
        titleLbl.fontColor = UIColor(red: 0.00, green: 0.88, blue: 1.00, alpha: 1.0)
        titleLbl.horizontalAlignmentMode = .center
        titleLbl.verticalAlignmentMode   = .center
        titleLbl.position = CGPoint(x: cx, y: cy + 68)
        overlay.addChild(titleLbl)

        // Shared button geometry
        let btnW: CGFloat = 210
        let btnH: CGFloat = 52
        let cornerR: CGFloat = btnH / 2

        // — RESUME button —
        let resumeY = cy + 10
        let resumeBg = SKShapeNode(
            rect: CGRect(x: cx - btnW/2, y: resumeY - btnH/2, width: btnW, height: btnH),
            cornerRadius: cornerR)
        resumeBg.fillColor   = UIColor(red: 0.00, green: 0.88, blue: 1.00, alpha: 0.18)
        resumeBg.strokeColor = UIColor(red: 0.00, green: 0.88, blue: 1.00, alpha: 0.80)
        resumeBg.lineWidth   = 1.5
        overlay.addChild(resumeBg)

        let resumeLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        resumeLbl.text      = "▶   RESUME"
        resumeLbl.fontSize  = 18
        resumeLbl.fontColor = UIColor(red: 0.00, green: 0.88, blue: 1.00, alpha: 1.0)
        resumeLbl.horizontalAlignmentMode = .center
        resumeLbl.verticalAlignmentMode   = .center
        resumeLbl.position = CGPoint(x: cx, y: resumeY)
        overlay.addChild(resumeLbl)

        pauseResumeRect = CGRect(x: cx - btnW/2, y: resumeY - btnH/2, width: btnW, height: btnH)

        // — MENU button —
        let menuY = cy - 58
        let menuBg = SKShapeNode(
            rect: CGRect(x: cx - btnW/2, y: menuY - btnH/2, width: btnW, height: btnH),
            cornerRadius: cornerR)
        menuBg.fillColor   = UIColor.white.withAlphaComponent(0.06)
        menuBg.strokeColor = UIColor.white.withAlphaComponent(0.35)
        menuBg.lineWidth   = 1.5
        overlay.addChild(menuBg)

        let menuLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        menuLbl.text      = "⌂   MAIN MENU"
        menuLbl.fontSize  = 18
        menuLbl.fontColor = UIColor.white.withAlphaComponent(0.85)
        menuLbl.horizontalAlignmentMode = .center
        menuLbl.verticalAlignmentMode   = .center
        menuLbl.position = CGPoint(x: cx, y: menuY)
        overlay.addChild(menuLbl)

        pauseMenuRect = CGRect(x: cx - btnW/2, y: menuY - btnH/2, width: btnW, height: btnH)

        // Fade in
        overlay.alpha = 0
        addChild(overlay)
        pauseOverlay = overlay
        overlay.run(.fadeIn(withDuration: 0.20))
    }

    private func hidePauseOverlay() {
        pauseOverlay?.removeFromParent()
        pauseOverlay    = nil
        pauseResumeRect = .zero
        pauseMenuRect   = .zero
    }

    private func returnToMenu() {
        hidePauseOverlay()
        let menu = EnhancedMenuScene(size: kViewSize)
        view?.presentScene(menu, transition: SKTransition.fade(with: .black, duration: 0.5))
    }

    private func endGame() {
        physicsWorld.speed = 0.0
        meteorController.stopSendingMetors()
        starController.stopSendingStars()
        powerUpController.stopSpawning()
        powerUpController.reset()
        player.hasShield = false
        bossWaveActive = false

        // Enhanced game over effects
        performGameOverEffects()
        
        // Update high scores
        gameSettings.updateBestScore(gameState.score)
        gameSettings.updateBestStars(gameState.starsCollected)
        
        // Show game over elements with enhanced visuals
        player.gameOver()
        player.stopEnhancedEngineEffects()
        meteorController.gameOver()
        starController.gameOver()
        
        // Stop tilt controls
        motionController.stopMotionUpdates()

        // Stop background animations
        parallaxBackground.stopScrolling()

        // Dim lighting for dramatic effect
        dynamicLighting.transitionToGameOver()
        
        // Transition to game over scene after delay
        let waitAction = SKAction.wait(forDuration: 2.0)
        let transitionAction = SKAction.run { [weak self] in
            self?.transitionToGameOver()
        }
        
        run(SKAction.sequence([waitAction, transitionAction]))
    }
    
    private func performGameOverEffects() {
        hidePauseOverlay()
        // Dramatic death flash
        performScreenFlash(color: .white, intensity: 0.6)

        // Camera shake
        cameraEffects.performDeathShake()
        
        // Slow motion effect
        cameraEffects.performSlowMotion(duration: 1.0, factor: 0.2)
        
        // Fade background to grayscale
        let desaturate = SKAction.colorize(with: .gray, colorBlendFactor: 0.8, duration: 1.0)
        background.run(desaturate)
    }
    
    private func transitionToGameOver() {
        guard let view = view else { return }
        
        let gameOverScene = GameOverScene(size: size, score: gameState.score, stars: gameState.starsCollected, streak: 0)
        
        let transition = SKTransition.fade(with: .black, duration: 0.75)
        view.presentScene(gameOverScene, transition: transition)
        
        logger.info("Transitioned to game over scene")
    }
    
    // MARK: - Update Loop
    override func update(_ currentTime: TimeInterval) {
        guard gameState.isGameActive else { return }
        
        let deltaTime = calculateDeltaTime(currentTime)
        frameCount += deltaTime
        
        // Update enhanced visual systems
        parallaxBackground.update(deltaTime: deltaTime, gameSpeed: Float(physicsWorld.speed))
        nebulae.update(deltaTime: deltaTime)
        dynamicLighting.update(playerPosition: player.position)
        cameraEffects.update(deltaTime: deltaTime)
        particleManager.update(deltaTime: deltaTime)
        
        // Apply tilt navigation (runs alongside touch — both feed targetPosition)
        if motionController.isActive {
            motionController.update()
            player.applyTilt(
                tiltX: motionController.tiltX,
                tiltY: motionController.tiltY,
                deltaTime: deltaTime,
                sensitivity: motionController.sensitivity
            )
        }

        // Update game objects
        player.update()
        player.updateDash(deltaTime: deltaTime)
        meteorController.update(delta: deltaTime)
        starController.update(delta: deltaTime)
        powerUpController.update(delta: deltaTime)

        // Apply active power-up effects
        player.hasShield = powerUpController.isShieldActive
        if powerUpController.isSlowMoActive {
            physicsWorld.speed = 0.4
        } else if !bossWaveActive {
            physicsWorld.speed = 1.0
        }
        if powerUpController.isMagnetActive {
            applyMagnetEffect(deltaTime: deltaTime)
        }

        // Update boss wave timer
        if bossWaveActive {
            bossWaveTimer -= deltaTime
            if bossWaveTimer <= 0 { endBossWave() }
        }

        // Update game state
        updateGameState()
        updateStatusBar()
        
        // Update animations
        animationController.update(deltaTime: deltaTime)
    }
    
    private func calculateDeltaTime(_ currentTime: TimeInterval) -> TimeInterval {
        let deltaTime = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
        lastUpdateTime = currentTime
        return min(deltaTime, 1.0/30.0) // Cap at 30 FPS minimum
    }
    
    private func updateGameState() {
        gameState.score = player.score
        gameState.lives = player.lives

        // Check for game over
        if player.lives <= 0 && gameState.currentPhase == .running {
            setCurrentPhase(.gameOver)
            return
        }

        // Progression tier escalation
        let score = gameState.score
        let newTier: Int
        if score >= 3000      { newTier = 4 }
        else if score >= 1500 { newTier = 3 }
        else if score >= 500  { newTier = 2 }
        else                  { newTier = 1 }

        if newTier != currentTier {
            currentTier = newTier
            meteorController.setTier(newTier)
            powerUpController.currentTier = newTier
            parallaxBackground.speedMultiplier = GameTier.speedMultipliers[newTier] ?? 1.0
            showTierAdvanceEffect(tier: newTier)
        }

        // Boss wave every 1000 points
        let bossThreshold = (score / 1000) * 1000
        if bossThreshold > 0 && bossThreshold > lastBossScore && !bossWaveActive {
            lastBossScore = bossThreshold
            startBossWave()
        }
    }

    private func showTierAdvanceEffect(tier: Int) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "TIER \(tier)!"
        label.fontSize = 32
        label.fontColor = Colors.colorFromRGB(rgbvalue: Colors.AccentCyan)
        label.position = CGPoint(x: kViewSize.width / 2, y: kViewSize.height * 0.6)
        label.zPosition = GameLayer.Interface + 5
        label.alpha = 0
        addChild(label)

        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.2),
                SKAction.scale(to: 1.2, duration: 0.2)
            ]),
            SKAction.wait(forDuration: 0.8),
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.moveBy(x: 0, y: 30, duration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))
        performScreenFlash(color: Colors.colorFromRGB(rgbvalue: Colors.AccentCyan), intensity: 0.15)
    }

    private func startBossWave() {
        bossWaveActive = true
        bossWaveTimer = bossWaveDuration
        // Crank up speed
        meteorController.speedMultiplier *= 1.8
        physicsWorld.speed = 1.0

        // Red vignette hint
        performScreenFlash(color: Colors.colorFromRGB(rgbvalue: Colors.DangerRed), intensity: 0.25)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "BOSS WAVE!"
        label.fontSize = 36
        label.fontColor = Colors.colorFromRGB(rgbvalue: Colors.DangerRed)
        label.position = CGPoint(x: kViewSize.width / 2, y: kViewSize.height * 0.55)
        label.zPosition = GameLayer.Interface + 5
        label.name = "bossLabel"
        addChild(label)
        label.run(SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.12),
            SKAction.scale(to: 1.0,  duration: 0.12),
            SKAction.wait(forDuration: 1.0),
            SKAction.fadeOut(withDuration: 0.4),
            SKAction.removeFromParent()
        ]))
        cameraEffects.performImpactShake()
    }

    private func endBossWave() {
        bossWaveActive = false
        // Restore speed
        meteorController.speedMultiplier = GameTier.speedMultipliers[currentTier] ?? 1.0
        // Bonus score
        player.score += 100

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "SURVIVED! +100"
        label.fontSize = 28
        label.fontColor = Colors.colorFromRGB(rgbvalue: Colors.AccentYellow)
        label.position = CGPoint(x: kViewSize.width / 2, y: kViewSize.height * 0.55)
        label.zPosition = GameLayer.Interface + 5
        addChild(label)
        label.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.1),
            SKAction.wait(forDuration: 1.2),
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.4),
                SKAction.moveBy(x: 0, y: 40, duration: 0.4)
            ]),
            SKAction.removeFromParent()
        ]))
        performScreenFlash(color: Colors.colorFromRGB(rgbvalue: Colors.AccentYellow), intensity: 0.2)
    }

    private func applyMagnetEffect(deltaTime: TimeInterval) {
        let pullSpeed: CGFloat = 180 * CGFloat(deltaTime)
        for node in starController.children {
            guard let star = node as? Star else { continue }
            let diff = CGPoint(x: player.position.x - star.position.x,
                               y: player.position.y - star.position.y)
            let dist = hypot(diff.x, diff.y)
            guard dist > 1 else { continue }
            let norm = CGPoint(x: diff.x / dist, y: diff.y / dist)
            star.position.x += norm.x * min(pullSpeed, dist)
            star.position.y += norm.y * min(pullSpeed, dist)
        }
    }
    
    private func updateStatusBar() {
        statusBar.updateScore(score: gameState.score)
        statusBar.updateLives(lives: gameState.lives)
        statusBar.updateStarsCollected(collected: gameState.starsCollected)
        statusBar.updateTier(currentTier)
        statusBar.updatePowerUpStatus(
            shield: powerUpController.isShieldActive,
            magnet: powerUpController.isMagnetActive,
            slowMo: powerUpController.isSlowMoActive
        )
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        switch gameState.currentPhase {
        case .tutorial:
            handleTutorialTouch(at: location)
        case .running:
            handleGameplayTouch(at: location)
        case .paused:
            handlePausedTouch(at: location)
        case .gameOver:
            break
        }
    }
    
    private func handleTutorialTouch(at location: CGPoint) {
        // Touch-circle toggle — check before start button so small pill is reliably tappable
        if touchToggleRect.contains(location) {
            gameSettings.toggleTouchCircles()
            refreshTouchToggle()
            audioManager.playSoundEffect(.buttonTap)
            return
        }

        if startButton.tapRect.contains(location) {
            audioManager.playSoundEffect(.buttonTap)
            setCurrentPhase(.running)
        }
    }
    
    private func handleGameplayTouch(at location: CGPoint) {
        // Check if pause button was tapped
        if statusBar.pauseButtonTapRect.contains(location) {
            statusBar.pauseButton.tapped()
            setCurrentPhase(.paused)
            return
        }

        // Double-tap detection → dash toward tap location
        let now = CACurrentMediaTime()
        let timeDelta = now - lastTapTime
        let dist = hypot(location.x - lastTapLocation.x, location.y - lastTapLocation.y)

        if timeDelta < 0.32 && dist < 90 && player.dashChargeAvailable {
            let direction = CGPoint(x: location.x - player.position.x, y: location.y - player.position.y)
            player.dash(toward: direction)
            cameraEffects.performDashZoom()
            lastTapTime = 0 // reset to prevent triple-tap chaining
        } else {
            player.updateTargetLocation(newLocation: location)
            lastTapTime = now
            lastTapLocation = location
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, gameState.currentPhase == .running else { return }
        let location = touch.location(in: self)
        // Only redirect ship if not mid-dash
        if !player.isDashing {
            player.updateTargetLocation(newLocation: location)
        }
    }
    
    private func handlePausedTouch(at location: CGPoint) {
        if pauseMenuRect.contains(location) {
            // MENU button — go back to main menu
            audioManager.playSoundEffect(.buttonTap)
            statusBar.pauseButton.resetToPlayIcon()
            returnToMenu()
        } else if pauseResumeRect.contains(location) || statusBar.pauseButtonTapRect.contains(location) {
            // RESUME button or pause-button tap — resume game
            audioManager.playSoundEffect(.buttonTap)
            statusBar.pauseButton.resetToPlayIcon()
            setCurrentPhase(.running)
        }
        // Taps on the dark backdrop do nothing — user must choose a button
    }
    
    // MARK: - Physics Contact
    func didBegin(_ contact: SKPhysicsContact) {
        let contactA = contact.bodyA.categoryBitMask
        let contactB = contact.bodyB.categoryBitMask
        
        // Player collision with meteor
        if (contactA == Contact.Player && contactB == Contact.Meteor) ||
           (contactA == Contact.Meteor && contactB == Contact.Player) {
            handlePlayerMeteorCollision(contact)
        }
        
        // Player collection of star
        if (contactA == Contact.Player && contactB == Contact.Star) ||
           (contactA == Contact.Star && contactB == Contact.Player) {
            handlePlayerStarCollection(contact)
        }

        // Player collection of power-up
        if (contactA == Contact.Player && contactB == Contact.PowerUp) ||
           (contactA == Contact.PowerUp && contactB == Contact.Player) {
            handlePlayerPowerUpCollection(contact)
        }
    }
    
    private func handlePlayerPowerUpCollection(_ contact: SKPhysicsContact) {
        guard gameState.isGameActive else { return }
        let orb = contact.bodyA.categoryBitMask == Contact.PowerUp ?
                  contact.bodyA.node : contact.bodyB.node
        guard let powerUp = orb as? PowerUp else { return }

        powerUpController.activateEffect(powerUp.powerUpType)
        powerUp.removeFromParent()
        player.score += 5

        // Visual feedback
        dynamicLighting.flashAt(powerUp.position, color: powerUp.powerUpType.color, intensity: 1.8)
        performScreenFlash(color: powerUp.powerUpType.color, intensity: 0.12)
        accessibilityManager.playHapticFeedback(.success)
        createFloatingScoreIndicator(at: powerUp.position, value: 5)
    }

    private func handlePlayerMeteorCollision(_ contact: SKPhysicsContact) {
        guard gameState.isGameActive else { return }

        let meteor = contact.bodyA.categoryBitMask == Contact.Meteor ?
                     contact.bodyA.node : contact.bodyB.node

        if let meteorNode = meteor as? Meteor {
            // Dash kill: dashing + shield active = destroy meteor, no damage, +10 score
            if player.isDashing && player.hasShield {
                performExplosionEffect(at: meteorNode.position)
                dynamicLighting.flashAt(meteorNode.position, color: UIColor(red: 1, green: 0.8, blue: 0, alpha: 1), intensity: 2.5)
                meteorNode.hitMeteor()
                player.score += 10
                createFloatingScoreIndicator(at: meteorNode.position, value: 10)
                accessibilityManager.playHapticFeedback(.heavy)
                return
            }
            // Shield active (but not dashing): absorb the hit, remove meteor, no lives lost
            if player.hasShield {
                meteorNode.hitMeteor()
                performScreenFlash(color: Colors.colorFromRGB(rgbvalue: Colors.AccentCyan), intensity: 0.18)
                accessibilityManager.playHapticFeedback(.medium)
                return
            }
            // Enhanced collision effects
            performExplosionEffect(at: meteorNode.position)
            // Red flash on hit, white on last life
            let isLastLife = player.lives <= 1 && !player.immune
            performScreenFlash(color: isLastLife ? .white : .red, intensity: isLastLife ? 0.5 : 0.28)
            if isLastLife {
                cameraEffects.performDeathShake()
            } else {
                cameraEffects.performImpactShake()
            }

            // Ship break effect — only fires on a real (non-immune) hit.
            if !player.immune && player.lives > 0 {
                if player.lives == 1 {
                    // Last life: permanent disassembly explosion
                    ShipBreakEffect.playDestroyEffect(for: player, in: self)
                } else {
                    // Surviving hit: quick scatter and snap back
                    ShipBreakEffect.playHitEffect(for: player, in: self)
                }
            }

            // Update game state
            player.hitMeteor()
            meteorNode.hitMeteor()

            // Haptic feedback — heavy on last life, medium otherwise
            let hapticType: HapticFeedbackType = (player.lives <= 0) ? .heavy : .medium
            accessibilityManager.playHapticFeedback(hapticType)

            // Last-life death: full-volume non-spatial boom; otherwise spatial at meteor
            if isLastLife {
                audioManager.playSoundEffect(.explosion)
            } else {
                audioManager.playSoundEffect(.explosion, at: meteorNode.position)
            }

            // Dynamic lighting effect
            dynamicLighting.flashAt(meteorNode.position, color: .red, intensity: 2.0)

            logger.info("Player hit by meteor with enhanced effects")
        }
    }
    
    private func handlePlayerStarCollection(_ contact: SKPhysicsContact) {
        guard gameState.isGameActive else { return }
        
        let star = contact.bodyA.categoryBitMask == Contact.Star ? 
                   contact.bodyA.node : contact.bodyB.node
        
        if let starNode = star as? Star {
            // Enhanced collection effects
            performStarCollectionEffect(at: starNode.position)
            
            starNode.pickedUpStar()
            gameState.starsCollected += 1
            player.pickedUpStar()

            // Light haptic on star collect
            accessibilityManager.playHapticFeedback(.light)

            // Dynamic lighting effect
            dynamicLighting.flashAt(starNode.position, color: .yellow, intensity: 1.5)
            
            // Particle burst
            _ = particleManager.createStarBurst(at: starNode.position)
            
            // Status bar animation
            statusBar.animateStarCollection()
            
            logger.info("Star collected with enhanced effects")
        }
    }
    
    // MARK: - Enhanced Visual Effects
    private func performExplosionEffect(at position: CGPoint) {
        // Particle burst
        let explosion = particleManager.createExplosion(at: position, intensity: .high)
        effectsNode.addChild(explosion)

        // Fire + smoke on every hit
        particleManager.addFireBurst(at: position, to: self)
        run(.wait(forDuration: 0.08)) { [weak self] in
            guard let self else { return }
            self.particleManager.addSmokePlume(at: position, to: self)
        }

        // Expanding shockwave ring
        let shockwave = createShockwave(at: position)
        effectsNode.addChild(shockwave)
    }
    
    private func performStarCollectionEffect(at position: CGPoint) {
        // Sparkling effect
        let sparkles = particleManager.createSparkles(at: position)
        effectsNode.addChild(sparkles)
        
        // Rising score indicator
        createFloatingScoreIndicator(at: position, value: 250)
    }
    
    private func performScreenFlash(color: SKColor = .white, intensity: CGFloat = 0.3) {
        screenFlash.color = color
        screenFlash.alpha = intensity
        let flash = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.12),
            SKAction.wait(forDuration: 0.04),
            SKAction.fadeAlpha(to: intensity * 0.4, duration: 0.08),
            SKAction.fadeOut(withDuration: 0.22)
        ])
        screenFlash.run(flash, withKey: "screenFlash")
    }
    
    private func createShockwave(at position: CGPoint) -> SKNode {
        let shockwave = SKShapeNode(circleOfRadius: 1)
        shockwave.strokeColor = .cyan
        shockwave.fillColor = .clear
        shockwave.lineWidth = 3
        shockwave.alpha = 0.8
        shockwave.position = position
        
        let expand = SKAction.scale(to: 100, duration: 0.5)
        let fade = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        
        shockwave.run(SKAction.sequence([
            SKAction.group([expand, fade]),
            remove
        ]))
        
        return shockwave
    }
    
    private func createFloatingScoreIndicator(at position: CGPoint, value: Int) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "+\(value)"
        label.fontSize = 24
        label.fontColor = .yellow
        label.position = position
        label.zPosition = GameLayer.Interface + 5
        
        // Add glow effect
        let glow = label.copy() as! SKLabelNode
        glow.fontColor = .white
        glow.alpha = 0.5
        glow.setScale(1.2)
        glow.zPosition = -1
        label.addChild(glow)
        
        addChild(label)
        
        let moveUp = SKAction.moveBy(x: 0, y: 80, duration: 1.0)
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let scale = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.9)
        ])
        
        label.run(SKAction.sequence([
            SKAction.group([moveUp, fadeOut, scale]),
            SKAction.removeFromParent()
        ]))
    }
    
    // MARK: - Notification Handlers
    @objc private func pauseGame() {
        guard gameState.currentPhase == .running else { return }
        setCurrentPhase(.paused)
    }
    
    @objc private func resumeGame() {
        guard gameState.currentPhase == .paused else { return }
        setCurrentPhase(.running)
    }
    
    // MARK: - App Lifecycle
    func handleAppBackground() {
        if gameState.currentPhase == .running {
            setCurrentPhase(.paused)
        }
    }
    
    func handleAppForeground() {
        // Game will remain paused until user resumes
    }
}
