//
//  StatusBar.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Compact top-of-screen HUD that shows game state in a dark glass strip pinned
//  below the device safe area (Dynamic Island / notch / status bar).
//
//  LAYOUT  (left → right)
//  [❚❚ pause] [♥♥♥ lives] [   score   ] [★ stars] [T1] [●]
//
//  The glass background extends from the top of the safe area down to the
//  bottom edge of the content strip, so it merges with the system status bar
//  area and leaves gameplay space clear below.
//
//  PUBLIC API
//  - init(lives:score:stars:safeAreaTop:)  — build and lay out the HUD
//  - updateScore(_:)                       — refresh score label
//  - updateLives(_:)                       — rebuild life icons
//  - updateStarsCollected(_:)              — refresh star count + bounce
//  - updateTier(_:)                        — color-coded tier badge
//  - updatePowerUpStatus(shield:magnet:slowMo:) — pulsing power-up dot
//  - pauseButtonTapRect                    — CGRect in statusBar's coordinate space
//  - show(with:) / hide(with:)             — entrance/exit animations (extension)
//  - reset()                               — restore to run-start values
//

import Foundation
import SpriteKit
import UIKit

class StatusBar: SKNode {

    // MARK: - Layout constants (set during init)
    private var barY: CGFloat = 0           // statusBar-space Y of bar bottom edge
    private var contentCenterY: CGFloat = 0 // Y of element center row
    private var contentHeight: CGFloat = 38 // visual strip below safe area

    // MARK: - Nodes
    private var barBackground: SKShapeNode!
    // internal — used by StatusBar+GlassEffect.swift extension for reactive animations
    var livesContainer = SKNode()
    var scoreLabel     = SKLabelNode()
    var starIcon       = SKSpriteNode()
    var starCountLabel = SKLabelNode()
    private var tierLabel  = SKLabelNode()
    private var powerUpDot = SKShapeNode(circleOfRadius: 5)

    // MARK: - Public
    let pauseButton = PauseButton()

    /// Hit rectangle for the pause button, in statusBar's coordinate space.
    private(set) var pauseButtonTapRect: CGRect = .zero

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
    override init() { super.init() }

    convenience init(lives: Int, score: Int, stars: Int, safeAreaTop: CGFloat) {
        self.init()

        contentHeight  = kDeviceTablet ? 44 : 38
        let totalHeight = safeAreaTop + contentHeight
        barY           = kViewSize.height - totalHeight
        contentCenterY = barY + contentHeight / 2

        setupBackground(totalHeight: totalHeight)
        setupPauseButton()
        setupScore(score)
        setupStarSection(stars)
        setupTierAndPowerUp()

        // Lives drawn last so it refreshes cleanly on updateLives()
        updateLives(lives: lives)

        zPosition = 100
    }

    // MARK: - Glass Background

    private func setupBackground(totalHeight: CGFloat) {
        // Dark glass panel — spans safe area + content strip
        let bgRect = CGRect(x: 0, y: barY, width: kViewSize.width, height: totalHeight)
        barBackground = SKShapeNode(rect: bgRect)
        barBackground.fillColor   = UIColor(red: 0.02, green: 0.05, blue: 0.16, alpha: 0.92)
        barBackground.strokeColor = .clear
        barBackground.zPosition   = 0
        addChild(barBackground)

        // Subtle shimmer — rendered once as a texture, zero runtime cost
        addGlassShimmer(rect: bgRect)

        // Cyan accent line along the bottom edge of the bar
        let edgeLine = SKSpriteNode(
            color: UIColor(red: 0.00, green: 0.88, blue: 1.00, alpha: 0.55),
            size: CGSize(width: kViewSize.width, height: 1.0))
        edgeLine.anchorPoint = CGPoint(x: 0, y: 0)
        edgeLine.position    = CGPoint(x: 0, y: barY)
        edgeLine.blendMode   = .add
        edgeLine.zPosition   = 2
        addChild(edgeLine)
    }

    private func addGlassShimmer(rect: CGRect) {
        let renderer = UIGraphicsImageRenderer(size: rect.size)
        let image = renderer.image { ctx in
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor.white.withAlphaComponent(0.16).cgColor,
                    UIColor.white.withAlphaComponent(0.03).cgColor,
                    UIColor.white.withAlphaComponent(0.09).cgColor
                ] as CFArray,
                locations: [0.0, 0.55, 1.0])!
            // Gradient from top (bright) to bottom (darker) of the bar
            ctx.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: rect.height),
                end:   CGPoint(x: 0, y: 0),
                options: [])
        }
        let shimmer = SKSpriteNode(texture: SKTexture(image: image))
        shimmer.anchorPoint = CGPoint(x: 0, y: 0)
        shimmer.position    = CGPoint(x: 0, y: barY)
        shimmer.blendMode   = .add
        shimmer.alpha       = 0.85
        shimmer.zPosition   = 1
        addChild(shimmer)
    }

    // MARK: - Pause Button

    private func setupPauseButton() {
        let targetH = contentHeight * 0.65
        let scale   = targetH / pauseButton.size.height
        pauseButton.setScale(scale)

        let cx = kDeviceTablet ? CGFloat(22) : CGFloat(20)
        pauseButton.position  = CGPoint(x: cx, y: contentCenterY)
        pauseButton.zPosition = 10
        addChild(pauseButton)

        // Generous tap target (44 × 44 minimum per HIG)
        let tapSize: CGFloat = max(44, targetH + 16)
        pauseButtonTapRect = CGRect(
            x: cx - tapSize / 2, y: contentCenterY - tapSize / 2,
            width: tapSize, height: tapSize)
    }

    // MARK: - Lives

    func updateLives(lives: Int) {
        livesContainer.removeFromParent()
        livesContainer = SKNode()
        livesContainer.zPosition = 5
        addChild(livesContainer)

        let iconH   = contentHeight * 0.36
        let sample  = GameTextures.sharedInstance.spriteWithName(name: SpriteName.PlayerLives)
        let scale   = iconH / sample.size.height
        let iconW   = sample.size.width * scale
        let spacing = iconW * 1.40
        let startX: CGFloat = kDeviceTablet ? 60 : 50

        for i in 0..<max(0, min(lives, 5)) {
            let icon = GameTextures.sharedInstance.spriteWithName(name: SpriteName.PlayerLives)
            icon.setScale(scale)
            icon.position  = CGPoint(x: startX + spacing * CGFloat(i), y: contentCenterY)
            icon.zPosition = 5
            livesContainer.addChild(icon)
        }
    }

    // MARK: - Score

    private func setupScore(_ score: Int) {
        scoreLabel.fontName  = "AvenirNext-Heavy"
        scoreLabel.fontSize  = kDeviceTablet ? 20 : 17
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode   = .center
        scoreLabel.text      = format(score)
        scoreLabel.position  = CGPoint(x: kViewSize.width / 2, y: contentCenterY)
        scoreLabel.zPosition = 5
        addChild(scoreLabel)
    }

    func updateScore(score: Int) {
        scoreLabel.text = format(score)
    }

    private func format(_ score: Int) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        return fmt.string(from: NSNumber(value: score)) ?? "\(score)"
    }

    // MARK: - Stars

    private func setupStarSection(_ count: Int) {
        // Spinning star icon
        let rawTex = GameTextures.sharedInstance.textureWithName(name: SpriteName.StarIcon)
        starIcon = SKSpriteNode(texture: rawTex)
        let iconH: CGFloat = contentHeight * 0.20
        starIcon.size = CGSize(width: iconH, height: iconH)

        let sectionX = kViewSize.width * 0.725
        starIcon.position  = CGPoint(x: sectionX, y: contentCenterY)
        starIcon.zPosition = 5
        addChild(starIcon)

        starIcon.run(SKAction.repeatForever(
            SKAction.rotate(byAngle: .pi * 2, duration: 5.0)))

        // Star count label
        let labelX = sectionX + iconH / 2 + 5
        starCountLabel.fontName  = "AvenirNext-DemiBold"
        starCountLabel.fontSize  = kDeviceTablet ? 16 : 14
        starCountLabel.fontColor = UIColor(red: 1.0, green: 0.88, blue: 0.10, alpha: 1.0)
        starCountLabel.horizontalAlignmentMode = .left
        starCountLabel.verticalAlignmentMode   = .center
        starCountLabel.text      = "\(count)"
        starCountLabel.position  = CGPoint(x: labelX, y: contentCenterY)
        starCountLabel.zPosition = 5
        addChild(starCountLabel)
    }

    func updateStarsCollected(collected: Int) {
        starCountLabel.text = "\(collected)"
        starIcon.run(bounce())
    }

    // MARK: - Tier + Power-up

    private func setupTierAndPowerUp() {
        tierLabel.fontName  = "AvenirNext-Bold"
        tierLabel.fontSize  = kDeviceTablet ? 12 : 11
        tierLabel.fontColor = Colors.colorFromRGB(rgbvalue: Colors.AccentCyan)
        tierLabel.horizontalAlignmentMode = .right
        tierLabel.verticalAlignmentMode   = .center
        tierLabel.text      = "T1"
        tierLabel.alpha     = 0.85
        tierLabel.position  = CGPoint(x: kViewSize.width - 26, y: contentCenterY)
        tierLabel.zPosition = 5
        addChild(tierLabel)

        powerUpDot.fillColor   = .clear
        powerUpDot.strokeColor = .clear
        powerUpDot.position    = CGPoint(x: kViewSize.width - 9, y: contentCenterY)
        powerUpDot.zPosition   = 5
        addChild(powerUpDot)
    }

    func updateTier(_ tier: Int) {
        tierLabel.text = "T\(tier)"
        let colors: [Int: UIColor] = [
            1: Colors.colorFromRGB(rgbvalue: Colors.AccentCyan),
            2: Colors.colorFromRGB(rgbvalue: Colors.AccentYellow),
            3: Colors.colorFromRGB(rgbvalue: Colors.AccentMagenta),
            4: Colors.colorFromRGB(rgbvalue: Colors.DangerRed)
        ]
        tierLabel.fontColor = colors[tier] ?? Colors.colorFromRGB(rgbvalue: Colors.AccentCyan)
        tierLabel.run(SKAction.sequence([
            SKAction.scale(to: 1.4, duration: 0.10),
            SKAction.scale(to: 1.0, duration: 0.12)
        ]))
    }

    func updatePowerUpStatus(shield: Bool, magnet: Bool, slowMo: Bool) {
        let color: UIColor?
        if shield {
            color = Colors.colorFromRGB(rgbvalue: Colors.AccentCyan)
        } else if magnet {
            color = Colors.colorFromRGB(rgbvalue: Colors.AccentYellow)
        } else if slowMo {
            color = UIColor(red: 0.00, green: 1.00, blue: 0.80, alpha: 1.0)
        } else {
            color = nil
        }

        if let c = color {
            powerUpDot.fillColor   = c
            powerUpDot.strokeColor = c
            if powerUpDot.action(forKey: "pulse") == nil {
                powerUpDot.run(SKAction.repeatForever(SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.35, duration: 0.40),
                    SKAction.fadeAlpha(to: 1.00, duration: 0.40)
                ])), withKey: "pulse")
            }
        } else {
            powerUpDot.fillColor   = .clear
            powerUpDot.strokeColor = .clear
            powerUpDot.removeAction(forKey: "pulse")
            powerUpDot.alpha = 1.0
        }
    }

    // MARK: - Reset

    func reset() {
        updateScore(score: 0)
        updateLives(lives: 3)
        updateStarsCollected(collected: 0)
        updateTier(1)
        updatePowerUpStatus(shield: false, magnet: false, slowMo: false)
        scoreLabel.removeAllActions()
        pauseButton.removeAllActions()
        pauseButton.resetToPlayIcon()
        pauseButton.alpha = 1.0
        alpha = 1.0
    }

    // MARK: - Shared animation

    func bounce() -> SKAction {
        SKAction.sequence([
            SKAction.scale(to: 1.45, duration: 0.10),
            SKAction.scale(to: 1.00, duration: 0.10)
        ])
    }
}
