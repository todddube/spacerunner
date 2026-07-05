//
//  EnhancedMenuScene.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Modern replacement for MenuScene. Delivers a cinematic first-impression using
//  the full enhanced-graphics stack: multi-layer parallax, gradient nebulae,
//  dynamic lighting, a detailed gas-giant planet with rings, periodic shooting
//  stars, and a glass play button with spring animations.
//
//  VISUAL FEATURES
//  - Gas-giant planet (upper right) with rendered gradient texture, atmosphere
//      rim glow, surface bands, and a ring system drawn in correct z-layers
//  - Shooting stars — random dramatic diagonal streaks with glow trails
//  - ParallaxBackground at 0.5× speed — faster scroll feels more alive
//  - NebulaSystem with radial-gradient textures for soft gas-cloud look
//  - DynamicLighting — atmospheric ambient and hover light
//  - Liquid glass play-button container with shimmer and spring pop
//  - Staggered entrance animations — title, planet, button fly in sequentially
//  - Touch sparkle effects — 8 cyan particles burst from each tap
//  - Camera shake intro — dramatic entrance on scene load
//
//  RESPONSIBILITIES
//  - setupEnhancedVisuals()  — background, nebulae, lighting, planet, shooting stars
//  - setupUI()               — play button, game title, ship assembly
//  - setupInfoLabels()       — copyright + version strip with sparkle animations
//  - touchesBegan(…)         — detect play-button tap; spawn sparkles on every touch
//  - transitionToGame()      — launch animation then push GameScene
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

    // MARK: - Menu Volume Slider
    private weak var menuVolumeContainer: UIView?

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
        setupMenuVolumeSlider(in: view)
    }

    public override func willMove(from view: SKView) {
        menuVolumeContainer?.removeFromSuperview()
        menuVolumeContainer = nil
    }

    // MARK: - Setup

    private func setupEnhancedMenuScene() {
        backgroundColor = Colors.colorFromRGB(rgbvalue: Colors.Background)

        setupEnhancedVisuals()
        setupUI()
        setupGlassEffects()
        setupInfoLabels()
        setupControlsHints()
        animateSceneIntro()
    }

    private func setupEnhancedVisuals() {
        // Multi-layer parallax star-field
        parallaxBackground = ParallaxBackground()
        addChild(parallaxBackground)
        parallaxBackground.startScrolling()

        // Radial-gradient nebulae — drift as a slow parallax layer
        nebulae = NebulaSystem()
        addChild(nebulae)
        nebulae.startAnimation()

        // Gas-giant planet with rings (added before nebulae so it sits behind)
        addPlanet()

        // Dynamic scene lighting
        dynamicLighting = DynamicLighting()
        addChild(dynamicLighting)

        // Animation and camera helpers
        animationController = AnimationController()
        cameraEffects = CameraEffects()
        cameraEffects.setupForScene(self)

        // Periodic shooting stars — dramatic diagonal streaks
        startShootingStars()

        // Slow decorative asteroids drifting across the background — like the game
        startBackgroundDebris()
    }

    // MARK: - Planet

    private func addPlanet() {
        let radius: CGFloat = kDeviceTablet ? 90 : 66

        let container = SKNode()
        // Upper-right region — partially off-screen for a dramatic framing
        container.position = CGPoint(x: kViewSize.width * 0.76, y: kViewSize.height * 0.83)
        container.zPosition = 1   // in front of background, behind nebulae (z 2+)
        container.alpha = 0
        container.name = "planet"
        addChild(container)

        // Back ring half — drawn behind planet body
        let ringBack = makePlanetRing(radius: radius, alpha: 0.22, zPos: -1)
        container.addChild(ringBack)

        // Planet surface — radial gradient rendered as texture once at setup
        let surfaceTex = makePlanetSurfaceTexture(radius: radius)
        let body = SKSpriteNode(texture: surfaceTex, size: CGSize(width: radius * 2, height: radius * 2))
        body.zPosition = 0
        container.addChild(body)

        // Atmospheric rim glow — thin cyan-violet ring around the sphere
        let rim = SKShapeNode(circleOfRadius: radius + 5)
        rim.fillColor   = .clear
        rim.strokeColor = UIColor(red: 0.45, green: 0.20, blue: 0.90, alpha: 0.45)
        rim.lineWidth   = 5.0
        rim.blendMode   = .add
        rim.zPosition   = 1
        container.addChild(rim)

        // Outer atmosphere haze (wider, softer)
        let haze = SKShapeNode(circleOfRadius: radius + 14)
        haze.fillColor   = .clear
        haze.strokeColor = UIColor(red: 0.30, green: 0.10, blue: 0.70, alpha: 0.18)
        haze.lineWidth   = 4.0
        haze.blendMode   = .add
        haze.zPosition   = 1
        container.addChild(haze)

        // Front ring half — drawn in front of planet body
        let ringFront = makePlanetRing(radius: radius, alpha: 0.42, zPos: 2)
        container.addChild(ringFront)

        // Gentle float — planet breathes up and down
        container.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 0, y: 10, duration: 7.0),
            SKAction.moveBy(x: 0, y: -10, duration: 7.0)
        ])))

        // Planet entrance — delayed so camera shake settles first
        container.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.2),
            SKAction.group([
                SKAction.fadeAlpha(to: 0.92, duration: 1.4),
                SKAction.moveBy(x: 0, y: 12, duration: 1.4)
            ])
        ]))
    }

    // Radial-gradient planet surface rendered once into a UIImage → SKTexture.
    // Simulates a light source above-left with darker limb darkening on the right.
    private func makePlanetSurfaceTexture(radius: CGFloat) -> SKTexture {
        let size = CGSize(width: radius * 2, height: radius * 2)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cgCtx  = ctx.cgContext
            let center = CGPoint(x: radius, y: radius)

            // Clip all drawing to the planet circle
            cgCtx.addEllipse(in: CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2))
            cgCtx.clip()

            // Base colour — deep indigo gradient lit from top-left
            guard let baseGrad = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 0.22, green: 0.12, blue: 0.48, alpha: 1.0).cgColor,
                    UIColor(red: 0.10, green: 0.05, blue: 0.24, alpha: 1.0).cgColor,
                    UIColor(red: 0.05, green: 0.02, blue: 0.14, alpha: 1.0).cgColor
                ] as CFArray,
                locations: [0.0, 0.55, 1.0]) else { return }

            let lightPt = CGPoint(x: radius * 0.55, y: radius * 1.55)
            cgCtx.drawRadialGradient(baseGrad,
                startCenter: lightPt, startRadius: 0,
                endCenter:   center,  endRadius:   radius * 1.1,
                options:     [.drawsAfterEndLocation])

            // Horizontal surface bands — gas-giant look
            let bands: [(y: CGFloat, h: CGFloat, r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)] = [
                (radius * 0.22, radius * 0.11, 0.32, 0.14, 0.60, 0.50),
                (radius * 0.52, radius * 0.08, 0.10, 0.05, 0.28, 0.55),
                (radius * 0.78, radius * 0.09, 0.28, 0.16, 0.58, 0.42),
                (radius * 1.18, radius * 0.08, 0.10, 0.05, 0.26, 0.52),
                (radius * 1.52, radius * 0.11, 0.24, 0.12, 0.52, 0.45),
            ]
            for b in bands {
                cgCtx.setFillColor(UIColor(red: b.r, green: b.g, blue: b.b, alpha: b.a).cgColor)
                cgCtx.fill(CGRect(x: 0, y: b.y - b.h, width: radius * 2, height: b.h * 2))
            }

            // Specular highlight — soft white spot upper-left
            guard let specGrad = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor.white.withAlphaComponent(0.18).cgColor,
                    UIColor.white.withAlphaComponent(0.00).cgColor
                ] as CFArray,
                locations: [0.0, 1.0]) else { return }

            let specPt = CGPoint(x: radius * 0.52, y: radius * 1.48)
            cgCtx.drawRadialGradient(specGrad,
                startCenter: specPt, startRadius: 0,
                endCenter:   specPt, endRadius:   radius * 0.75,
                options:     [])
        }
        return SKTexture(image: image)
    }

    // Full ellipse ring. Placing two instances at z:-1 (dim) and z:+2 (bright) with
    // the planet body at z:0 in between creates a natural split-ring illusion.
    private func makePlanetRing(radius: CGFloat, alpha: CGFloat, zPos: CGFloat) -> SKShapeNode {
        let ringW = radius * 1.85
        let ringH = radius * 0.24
        let rect  = CGRect(x: -ringW, y: -ringH / 2, width: ringW * 2, height: ringH)
        let ring  = SKShapeNode(path: UIBezierPath(ovalIn: rect).cgPath)
        ring.fillColor   = UIColor(red: 0.55, green: 0.32, blue: 0.88, alpha: alpha * 0.25)
        ring.strokeColor = UIColor(red: 0.62, green: 0.38, blue: 0.92, alpha: alpha)
        ring.lineWidth   = kDeviceTablet ? 3.5 : 2.5
        ring.blendMode   = .add
        ring.zPosition   = zPos
        return ring
    }

    // MARK: - Shooting Stars

    // Schedules periodic shooting-star streaks at random intervals (4–11 s).
    private func startShootingStars() {
        let spawnLoop = SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: 5.5, withRange: 5.5),
            SKAction.run { [weak self] in self?.spawnShootingStar() }
        ]))
        run(spawnLoop, withKey: "shootingStars")
    }

    private func spawnShootingStar() {
        // Spawn from top edge or right edge, travel diagonally downward-left
        let fromRight = Bool.random()
        let startX: CGFloat = fromRight
            ? kViewSize.width + 20
            : CGFloat.random(in: kViewSize.width * 0.3 ... kViewSize.width)
        let startY: CGFloat = fromRight
            ? CGFloat.random(in: kViewSize.height * 0.5 ... kViewSize.height + 20)
            : kViewSize.height + 20

        let travelX  = CGFloat.random(in: -kViewSize.width * 0.85 ... -kViewSize.width * 0.45)
        let travelY  = CGFloat.random(in: -kViewSize.height * 0.65 ... -kViewSize.height * 0.35)
        let dist     = sqrt(travelX * travelX + travelY * travelY)
        let speed    = CGFloat.random(in: 900...1500)
        let duration = Double(dist / speed)
        let angle    = atan2(travelY, travelX) + .pi / 2

        // White core streak
        let streakLen = CGFloat.random(in: 55...110)
        let streak    = SKSpriteNode(color: .white, size: CGSize(width: 1.5, height: streakLen))
        streak.alpha     = 0
        streak.blendMode = .add
        streak.zRotation = angle
        streak.zPosition = 3
        streak.position  = CGPoint(x: startX, y: startY)
        addChild(streak)

        // Soft cyan glow copy (wider, dimmer)
        let glow = SKSpriteNode(
            color: UIColor(red: 0.6, green: 0.9, blue: 1.0, alpha: 1.0),
            size: CGSize(width: 4, height: streakLen))
        glow.blendMode   = .add
        glow.zRotation   = angle
        glow.zPosition   = 2
        glow.position    = streak.position
        addChild(glow)

        let move = SKAction.moveBy(x: travelX, y: travelY, duration: duration)

        streak.run(SKAction.group([move, SKAction.sequence([
            SKAction.fadeAlpha(to: 1.0,  duration: duration * 0.08),
            SKAction.fadeAlpha(to: 0.85, duration: duration * 0.72),
            SKAction.fadeOut(withDuration: duration * 0.20),
            SKAction.removeFromParent()
        ])]))

        glow.run(SKAction.group([
            SKAction.moveBy(x: travelX, y: travelY, duration: duration),
            SKAction.sequence([
                SKAction.fadeAlpha(to: 0.35, duration: duration * 0.08),
                SKAction.fadeAlpha(to: 0.25, duration: duration * 0.72),
                SKAction.fadeOut(withDuration: duration * 0.20),
                SKAction.removeFromParent()
            ])
        ]))
    }

    // MARK: - Background Debris

    // Spawns slow, low-opacity decorative asteroids drifting downward —
    // the same feel as the gameplay backdrop but non-interactive.
    private func startBackgroundDebris() {
        // Seed a few rocks on-screen immediately so it doesn't feel empty at first
        for i in 0..<4 {
            let delay = Double(i) * 1.2
            run(SKAction.wait(forDuration: delay)) {
                self.spawnBackgroundRock(startY: CGFloat.random(
                    in: kViewSize.height * 0.2 ... kViewSize.height * 0.95))
            }
        }

        // Continuous trickle thereafter
        run(SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: 3.5, withRange: 2.5),
            SKAction.run { [weak self] in
                self?.spawnBackgroundRock(startY: kViewSize.height + 60)
            }
        ])), withKey: "debris")
    }

    private func spawnBackgroundRock(startY: CGFloat) {
        // Randomly pick from the available meteor sizes
        let names = [SpriteName.MeteorHuge, SpriteName.MeteorLarge,
                     SpriteName.MeteorMedium, SpriteName.MeteorSmall]
        let texName = names.randomElement()!
        let tex  = GameTextures.sharedInstance.textureWithName(name: texName)
        let rock = SKSpriteNode(texture: tex)

        // Scale so the largest rock fits nicely without dominating the screen
        let targetW = CGFloat.random(in: 40...90)
        let scale   = targetW / rock.size.width
        rock.setScale(scale)

        // Very low opacity — these are background ambience, not obstacles
        rock.alpha    = CGFloat.random(in: 0.08...0.22)
        rock.blendMode = .add

        // Drift speed slower than actual game so it feels like distant parallax
        let driftSpeed = CGFloat.random(in: 55...120)  // pts/s
        let duration   = Double((startY + rock.size.height) / driftSpeed)

        rock.position = CGPoint(
            x: CGFloat.random(in: rock.size.width / 2 ... kViewSize.width - rock.size.width / 2),
            y: startY)
        rock.zPosition = 2

        // Gentle tumble
        let rotateDur = Double.random(in: 6...18)
        rock.run(SKAction.repeatForever(
            SKAction.rotate(byAngle: Bool.random() ? .pi * 2 : -.pi * 2, duration: rotateDur)))

        addChild(rock)
        rock.run(SKAction.sequence([
            SKAction.moveBy(x: CGFloat.random(in: -25...25), y: -startY - rock.size.height * 2, duration: duration),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Controls Hints Card

    // Three-column glass card: TAP | TILT | DASH — fades in after the play button.
    private func setupControlsHints() {
        let cardW: CGFloat = kDeviceTablet ? 340 : 280
        let cardH: CGFloat = kDeviceTablet ? 80  : 68
        let cardY = kViewSize.height * 0.22

        let card = SKNode()
        card.position = CGPoint(x: kViewSize.width / 2, y: cardY)
        card.alpha    = 0
        card.name     = "controlsCard"
        addChild(card)

        // Glass pill background
        let bg = SKShapeNode(
            rect: CGRect(x: -cardW / 2, y: -cardH / 2, width: cardW, height: cardH),
            cornerRadius: cardH / 2)
        bg.fillColor   = UIColor(red: 0.00, green: 0.88, blue: 1.00, alpha: 0.07)
        bg.strokeColor = UIColor(red: 0.00, green: 0.88, blue: 1.00, alpha: 0.38)
        bg.lineWidth   = 1.0
        card.addChild(bg)

        // Subtle shimmer on the glass
        let shimmer = SKShapeNode(
            rect: CGRect(x: -cardW / 2, y: 0, width: cardW, height: cardH / 2),
            cornerRadius: cardH / 2)
        shimmer.fillColor   = UIColor.white.withAlphaComponent(0.04)
        shimmer.strokeColor = .clear
        card.addChild(shimmer)

        let entries: [(icon: String, action: String, detail: String)] = [
            ("👆", "TAP",    "to steer"),
            ("📱", "TILT",   "to fly"),
            ("⚡", "2× TAP", "to dash"),
        ]

        let colW = cardW / CGFloat(entries.count)

        for (i, entry) in entries.enumerated() {
            let cx = -cardW / 2 + colW * (CGFloat(i) + 0.5)

            // Divider (between columns)
            if i > 0 {
                let div = SKSpriteNode(
                    color: UIColor(red: 0.00, green: 0.88, blue: 1.00, alpha: 0.22),
                    size: CGSize(width: 1, height: cardH * 0.55))
                div.position = CGPoint(x: cx - colW / 2, y: 0)
                card.addChild(div)
            }

            // Icon
            let icon = SKLabelNode(text: entry.icon)
            icon.fontSize                 = kDeviceTablet ? 22 : 18
            icon.horizontalAlignmentMode  = .center
            icon.verticalAlignmentMode    = .center
            icon.position                 = CGPoint(x: cx, y: 12)
            card.addChild(icon)

            // Action label (cyan, bold)
            let actionLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
            actionLbl.text                    = entry.action
            actionLbl.fontSize                = kDeviceTablet ? 13 : 11
            actionLbl.fontColor               = UIColor(red: 0.00, green: 0.88, blue: 1.00, alpha: 1.0)
            actionLbl.horizontalAlignmentMode = .center
            actionLbl.verticalAlignmentMode   = .center
            actionLbl.position                = CGPoint(x: cx, y: -6)
            card.addChild(actionLbl)

            // Detail label (white, dim)
            let detailLbl = SKLabelNode(fontNamed: "AvenirNext-Regular")
            detailLbl.text                    = entry.detail
            detailLbl.fontSize                = kDeviceTablet ? 11 : 10
            detailLbl.fontColor               = UIColor.white.withAlphaComponent(0.55)
            detailLbl.horizontalAlignmentMode = .center
            detailLbl.verticalAlignmentMode   = .center
            detailLbl.position                = CGPoint(x: cx, y: -20)
            card.addChild(detailLbl)
        }

        // Staggered entrance — card slides up after the play button pops in
        card.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.7),
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.7),
                SKAction.moveBy(x: 0, y: 8, duration: 0.7)
            ])
        ]))

        // Gentle breathing glow on the border
        bg.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: 3.2),
            SKAction.customAction(withDuration: 0.0) { node, _ in
                (node as? SKShapeNode)?.strokeColor =
                    UIColor(red: 0.00, green: 0.88, blue: 1.00, alpha: 0.65)
            },
            SKAction.wait(forDuration: 1.8),
            SKAction.customAction(withDuration: 0.0) { node, _ in
                (node as? SKShapeNode)?.strokeColor =
                    UIColor(red: 0.00, green: 0.88, blue: 1.00, alpha: 0.38)
            }
        ])))
    }

    // MARK: - Menu Volume Slider (UIKit overlay)

    private func setupMenuVolumeSlider(in view: SKView) {
        let sliderW: CGFloat    = 165
        let containerW: CGFloat = sliderW + 78
        let containerH: CGFloat = 36
        let x = (view.bounds.width  - containerW) / 2
        // Sits between the controls card and the copyright strip at the bottom
        let y = view.bounds.height - view.bounds.height * 0.145

        let container = UIView(frame: CGRect(x: x, y: y, width: containerW, height: containerH))
        container.backgroundColor = UIColor(red: 0.02, green: 0.05, blue: 0.16, alpha: 0.80)
        container.layer.cornerRadius = containerH / 2
        container.alpha = 0  // fades in via UIView animation after scene settles

        // Speaker icon
        let iconLbl = UILabel(frame: CGRect(x: 10, y: 0, width: 24, height: containerH))
        iconLbl.text          = "🔊"
        iconLbl.font          = UIFont.systemFont(ofSize: 13)
        iconLbl.textAlignment = .center
        container.addSubview(iconLbl)

        // "VOL" label
        let volLbl = UILabel(frame: CGRect(x: 34, y: 0, width: 28, height: containerH))
        volLbl.text          = "VOL"
        volLbl.font          = UIFont.systemFont(ofSize: 9, weight: .bold)
        volLbl.textColor     = UIColor(red: 0.00, green: 0.88, blue: 1.00, alpha: 0.85)
        volLbl.textAlignment = .left
        container.addSubview(volLbl)

        // Slider
        let slider = UISlider(frame: CGRect(x: 62, y: 8, width: sliderW, height: containerH - 16))
        slider.minimumValue       = 0
        slider.maximumValue       = 1
        slider.value              = GameAudio.shared.musicVolume
        slider.minimumTrackTintColor = UIColor(red: 0.00, green: 0.88, blue: 1.00, alpha: 0.90)
        slider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.18)
        slider.thumbTintColor     = UIColor.white

        slider.addAction(UIAction { _ in
            GameAudio.shared.setMusicVolume(slider.value)
        }, for: .valueChanged)

        container.addSubview(slider)
        view.addSubview(container)
        menuVolumeContainer = container

        // Fade the slider in after the controls card appears
        UIView.animate(withDuration: 0.8, delay: 3.2, options: .curveEaseOut) {
            container.alpha = 1
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        modernPlayButton = ModernStartButton()
        modernPlayButton.position = CGPoint(x: kViewSize.width / 2, y: kViewSize.height * 0.35)
        modernPlayButton.setScale(0.0)
        addChild(modernPlayButton)

        gameTitle = GameTitle()
        addChild(gameTitle)

        shipAssembly = ShipAssemblyAnimation()
    }

    private func setupGlassEffects() {
        glassContainer = SKNode()
        addChild(glassContainer)

        let glassBackground = createGlassBackground()
        glassBackground.position = CGPoint(x: kViewSize.width / 2, y: kViewSize.height * 0.35)
        glassContainer.addChild(glassBackground)
        glassContainer.alpha = 0.0
    }

    private func createGlassBackground() -> SKShapeNode {
        let rect = CGRect(x: -120, y: -80, width: 240, height: 160)
        let glassShape = SKShapeNode(rect: rect, cornerRadius: 25)
        glassShape.fillColor   = SKColor.white.withAlphaComponent(0.10)
        glassShape.strokeColor = SKColor.cyan.withAlphaComponent(0.30)
        glassShape.lineWidth   = 2.0

        let innerGlow = SKShapeNode(rect: rect.insetBy(dx: 5, dy: 5), cornerRadius: 20)
        innerGlow.fillColor   = SKColor.clear
        innerGlow.strokeColor = SKColor.white.withAlphaComponent(0.20)
        innerGlow.lineWidth   = 1.0
        glassShape.addChild(innerGlow)

        return glassShape
    }

    // MARK: - Info Labels

    private func setupInfoLabels() {
        let appVersion  = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        infoContainer          = SKNode()
        infoContainer.position = CGPoint(x: kViewSize.width / 2, y: 52)
        infoContainer.alpha    = 0
        addChild(infoContainer)

        authorLabel                          = SKLabelNode(fontNamed: "AvenirNext-Medium")
        authorLabel.text                     = "© 2026 Todd Dube"
        authorLabel.fontSize                 = 13
        authorLabel.fontColor                = .white
        authorLabel.horizontalAlignmentMode  = .center
        authorLabel.verticalAlignmentMode    = .center
        authorLabel.position                 = CGPoint(x: 0, y: 14)
        infoContainer.addChild(authorLabel)

        versionLabel                         = SKLabelNode(fontNamed: "AvenirNext-Light")
        versionLabel.text                    = "v\(appVersion)  ·  build \(buildNumber)"
        versionLabel.fontSize                = 11
        versionLabel.fontColor               = SKColor.cyan.withAlphaComponent(0.85)
        versionLabel.horizontalAlignmentMode = .center
        versionLabel.verticalAlignmentMode   = .center
        versionLabel.position                = CGPoint(x: 0, y: -2)
        infoContainer.addChild(versionLabel)

        let accent     = SKSpriteNode(color: SKColor.cyan.withAlphaComponent(0.35),
                                      size: CGSize(width: 180, height: 0.5))
        accent.blendMode = .add
        accent.position  = CGPoint(x: 0, y: 7)
        infoContainer.addChild(accent)

        let halo        = SKShapeNode(rectOf: CGSize(width: 210, height: 36), cornerRadius: 10)
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

        let best = GameSettings.shared.bestScore
        if best > 0 {
            let fmt = NumberFormatter(); fmt.numberStyle = .decimal
            let bestLabel                         = SKLabelNode(fontNamed: "AvenirNext-Bold")
            bestLabel.text                        = "BEST  \(fmt.string(from: NSNumber(value: best)) ?? "\(best)")"
            bestLabel.fontSize                    = 15
            bestLabel.fontColor                   = SKColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 0.85)
            bestLabel.horizontalAlignmentMode     = .center
            bestLabel.position = CGPoint(x: kViewSize.width / 2, y: kViewSize.height * 0.27)
            bestLabel.alpha    = 0
            addChild(bestLabel)
            bestLabel.run(SKAction.sequence([
                SKAction.wait(forDuration: 2.4),
                SKAction.fadeAlpha(to: 0.85, duration: 0.6)
            ]))
        }

        setupInfoLabelAnimations()
    }

    private func setupInfoLabelAnimations() {
        authorLabel.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.colorize(with: .white,
                              colorBlendFactor: 1, duration: 2.5),
            SKAction.colorize(with: SKColor(red: 0.4, green: 1.0, blue: 1.0, alpha: 1),
                              colorBlendFactor: 1, duration: 2.5),
            SKAction.colorize(with: .white,
                              colorBlendFactor: 1, duration: 2.5),
            SKAction.colorize(with: SKColor(red: 1.0, green: 0.5, blue: 1.0, alpha: 1),
                              colorBlendFactor: 1, duration: 2.5)
        ])))

        versionLabel.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.45, duration: 3.0),
            SKAction.fadeAlpha(to: 0.85, duration: 3.0)
        ])))

        infoContainer.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: 0.55, withRange: 0.7),
            SKAction.run { [weak self] in self?.spawnInfoSparkle() }
        ])), withKey: "sparkles")
    }

    private func spawnInfoSparkle() {
        let radius  = CGFloat.random(in: 0.7...2.2)
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
        sparkle.position    = CGPoint(x: CGFloat.random(in: -105...105),
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

    // MARK: - Scene Intro Animation

    private func animateSceneIntro() {
        cameraEffects.performGameStartShake()

        let assemblyPos = CGPoint(x: kViewSize.width / 2, y: kViewSize.height * 0.57)
        run(SKAction.wait(forDuration: 0.7)) {
            self.shipAssembly?.runAssembly(in: self, at: assemblyPos)
        }

        glassContainer.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.fadeIn(withDuration: 0.8)
        ]))

        modernPlayButton.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            animationController.createPulseAnimation(scale: 1.0, duration: 0.6)
        ])) {
            let floating = self.animationController.createFloatingAnimation(distance: 5, duration: 3.0)
            self.modernPlayButton.run(SKAction.repeatForever(floating))
        }

        infoContainer.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.5),
            SKAction.group([
                SKAction.fadeIn(withDuration: 1.0),
                SKAction.moveBy(x: 0, y: 10, duration: 1.0)
            ])
        ]))

        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.run { self.dynamicLighting.transitionToGameplay() }
        ]))
    }

    // MARK: - Update

    public override func update(_ currentTime: TimeInterval) {
        let deltaTime: TimeInterval = lastUpdateTime > 0
            ? min(currentTime - lastUpdateTime, 1.0 / 30.0)
            : 1.0 / 60.0
        lastUpdateTime = currentTime

        // 0.5 gameSpeed — faster scroll makes the menu feel alive vs 0.3
        parallaxBackground.update(deltaTime: deltaTime, gameSpeed: 0.5)
        nebulae.update(deltaTime: deltaTime)
        dynamicLighting.update(playerPosition: CGPoint(x: kViewSize.width / 2,
                                                       y: kViewSize.height / 2))
        cameraEffects.update(deltaTime: deltaTime)
    }

    // MARK: - Touch Events

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)

        if modernPlayButton.contains(touchLocation) {
            modernPlayButton.run(SKAction.sequence([
                SKAction.scale(to: 0.9, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
            GameAudio.shared.playSoundEffect(.buttonTap)
            createTouchSparkles(at: touchLocation)

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

            let angle    = Float.random(in: 0...(2 * Float.pi))
            let distance = CGFloat.random(in: 30...60)
            let target   = CGPoint(x: position.x + cos(CGFloat(angle)) * distance,
                                   y: position.y + sin(CGFloat(angle)) * distance)

            sparkle.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: target, duration: 0.6),
                    SKAction.fadeOut(withDuration: 0.6),
                    SKAction.scale(to: 0.1, duration: 0.6)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Scene Transition

    private func transitionToGame() {
        cameraEffects.performImpactShake()
        removeAction(forKey: "shootingStars")
        removeAction(forKey: "debris")
        menuVolumeContainer?.removeFromSuperview()
        menuVolumeContainer = nil

        // Ship launches upward before the scene fade
        let shipTex    = GameTextures.sharedInstance.textureWithName(name: SpriteName.Player)
        let launchShip = SKSpriteNode(texture: shipTex)
        launchShip.setScale(0.85)
        launchShip.position  = CGPoint(x: kViewSize.width / 2, y: kViewSize.height * 0.57)
        launchShip.zPosition = 100
        addChild(launchShip)

        let engineGlow = SKShapeNode(ellipseOf: CGSize(width: 18, height: 8))
        engineGlow.fillColor   = Colors.colorFromRGB(rgbvalue: Colors.AccentCyan)
        engineGlow.strokeColor = .clear
        engineGlow.blendMode   = .add
        engineGlow.alpha       = 0.8
        engineGlow.position    = CGPoint(x: 0, y: -launchShip.size.height * 0.4)
        engineGlow.zPosition   = -1
        launchShip.addChild(engineGlow)

        let windUp = SKAction.moveBy(x: 0, y: -8, duration: 0.12)
        let blast  = SKAction.moveBy(x: 0, y: kViewSize.height * 1.6, duration: 0.45)
        blast.timingMode = .easeIn
        let glowPop = SKAction.sequence([
            SKAction.scale(to: 1.4, duration: 0.08),
            SKAction.scale(to: 1.0, duration: 0.35)
        ])
        launchShip.run(SKAction.sequence([windUp, blast]))
        engineGlow.run(glowPop)

        run(SKAction.wait(forDuration: 0.42)) { [weak self] in
            guard let self else { return }
            let gameScene  = GameScene(size: kViewSize)
            let transition = SKTransition.fade(with: .black, duration: 0.5)
            transition.pausesIncomingScene = false
            self.view?.presentScene(gameScene, transition: transition)
        }
    }
}
