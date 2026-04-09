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
//  - ParallaxBackground + NebulaSystem  — layered scrolling backdrop
//  - DynamicLighting                    — real-time coloured light sources
//  - EnhancedParticleManager            — multi-intensity explosions and star bursts
//  - CameraEffects                      — screen shake, slow-motion, intro transition
//  - AnimationController                — ambient UI micro-animations
//  - GameAudio (spatial)                — distance-attenuated sound effects
//  - StatusBar (glass HUD)              — score, lives, stars, pause button
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
    // private let accessibilityManager = AccessibilityManager.shared // TODO: Add AccessibilityManager to project
    
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
    private var statusBar: StatusBar!
    
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
        Task {
            await setupScene()
        }
        setupNotifications()
        logger.info("GameScene initialized and moved to view")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        logger.info("GameScene deinitialized")
    }
    
    // MARK: - Setup
    private func setupScene() async {
        backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0) // Deep space blue
        setupPhysics()
        await setupNodes()
        await setupVisualEffects()
        setupInterface()
        setupAccessibility()
        
        // Initialize game state
        gameState.lives = player.lives
        gameState.score = player.score
        gameState.starsCollected = 0
        
        // Start with dramatic camera transition
        await cameraEffects.performIntroTransition()
        
        // Start tutorial phase
        setCurrentPhase(.tutorial)
    }
    
    private func setupPhysics() {
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        physicsWorld.speed = 1.0
    }
    
    private func setupNodes() async {
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
        
        // Enhanced background system
        await setupEnhancedBackground()
        
        // Setup player with enhanced effects
        await setupEnhancedPlayer()
        
        // Setup enhanced controllers
        gameNode.addChild(meteorController)
        gameNode.addChild(starController)
        
        // Initialize audio with enhanced effects
        audioManager.playBackgroundMusic()
        await audioManager.setupSpatialAudio()
    }
    
    private func setupEnhancedBackground() async {
        // Layer 1: Deep space background
        background.zPosition = GameLayer.Background
        gameNode.addChild(background)
        
        // Layer 2: Parallax star fields
        parallaxBackground.setupLayers(for: size)
        parallaxBackground.zPosition = GameLayer.Background + 0.1
        gameNode.addChild(parallaxBackground)
        
        // Layer 3: Distant nebulae
        nebulae.setupNebulae(for: size)
        nebulae.zPosition = GameLayer.Background + 0.2
        gameNode.addChild(nebulae)
    }
    
    private func setupEnhancedPlayer() async {
        player.position = CGPoint(x: kViewSize.width / 2, y: kViewSize.height * 0.15)
        player.zPosition = GameLayer.Player
        
        // Add enhanced engine trails
        await player.setupEnhancedEngineEffects()
        
        // Add dynamic lighting
        let playerLight = dynamicLighting.addLight(at: player.position, 
                                                 color: .cyan, 
                                                 intensity: 0.8,
                                                 radius: 150)
        playerLight.name = "playerLight"
        
        gameNode.addChild(player)
    }
    
    private func setupVisualEffects() async {
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
        
        // Setup status bar with enhanced visuals
        statusBar = StatusBar(lives: gameState.lives, score: gameState.score, stars: gameState.starsCollected)
        statusBar.position = CGPoint.zero
        statusBar.zPosition = GameLayer.Interface
        statusBar.applyGlassEffect()
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
        
        // Animate the hint
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.8),
            SKAction.scale(to: 0.9, duration: 0.8)
        ])
        hint.run(SKAction.repeatForever(pulse))
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
        
        // Remove tutorial hints
        interfaceNode.children.filter { $0.name == "tutorialHint" }.forEach { node in
            node.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.removeFromParent()
            ]))
        }
        
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
        motionController.startMotionUpdates()
        
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
        motionController.stopMotionUpdates()
        audioManager.pauseBackgroundMusic()
    }
    
    private func resumeGameplay() {
        // Resume physics
        physicsWorld.speed = 1.0

        // Resume gameplay systems
        player.enableMovement()
        meteorController.startSendingMeteors()
        starController.startSendingStars()
        motionController.startMotionUpdates()
        audioManager.playBackgroundMusic()
        
        // Update UI
        updateStatusBar()
    }
    
    private func endGame() {
        physicsWorld.speed = 0.0
        meteorController.stopSendingMetors()
        starController.stopSendingStars()
        
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
        // Dramatic screen flash
        performScreenFlash()
        
        // Camera shake
        cameraEffects.performImpactShake()
        
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
        meteorController.update(delta: deltaTime)
        starController.update(delta: deltaTime)
        
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
        // starsCollected is tracked directly in gameState when stars are collected
        
        // Check for game over
        if player.lives <= 0 && gameState.currentPhase == .running {
            setCurrentPhase(.gameOver)
        }
    }
    
    private func updateStatusBar() {
        statusBar.updateScore(score: gameState.score)
        statusBar.updateLives(lives: gameState.lives)
        statusBar.updateStarsCollected(collected: gameState.starsCollected)
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
        // Use the button's own responsive tap rect (accounts for dynamic sizing)
        if startButton.tapRect.contains(location) {
            audioManager.playSoundEffect(.buttonTap)
            setCurrentPhase(.running)
        }
    }
    
    private func handleGameplayTouch(at location: CGPoint) {
        // Check if pause button was tapped
        // Get pause button position in scene coordinates
        let pauseButtonScenePosition = convert(statusBar.pauseButton.position, from: statusBar)
        let pauseButtonFrame = CGRect(
            x: pauseButtonScenePosition.x - statusBar.pauseButton.size.width / 2,
            y: pauseButtonScenePosition.y - statusBar.pauseButton.size.height / 2,
            width: statusBar.pauseButton.size.width,
            height: statusBar.pauseButton.size.height
        )
        
        if pauseButtonFrame.contains(location) {
            statusBar.pauseButton.tapped()
            setCurrentPhase(.paused)
            return
        }
        
        // Otherwise, move player
        player.updateTargetLocation(newLocation: location)
    }
    
    private func handlePausedTouch(at location: CGPoint) {
        // When paused, any tap resumes the game
        // Could also check for specific pause button or resume area if desired
        audioManager.playSoundEffect(.buttonTap)
        setCurrentPhase(.running)
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
    }
    
    private func handlePlayerMeteorCollision(_ contact: SKPhysicsContact) {
        guard gameState.isGameActive else { return }
        
        let meteor = contact.bodyA.categoryBitMask == Contact.Meteor ? 
                     contact.bodyA.node : contact.bodyB.node
        
        if let meteorNode = meteor as? Meteor {
            // Enhanced collision effects
            performExplosionEffect(at: meteorNode.position)
            performScreenFlash()
            cameraEffects.performImpactShake()
            
            // Update game state
            player.hitMeteor()
            meteorNode.hitMeteor()
            
            // Enhanced audio with spatial effects
            audioManager.playSoundEffect(.explosion, at: meteorNode.position)
            
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
        // Main explosion
        let explosion = particleManager.createExplosion(at: position, intensity: .high)
        effectsNode.addChild(explosion)
        
        // Secondary debris
        let debris = particleManager.createDebris(at: position, velocity: CGVector(dx: 0, dy: -200))
        effectsNode.addChild(debris)
        
        // Shockwave
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
    
    private func performScreenFlash() {
        screenFlash.alpha = 0.3
        let flash = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.1),
            SKAction.wait(forDuration: 0.05),
            SKAction.fadeAlpha(to: 0.1, duration: 0.1),
            SKAction.fadeOut(withDuration: 0.2)
        ])
        screenFlash.run(flash)
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
