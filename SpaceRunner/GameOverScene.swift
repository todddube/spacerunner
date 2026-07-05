//
//  GameOverScene.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  End-of-run screen shown after the player's ship is destroyed.
//  Presents an animated score card, retry/menu/share buttons, and
//  a parallax background system for visual continuity with gameplay.
//

import Foundation
import SpriteKit
import UIKit

class GameOverScene: SKScene {

    // MARK: - Properties
    private var score: Int = 0
    private var stars: Int = 0
    private var streak: Int = 0

    private var parallaxBackground: ParallaxBackground!
    private var nebulae: NebulaSystem!

    private var lastUpdateTime: TimeInterval = 0

    // Button hit rects (in scene coordinates)
    private var retryRect: CGRect = .zero
    private var menuRect:  CGRect = .zero
    private var shareRect: CGRect = .zero

    // Nodes we need to reference post-setup
    private var retryButtonNode: SKShapeNode!
    private var menuButtonNode:  SKShapeNode!
    private var shareButtonNode: SKShapeNode!
    private var newRecordLabel:  SKLabelNode?

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(size: CGSize) {
        super.init(size: size)
    }

    convenience init(size: CGSize, score: Int, stars: Int, streak: Int) {
        self.init(size: size)
        self.score  = score
        self.stars  = stars
        self.streak = streak
        setupScene()
    }

    // MARK: - Scene Setup
    private func setupScene() {
        backgroundColor = Colors.colorFromRGB(rgbvalue: Colors.Background)

        // Parallax background
        let pb = ParallaxBackground()
        pb.setupLayers(for: size)
        pb.startScrolling()
        pb.zPosition = CGFloat(GameLayer.Background)
        addChild(pb)
        parallaxBackground = pb

        // Nebula system
        let ns = NebulaSystem()
        ns.setupNebulae(for: size)
        ns.startAnimation()
        ns.zPosition = CGFloat(GameLayer.Background) + 1
        addChild(ns)
        nebulae = ns

        // Snapshot best score BEFORE updating so we can compare
        let prevBest = GameSettings.shared.bestScore
        GameSettings.shared.updateBestScore(score)
        GameSettings.shared.updateBestStars(stars)

        setupTitle()
        setupScoreCard(isNewRecord: score >= prevBest)
        setupButtons()
        setupAuthorLabel()

        if score > prevBest {
            let wait = SKAction.wait(forDuration: 1.2)
            let trigger = SKAction.run { [weak self] in self?.triggerNewRecordEffect() }
            run(SKAction.sequence([wait, trigger]))
        }
    }

    // MARK: - Title
    private func setupTitle() {
        let fontSize: CGFloat = kDeviceTablet ? 36 : 48
        let y = kViewSize.height * 0.78

        // Glow layer (behind)
        let glow = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        glow.text      = "GAME OVER"
        glow.fontSize  = fontSize
        glow.fontColor = Colors.colorFromRGB(rgbvalue: Colors.AccentMagenta)
        glow.alpha     = 0.3
        glow.setScale(1.04)
        glow.blendMode = .add
        glow.zPosition = CGFloat(GameLayer.Interface) - 1
        glow.horizontalAlignmentMode = .center
        glow.position  = CGPoint(x: kViewSize.width / 2, y: y)
        addChild(glow)

        // Main title
        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text      = "GAME OVER"
        title.fontSize  = fontSize
        title.fontColor = Colors.colorFromRGB(rgbvalue: Colors.AccentMagenta)
        title.zPosition = CGFloat(GameLayer.Interface)
        title.horizontalAlignmentMode = .center
        title.position  = CGPoint(x: kViewSize.width / 2, y: y)
        title.alpha     = 0
        title.setScale(0.7)
        addChild(title)

        title.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.35),
            SKAction.scale(to: 1.0, duration: 0.35)
        ]))
    }

    // MARK: - Score Card
    private func setupScoreCard(isNewRecord: Bool) {
        let cardW: CGFloat  = 300
        let cardH: CGFloat  = 200
        let cornerR: CGFloat = 20
        let cardY   = kViewSize.height * 0.50
        let cardX   = kViewSize.width / 2

        let cardRect = CGRect(x: -cardW / 2, y: -cardH / 2, width: cardW, height: cardH)
        let card = SKShapeNode(rect: cardRect, cornerRadius: cornerR)
        card.fillColor   = UIColor.white.withAlphaComponent(0.06)
        card.strokeColor = Colors.colorFromRGB(rgbvalue: Colors.AccentCyan).withAlphaComponent(0.25)
        card.lineWidth   = 1.5
        card.zPosition   = CGFloat(GameLayer.Interface)
        card.position    = CGPoint(x: cardX, y: cardY - 80)   // starts below
        addChild(card)

        // Slide in from below
        let slideIn = SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            SKAction.move(to: CGPoint(x: cardX, y: cardY), duration: 0.5)
        ])
        card.run(slideIn)

        // --- Card children (positions relative to card center 0,0) ---
        let rowSpacing: CGFloat = 36
        var curY: CGFloat = cardH * 0.3

        // "SCORE" header
        let scoreHeader = SKLabelNode(fontNamed: "AvenirNext-Medium")
        scoreHeader.text      = "SCORE"
        scoreHeader.fontSize  = 13
        scoreHeader.fontColor = Colors.colorFromRGB(rgbvalue: Colors.AccentCyan).withAlphaComponent(0.7)
        scoreHeader.horizontalAlignmentMode = .center
        scoreHeader.position  = CGPoint(x: 0, y: curY)
        card.addChild(scoreHeader)
        curY -= rowSpacing * 0.6

        // Score value (count-up)
        let scoreValue = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        scoreValue.text      = "0"
        scoreValue.fontSize  = 42
        scoreValue.fontColor = .white
        scoreValue.horizontalAlignmentMode = .center
        scoreValue.position  = CGPoint(x: 0, y: curY)
        card.addChild(scoreValue)
        curY -= rowSpacing * 1.1

        let targetScore = score
        let countUp = SKAction.customAction(withDuration: 1.5) { node, elapsed in
            guard let label = node as? SKLabelNode else { return }
            let progress = min(Double(elapsed) / 1.5, 1.0)
            let eased = 1 - pow(1 - progress, 3)
            label.text = "\(Int(Double(targetScore) * eased))"
        }
        scoreValue.run(countUp)

        // Divider line
        let divPath = CGMutablePath()
        divPath.move(to: CGPoint(x: -110, y: 0))
        divPath.addLine(to: CGPoint(x: 110, y: 0))
        let divider = SKShapeNode(path: divPath)
        divider.strokeColor = Colors.colorFromRGB(rgbvalue: Colors.AccentCyan).withAlphaComponent(0.2)
        divider.lineWidth   = 1
        divider.position    = CGPoint(x: 0, y: curY)
        card.addChild(divider)
        curY -= rowSpacing * 0.7

        // Stars row
        let starsLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        starsLabel.text      = "STARS  ★ \(stars)"
        starsLabel.fontSize  = 16
        starsLabel.fontColor = Colors.colorFromRGB(rgbvalue: Colors.AccentYellow)
        starsLabel.horizontalAlignmentMode = .center
        starsLabel.position  = CGPoint(x: 0, y: curY)
        card.addChild(starsLabel)
        curY -= rowSpacing * 0.85

        // Best / new record row
        let bestLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        if isNewRecord {
            bestLabel.text      = "NEW RECORD! ★"
            bestLabel.fontColor = Colors.colorFromRGB(rgbvalue: Colors.AccentYellow)
        } else {
            bestLabel.text      = "BEST  \(GameSettings.shared.bestScore)"
            bestLabel.fontColor = UIColor.white.withAlphaComponent(0.6)
        }
        bestLabel.fontSize  = 16
        bestLabel.horizontalAlignmentMode = .center
        bestLabel.position  = CGPoint(x: 0, y: curY)
        card.addChild(bestLabel)
    }

    // MARK: - Buttons
    private func setupButtons() {
        let cx = kViewSize.width / 2

        // ── Retry button ──────────────────────────────────────────
        let retryW: CGFloat = 200, retryH: CGFloat = 54, retryR: CGFloat = 27
        let retryY = kViewSize.height * 0.28
        let retryRect2 = CGRect(x: -retryW / 2, y: -retryH / 2, width: retryW, height: retryH)

        let retryShape = SKShapeNode(rect: retryRect2, cornerRadius: retryR)
        retryShape.fillColor   = Colors.colorFromRGB(rgbvalue: Colors.AccentCyan).withAlphaComponent(0.15)
        retryShape.strokeColor = Colors.colorFromRGB(rgbvalue: Colors.AccentCyan)
        retryShape.lineWidth   = 1.5
        retryShape.zPosition   = CGFloat(GameLayer.Interface)
        retryShape.position    = CGPoint(x: cx, y: retryY)
        addChild(retryShape)
        retryButtonNode = retryShape

        let retryLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        retryLabel.text      = "PLAY AGAIN"
        retryLabel.fontSize  = 18
        retryLabel.fontColor = .white
        retryLabel.verticalAlignmentMode   = .center
        retryLabel.horizontalAlignmentMode = .center
        retryShape.addChild(retryLabel)

        // Pulse
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.03, duration: 0.9),
            SKAction.scale(to: 1.00, duration: 0.9)
        ])
        retryShape.run(SKAction.repeatForever(pulse))

        retryRect = CGRect(x: cx - retryW / 2, y: retryY - retryH / 2,
                           width: retryW, height: retryH)

        // ── Menu button ──────────────────────────────────────────
        let menuW: CGFloat = 140, menuH: CGFloat = 40, menuR: CGFloat = 20
        let menuY = kViewSize.height * 0.19
        let menuRect2 = CGRect(x: -menuW / 2, y: -menuH / 2, width: menuW, height: menuH)

        let menuShape = SKShapeNode(rect: menuRect2, cornerRadius: menuR)
        menuShape.fillColor   = UIColor.white.withAlphaComponent(0.07)
        menuShape.strokeColor = UIColor.white.withAlphaComponent(0.3)
        menuShape.lineWidth   = 1
        menuShape.zPosition   = CGFloat(GameLayer.Interface)
        menuShape.position    = CGPoint(x: cx, y: menuY)
        addChild(menuShape)
        menuButtonNode = menuShape

        let menuLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        menuLabel.text      = "MENU"
        menuLabel.fontSize  = 14
        menuLabel.fontColor = .white
        menuLabel.verticalAlignmentMode   = .center
        menuLabel.horizontalAlignmentMode = .center
        menuShape.addChild(menuLabel)

        menuRect = CGRect(x: cx - menuW / 2, y: menuY - menuH / 2,
                          width: menuW, height: menuH)

        // ── Share button ─────────────────────────────────────────
        let shareRadius: CGFloat = 20
        let shareX = kViewSize.width * 0.75
        let shareY = kViewSize.height * 0.28

        let shareShape = SKShapeNode(circleOfRadius: shareRadius)
        shareShape.fillColor   = Colors.colorFromRGB(rgbvalue: Colors.AccentCyan).withAlphaComponent(0.12)
        shareShape.strokeColor = Colors.colorFromRGB(rgbvalue: Colors.AccentCyan).withAlphaComponent(0.4)
        shareShape.lineWidth   = 1
        shareShape.zPosition   = CGFloat(GameLayer.Interface)
        shareShape.position    = CGPoint(x: shareX, y: shareY)
        addChild(shareShape)
        shareButtonNode = shareShape

        let shareLabel = SKLabelNode(text: "⬆️")
        shareLabel.fontSize  = 16
        shareLabel.verticalAlignmentMode   = .center
        shareLabel.horizontalAlignmentMode = .center
        shareShape.addChild(shareLabel)

        shareRect = CGRect(x: shareX - shareRadius, y: shareY - shareRadius,
                           width: shareRadius * 2, height: shareRadius * 2)
    }

    // MARK: - Author Label
    private func setupAuthorLabel() {
        let label = GameFonts.shared.createLabel(string: UIText.AuthorLabel,
                                                  labelType: GameFonts.LabelType.statusBar)
        label.horizontalAlignmentMode = .center
        label.alpha    = 0.4
        label.zPosition = CGFloat(GameLayer.Interface)
        label.position = CGPoint(x: kViewSize.width / 2, y: 28)
        addChild(label)
    }

    // MARK: - New Record Effect
    private func triggerNewRecordEffect() {
        let burstColors: [Int] = [Colors.AccentCyan, Colors.AccentMagenta, Colors.AccentYellow]
        let origin = CGPoint(x: kViewSize.width / 2, y: kViewSize.height * 0.72)

        for _ in 0..<20 {
            let dot = SKShapeNode(rectOf: CGSize(width: 4, height: 4))
            let colorHex = burstColors[Int.random(in: 0..<burstColors.count)]
            dot.fillColor   = Colors.colorFromRGB(rgbvalue: colorHex)
            dot.strokeColor = .clear
            dot.position    = origin
            dot.zPosition   = CGFloat(GameLayer.Interface) + 2
            addChild(dot)

            let angle    = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 60...180)
            let dest     = CGPoint(x: origin.x + cos(angle) * distance,
                                   y: origin.y + sin(angle) * distance)
            let duration = TimeInterval.random(in: 1.0...1.4)

            dot.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: dest, duration: duration),
                    SKAction.fadeOut(withDuration: duration),
                    SKAction.scale(to: 0.1, duration: duration)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        // "NEW RECORD!" label
        let rec = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        rec.text      = "NEW RECORD!"
        rec.fontSize  = 30
        rec.fontColor = Colors.colorFromRGB(rgbvalue: Colors.AccentYellow)
        rec.horizontalAlignmentMode = .center
        rec.zPosition = CGFloat(GameLayer.Interface) + 3
        rec.position  = CGPoint(x: kViewSize.width / 2, y: kViewSize.height * 0.63)
        rec.setScale(0)
        addChild(rec)
        newRecordLabel = rec

        rec.run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.18),
            SKAction.scale(to: 1.0, duration: 0.12),
            SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.05, duration: 0.8),
                SKAction.scale(to: 0.95, duration: 0.8)
            ]))
        ]))
    }

    // MARK: - Update
    override func update(_ currentTime: TimeInterval) {
        let rawDelta = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        let deltaTime = min(rawDelta, 1.0 / 30.0)

        parallaxBackground?.update(deltaTime: deltaTime, gameSpeed: Float(0.2))
        nebulae?.update(deltaTime: deltaTime)
    }

    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)

        if retryRect.contains(loc) {
            GameAudio.shared.playSoundEffect(.buttonTap)
            retryButtonNode?.run(SKAction.sequence([
                SKAction.scale(to: 0.92, duration: 0.08),
                SKAction.scale(to: 1.00, duration: 0.08),
                SKAction.wait(forDuration: 0.09)
            ]))
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.25),
                SKAction.run { [weak self] in
                    let scene = GameScene(size: kViewSize)
                    self?.view?.presentScene(scene,
                        transition: SKTransition.fade(with: .black, duration: 0.4))
                }
            ]))
        } else if menuRect.contains(loc) {
            GameAudio.shared.playSoundEffect(.buttonTap)
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.15),
                SKAction.run { [weak self] in
                    let scene = EnhancedMenuScene(size: kViewSize)
                    self?.view?.presentScene(scene,
                        transition: SKTransition.fade(with: .black, duration: 0.4))
                }
            ]))
        } else if shareRect.contains(loc) {
            shareScore()
        }
    }

    // MARK: - Share
    private func shareScore() {
        let text = "I scored \(score) in SpaceRunner! Can you beat it? 🚀"
        let vc   = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let rootVC = view?.window?.rootViewController {
            vc.popoverPresentationController?.sourceView = view
            rootVC.present(vc, animated: true)
        }
    }
}
