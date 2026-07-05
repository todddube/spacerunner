//
//  EnhancedMenuScene.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Modern replacement for MenuScene. Delivers a premium first-impression using
//  the full enhanced-graphics stack: multi-layer parallax, animated nebulae,
//  dynamic lighting, and a responsive glass play button with spring animations.
//
//  VISUAL FEATURES
//  - ParallaxBackground + NebulaSystem  — living space backdrop
//  - DynamicLighting                    — atmospheric ambient and hover light
//  - Liquid glass play-button container — rounded rect with shimmer animation
//  - Staggered entrance animations      — title, button, and labels fly in
//      sequentially using spring-based timing
//  - Touch sparkle effects              — 8 cyan particles burst from each tap
//  - Camera shake intro                 — dramatic entrance on scene load
//
//  RESPONSIBILITIES
//  - setupScene()       — async init of all visual systems and layout
//  - setupTitle()       — position and animate the "SPACE RUNNER" title label
//  - setupPlayButton()  — create the glass container + ModernStartButton
//  - setupLabels()      — author and version labels above safe-area bottom
//  - touchesBegan(…)    — detect play-button tap; spawn sparkles on every touch
//  - loadGameScene()    — transition to GameScene with fade
//
//  REQUIRES @MainActor — all SpriteKit mutations on the main thread
//

import Foundation
import SpriteKit

@MainActor
public class EnhancedMenuScene: SKScene {

    // MARK: - Enhanced Visual Components
    private var parallaxBackground: ParallaxBackground!
    private var nebulae: NebulaSystem!
    private var dynamicLighting: DynamicLighting!
    private var animationController: AnimationController!
    private var cameraEffects: CameraEffects!

    // MARK: - UI Components
    private var modernPlayButton: ModernStartButton!
    private var gameTitle: GameTitle!
    private var gameTitleShip: GameTitleShip?
    private var shipAssembly: ShipAssemblyAnimation?

    // MARK: - Info Labels
    private var authorLabel: SKLabelNode!
    private var versionLabel: SKLabelNode!
    private var infoContainer: SKNode!

    // MARK: - Glass Effect Container
    private var glassContainer: SKNode!

    // MARK: - Constants
    private let fonts = GameFonts.shared

    // MARK: - Delta Time Tracking
    private var lastUpdateTime: TimeInterval = 0

    // MARK: - Init
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public override init(size: CGSize) {
        super.init(size: size)
    }

    public override func didMove(to view: SKView) {
        setupEnhancedMenuScene()
        GameAudio.shared.playBackgroundMusic()
    }

    // MARK: - Setup
    private func setupEnhancedMenuScene() {
        backgroundColor = Colors.colorFromRGB(rgbvalue: Colors.Background)

        setupEnhancedVisuals()
        setupUI()
        setupGlassEffects()
        setupInfoLabels()
        animateSceneIntro()
    }

    private func setupEnhancedVisuals() {
        // Enhanced background with parallax scrolling
        parallaxBackground = ParallaxBackground()
        addChild(parallaxBackground)
        parallaxBackground.startScrolling()

        // Animated nebulae system
        nebulae = NebulaSystem()
        addChild(nebulae)
        nebulae.startAnimation()

        // Dynamic lighting system
        dynamicLighting = DynamicLighting()
        addChild(dynamicLighting)
        // Ambient lighting is set up automatically in init

        // Animation controller
        animationController = AnimationController()

        // Camera effects for intro
        cameraEffects = CameraEffects()
        cameraEffects.setupForScene(self)
    }

    private func setupUI() {
        // Modern play button with liquid glass effects
        modernPlayButton = ModernStartButton()
        modernPlayButton.position = CGPoint(x: kViewSize.width / 2, y: kViewSize.height * 0.35)
        modernPlayButton.setScale(0.0) // Start invisible for animation
        addChild(modernPlayButton)

        // Game title
        gameTitle = GameTitle()
        addChild(gameTitle)

        // Ship assembly animation — added to scene inside animateSceneIntro()
        shipAssembly = ShipAssemblyAnimation()
    }

    private func setupGlassEffects() {
        // Create glass container for UI elements
        glassContainer = SKNode()
        addChild(glassContainer)

        // Add glass background effect
        let glassBackground = createGlassBackground()
        glassBackground.position = CGPoint(x: kViewSize.width / 2, y: kViewSize.height * 0.35)
        glassContainer.addChild(glassBackground)
        glassContainer.alpha = 0.0
    }

    private func createGlassBackground() -> SKShapeNode {
        let rect = CGRect(x: -120, y: -80, width: 240, height: 160)
        let glassShape = SKShapeNode(rect: rect, cornerRadius: 25)

        // Liquid glass appearance
        glassShape.fillColor = SKColor.white.withAlphaComponent(0.1)
        glassShape.strokeColor = SKColor.cyan.withAlphaComponent(0.3)
        glassShape.lineWidth = 2.0

        // Add inner glow
        let innerGlow = SKShapeNode(rect: rect.insetBy(dx: 5, dy: 5), cornerRadius: 20)
        innerGlow.fillColor = SKColor.clear
        innerGlow.strokeColor = SKColor.white.withAlphaComponent(0.2)
        innerGlow.lineWidth = 1.0
        glassShape.addChild(innerGlow)

        return glassShape
    }

    private func setupInfoLabels() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        // Container — fades in as one unit; sparkles are children of this node
        infoContainer = SKNode()
        infoContainer.position = CGPoint(x: kViewSize.width / 2, y: 52)
        infoContainer.alpha = 0
        addChild(infoContainer)

        // Copyright label
        authorLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        authorLabel.text = "© 2026 Todd Dube"
        authorLabel.fontSize = 13
        authorLabel.fontColor = .white
        authorLabel.horizontalAlignmentMode = .center
        authorLabel.verticalAlignmentMode   = .center
        authorLabel.position = CGPoint(x: 0, y: 14)
        infoContainer.addChild(authorLabel)

        // Version label
        versionLabel = SKLabelNode(fontNamed: "AvenirNext-Light")
        versionLabel.text = "v\(appVersion)  ·  build \(buildNumber)"
        versionLabel.fontSize = 11
        versionLabel.fontColor = SKColor.cyan.withAlphaComponent(0.85)
        versionLabel.horizontalAlignmentMode = .center
        versionLabel.verticalAlignmentMode   = .center
        versionLabel.position = CGPoint(x: 0, y: -2)
        infoContainer.addChild(versionLabel)

        // Thin cyan accent line between labels
        let accent = SKSpriteNode(
            color: SKColor.cyan.withAlphaComponent(0.35),
            size: CGSize(width: 180, height: 0.5))
        accent.blendMode  = .add
        accent.position   = CGPoint(x: 0, y: 7)
        infoContainer.addChild(accent)

        // Pulsing glow halo behind the text
        let halo = SKShapeNode(rectOf: CGSize(width: 210, height: 36), cornerRadius: 10)
        halo.fillColor   = SKColor.cyan.withAlphaComponent(0.04)
        halo.strokeColor = SKColor.cyan.withAlphaComponent(0.18)
        halo.lineWidth   = 1.0
        halo.blendMode   = .add
        halo.position    = CGPoint(x: 0, y: 6)
        infoContainer.addChild(halo)
        halo.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.4, duration: 2.2),
            SKAction.fadeAlpha(to: 1.0, duration: 2.2)
        ])))

        // Best score — gold treatment, shown only when > 0
        let best = GameSettings.shared.bestScore
        if best > 0 {
            let fmt = NumberFormatter(); fmt.numberStyle = .decimal
            let bestLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            bestLabel.text = "BEST  \(fmt.string(from: NSNumber(value: best)) ?? "\(best)")"
            bestLabel.fontSize = 15
            bestLabel.fontColor = SKColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 0.85)
            bestLabel.horizontalAlignmentMode = .center
            bestLabel.position = CGPoint(x: kViewSize.width / 2, y: kViewSize.height * 0.27)
            bestLabel.alpha = 0
            addChild(bestLabel)
            bestLabel.run(SKAction.sequence([
                SKAction.wait(forDuration: 2.4),
                SKAction.fadeAlpha(to: 0.85, duration: 0.6)
            ]))
        }

        // Control hint
        let controlHint = SKLabelNode(fontNamed: "AvenirNext-Medium")
        controlHint.text = "Tap or tilt to navigate"
        controlHint.fontSize = 16
        controlHint.fontColor = SKColor.cyan.withAlphaComponent(0.75)
        controlHint.horizontalAlignmentMode = .center
        controlHint.position = CGPoint(x: kViewSize.width / 2, y: kViewSize.height * 0.18)
        controlHint.alpha = 0.0
        controlHint.name = "controlHint"
        addChild(controlHint)
        controlHint.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.2),
            SKAction.fadeAlpha(to: 0.75, duration: 0.8),
            SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.4, duration: 1.8),
                SKAction.fadeAlpha(to: 0.75, duration: 1.8)
            ]))
        ]))

        setupInfoLabelAnimations()
    }

    private func setupInfoLabelAnimations() {
        // Copyright: slow color shimmer white → cyan → white → soft magenta
        let shimmer = SKAction.repeatForever(SKAction.sequence([
            SKAction.colorize(with: .white,                                             colorBlendFactor: 1, duration: 2.5),
            SKAction.colorize(with: SKColor(red: 0.4, green: 1.0, blue: 1.0, alpha: 1), colorBlendFactor: 1, duration: 2.5),
            SKAction.colorize(with: .white,                                             colorBlendFactor: 1, duration: 2.5),
            SKAction.colorize(with: SKColor(red: 1.0, green: 0.5, blue: 1.0, alpha: 1), colorBlendFactor: 1, duration: 2.5)
        ]))
        authorLabel.run(shimmer)

        // Version: gentle breathe
        versionLabel.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.45, duration: 3.0),
            SKAction.fadeAlpha(to: 0.85, duration: 3.0)
        ])))

        // Spawn sparkles continuously once the container is visible
        let spawnSparkles = SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: 0.55, withRange: 0.7),
            SKAction.run { [weak self] in self?.spawnInfoSparkle() }
        ]))
        infoContainer.run(spawnSparkles, withKey: "sparkles")
    }

    private func spawnInfoSparkle() {
        let radius = CGFloat.random(in: 0.7...2.2)
        let sparkle = SKShapeNode(circleOfRadius: radius)
        let palette: [SKColor] = [
            .cyan,
            .white,
            SKColor(red: 0.8, green: 0.4, blue: 1.0, alpha: 1),
            SKColor(red: 0.4, green: 1.0, blue: 0.8, alpha: 1)
        ]
        sparkle.fillColor   = palette.randomElement()!
        sparkle.strokeColor = .clear
        sparkle.blendMode   = .add
        sparkle.alpha       = 0

        // Random scatter across the label area
        sparkle.position = CGPoint(
            x: CGFloat.random(in: -105...105),
            y: CGFloat.random(in: -18...28))
        infoContainer.addChild(sparkle)

        let peakAlpha = CGFloat.random(in: 0.55...1.0)
        sparkle.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeAlpha(to: peakAlpha, duration: 0.12),
                SKAction.moveBy(x: CGFloat.random(in: -6...6),
                                y: CGFloat.random(in: 6...18), duration: 1.1)
            ]),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
    }

    private func animateSceneIntro() {
        // Camera intro effect - using available shake for dramatic intro
        cameraEffects.performGameStartShake()

        // Ship assembly — parts fly in from the four corners ~0.7 s after the
        // camera shake fires, landing at 57 % screen height (between title and button).
        let assemblyPos = CGPoint(x: kViewSize.width / 2, y: kViewSize.height * 0.57)
        run(SKAction.wait(forDuration: 0.7)) {
            self.shipAssembly?.runAssembly(in: self, at: assemblyPos)
        }

        // Glass container animation
        let glassDelay = SKAction.wait(forDuration: 1.5)
        let glassFadeIn = SKAction.fadeIn(withDuration: 0.8)
        let glassSequence = SKAction.sequence([glassDelay, glassFadeIn])
        glassContainer.run(glassSequence)

        // Modern play button animation
        let buttonDelay = SKAction.wait(forDuration: 2.0)
        let buttonScale = animationController.createPulseAnimation(scale: 1.0, duration: 0.6)
        let buttonSequence = SKAction.sequence([buttonDelay, buttonScale])
        modernPlayButton.run(buttonSequence) {
            // Add subtle floating animation
            let floating = self.animationController.createFloatingAnimation(distance: 5, duration: 3.0)
            self.modernPlayButton.run(SKAction.repeatForever(floating))
        }

        // Info container — fade + float up together
        infoContainer.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.5),
            SKAction.group([
                SKAction.fadeIn(withDuration: 1.0),
                SKAction.moveBy(x: 0, y: 10, duration: 1.0)
            ])
        ]))

        // Dynamic lighting effects
        let lightingDelay = SKAction.wait(forDuration: 1.0)
        let lightingSequence = SKAction.sequence([lightingDelay, SKAction.run {
            self.dynamicLighting.transitionToGameplay()
        }])
        run(lightingSequence)
    }

    // MARK: - Update
    public override func update(_ currentTime: TimeInterval) {
        let deltaTime: TimeInterval = lastUpdateTime > 0
            ? min(currentTime - lastUpdateTime, 1.0 / 30.0) // cap at 30 FPS floor
            : 1.0 / 60.0
        lastUpdateTime = currentTime

        parallaxBackground.update(deltaTime: deltaTime, gameSpeed: 0.3)
        nebulae.update(deltaTime: deltaTime)
        dynamicLighting.update(playerPosition: CGPoint(x: kViewSize.width / 2, y: kViewSize.height / 2))
        cameraEffects.update(deltaTime: deltaTime)
    }

    // MARK: - Touch Events
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)

        if modernPlayButton.contains(touchLocation) {
            // Animate button tap
            let scaleDown = SKAction.scale(to: 0.9, duration: 0.1)
            let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
            let tapAnimation = SKAction.sequence([scaleDown, scaleUp])
            modernPlayButton.run(tapAnimation)
            GameAudio.shared.playSoundEffect(.buttonTap)

            // Trigger sparkles at touch location
            createTouchSparkles(at: touchLocation)

            // Transition to game with enhanced effects
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.transitionToGame()
            }
        }
    }

    private func createTouchSparkles(at position: CGPoint) {
        for _ in 0..<8 {
            let sparkle = SKSpriteNode(color: .cyan, size: CGSize(width: 4, height: 4))
            sparkle.position = position
            addChild(sparkle)

            let randomAngle = Float.random(in: 0...(2 * Float.pi))
            let randomDistance = CGFloat.random(in: 30...60)
            let targetX = position.x + cos(CGFloat(randomAngle)) * randomDistance
            let targetY = position.y + sin(CGFloat(randomAngle)) * randomDistance

            let moveAction = SKAction.move(to: CGPoint(x: targetX, y: targetY), duration: 0.6)
            let fadeAction = SKAction.fadeOut(withDuration: 0.6)
            let scaleAction = SKAction.scale(to: 0.1, duration: 0.6)
            let removeAction = SKAction.removeFromParent()

            let sparkleAnimation = SKAction.group([moveAction, fadeAction, scaleAction])
            let sparkleSequence = SKAction.sequence([sparkleAnimation, removeAction])

            sparkle.run(sparkleSequence)
        }
    }

    private func transitionToGame() {
        cameraEffects.performImpactShake()

        // Spawn a ship that launches upward before the transition
        let shipTex = GameTextures.sharedInstance.textureWithName(name: SpriteName.Player)
        let launchShip = SKSpriteNode(texture: shipTex)
        launchShip.setScale(0.85)
        launchShip.position = CGPoint(x: kViewSize.width / 2, y: kViewSize.height * 0.57)
        launchShip.zPosition = 100
        addChild(launchShip)

        // Neon engine glow under the ship
        let engineGlow = SKShapeNode(ellipseOf: CGSize(width: 18, height: 8))
        engineGlow.fillColor = Colors.colorFromRGB(rgbvalue: Colors.AccentCyan)
        engineGlow.strokeColor = .clear
        engineGlow.blendMode = .add
        engineGlow.alpha = 0.8
        engineGlow.position = CGPoint(x: 0, y: -launchShip.size.height * 0.4)
        engineGlow.zPosition = -1
        launchShip.addChild(engineGlow)

        // Launch: slow wind-up then fast exit
        let windUp  = SKAction.moveBy(x: 0, y: -8,  duration: 0.12)
        let blast   = SKAction.moveBy(x: 0, y: kViewSize.height * 1.6, duration: 0.45)
        blast.timingMode = .easeIn
        let glowPop = SKAction.sequence([
            SKAction.scale(to: 1.4, duration: 0.08),
            SKAction.scale(to: 1.0, duration: 0.35)
        ])
        launchShip.run(SKAction.sequence([windUp, blast]))
        engineGlow.run(glowPop)

        // Fade everything else and transition
        run(SKAction.wait(forDuration: 0.42)) { [weak self] in
            guard let self else { return }
            let gameScene = GameScene(size: kViewSize)
            let transition = SKTransition.fade(with: .black, duration: 0.5)
            transition.pausesIncomingScene = false
            self.view?.presentScene(gameScene, transition: transition)
        }
    }
}
