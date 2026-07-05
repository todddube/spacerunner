//
//  LaserBeam.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Full-screen-width horizontal laser obstacle. Spawned by MeteorController at tier 3+.
//  Progresses through three phases:
//   1. Telegraph (1.2 s) — flickering, no collision — player can dodge
//   2. Active    (0.6 s) — solid, lethal (contactTestBitMask = Player)
//   3. Fading    (0.3 s) — fades out, collision removed
//  Scrolls downward more slowly than meteors (0.8× base speed).
//

import Foundation
import SpriteKit

class LaserBeam: SKNode {

    // MARK: - Phase

    private enum LaserPhase { case telegraph, active, fading, done }

    // MARK: - Visuals

    private let beamSprite: SKSpriteNode
    private let glowSprite: SKSpriteNode

    // MARK: - State

    private var phase: LaserPhase    = .telegraph
    private var phaseTimer: TimeInterval = 0

    // MARK: - Init

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override init() {
        let beamWidth  = kViewSize.width
        let beamColor  = UIColor(red: 0.00, green: 0.898, blue: 1.00, alpha: 1.0) // AccentCyan

        beamSprite = SKSpriteNode(color: beamColor, size: CGSize(width: beamWidth, height: 6))
        glowSprite = SKSpriteNode(color: beamColor, size: CGSize(width: beamWidth, height: 16))

        super.init()

        // Glow layer — additive blend, behind the beam
        glowSprite.alpha     = 0.10
        glowSprite.blendMode = .add
        glowSprite.zPosition = -1
        addChild(glowSprite)
        addChild(beamSprite)

        zPosition = GameLayer.Meteor

        // Position above screen; caller can override before adding to scene
        let spawnBand: CGFloat = kViewSize.height * 0.3 // 1.1 … 1.4 × height
        position.y = kViewSize.height * 1.1 + RandomFloatRange(min: 0, max: spawnBand)
        position.x = kViewSize.width * 0.5

        startTelegraphAnimation()
    }

    // MARK: - Phase transitions

    private func startTelegraphAnimation() {
        beamSprite.alpha = 0.15
        let flicker = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.6, duration: 0.06),
            SKAction.fadeAlpha(to: 0.15, duration: 0.06)
        ])
        beamSprite.run(SKAction.repeatForever(flicker), withKey: "flicker")
    }

    private func enterActivePhase() {
        beamSprite.removeAction(forKey: "flicker")
        beamSprite.alpha = 1.0
        glowSprite.alpha = 0.30

        // Activate lethal physics body
        let body = SKPhysicsBody(rectangleOf: CGSize(width: kViewSize.width - 20, height: 6))
        body.categoryBitMask    = Contact.Meteor   // reuses Meteor category per spec
        body.collisionBitMask   = 0
        body.contactTestBitMask = Contact.Player
        body.isDynamic          = false
        physicsBody = body
    }

    private func enterFadingPhase() {
        // Disarm collision before visual fade
        physicsBody?.contactTestBitMask = 0
        run(SKAction.fadeOut(withDuration: 0.3))
    }

    // MARK: - Update (called by MeteorController each frame)

    func update(delta: TimeInterval) {
        // Scroll slower than meteors
        let fallSpeed: CGFloat = CGFloat(delta * 60 * 0.8)
        position.y -= fallSpeed

        if position.y < -50 {
            removeFromParent()
            return
        }

        phaseTimer += delta

        switch phase {
        case .telegraph:
            if phaseTimer >= 1.2 {
                phase = .active
                phaseTimer = 0
                enterActivePhase()
            }

        case .active:
            if phaseTimer >= 0.6 {
                phase = .fading
                phaseTimer = 0
                enterFadingPhase()
            }

        case .fading:
            if phaseTimer >= 0.3 {
                phase = .done
                physicsBody = nil
            }

        case .done:
            break
        }
    }
}
