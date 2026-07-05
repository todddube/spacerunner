//
//  PowerUp.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  A collectible orb that grants the player a timed effect on contact.
//
//  TYPES
//  .shield  (cyan,   🛡️, 5s) — invulnerability; combined with dash → dash kill (+10)
//  .magnet  (yellow, 🔮, 8s) — stars pulled toward player at 180 pt/s
//  .slowMo  (teal,   ⏱️, 4s) — physicsWorld.speed = 0.4; player movement unaffected
//
//  Spawned by PowerUpController at tier-scaled intervals (18s down to 10s).
//  Falls at small-meteor speed. Physics body: Contact.PowerUp, contactTest: Contact.Player.
//

import Foundation
import SpriteKit

// MARK: - PowerUpType

enum PowerUpType: CaseIterable {
    case shield
    case magnet
    case slowMo

    var color: UIColor {
        switch self {
        case .shield:  return UIColor(red: 0.00, green: 0.898, blue: 1.00, alpha: 1.0) // cyan  #00E5FF
        case .magnet:  return UIColor(red: 1.00, green: 0.900, blue: 0.00, alpha: 1.0) // yellow
        case .slowMo:  return UIColor(red: 0.00, green: 1.000, blue: 0.80, alpha: 1.0) // teal  #00FFCC
        }
    }

    var icon: String {
        switch self {
        case .shield:  return "🛡️"
        case .magnet:  return "🔮"
        case .slowMo:  return "⏱️"
        }
    }

    var duration: TimeInterval {
        switch self {
        case .shield:  return 5.0
        case .magnet:  return 8.0
        case .slowMo:  return 4.0
        }
    }
}

// MARK: - PowerUp

class PowerUp: SKNode {

    let powerUpType: PowerUpType

    // MARK: - Init

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    init(type: PowerUpType) {
        self.powerUpType = type
        super.init()
        setupVisuals()
        setupPhysics()
    }

    // MARK: - Setup

    private func setupVisuals() {
        zPosition = GameLayer.PowerUp
        let color = powerUpType.color

        // Outer glow ring — additive blend for neon effect
        let outerRing = SKShapeNode(circleOfRadius: 28)
        outerRing.strokeColor = color
        outerRing.fillColor = .clear
        outerRing.lineWidth = 2.0
        outerRing.blendMode = .add
        outerRing.alpha = 0.6
        addChild(outerRing)

        // Inner fill circle
        let innerCircle = SKShapeNode(circleOfRadius: 20)
        innerCircle.fillColor = color.withAlphaComponent(0.15)
        innerCircle.strokeColor = color
        innerCircle.lineWidth = 1.5
        addChild(innerCircle)

        // Emoji icon label
        let icon = SKLabelNode(text: powerUpType.icon)
        icon.fontSize = 22
        icon.verticalAlignmentMode = .center
        icon.horizontalAlignmentMode = .center
        addChild(icon)

        // Pulse animation — scale + alpha, staggered start
        let waitOffset = TimeInterval.random(in: 0.0...0.6)
        let pulseScale = SKAction.sequence([
            SKAction.scale(to: 1.12, duration: 0.6),
            SKAction.scale(to: 1.00, duration: 0.6)
        ])
        let pulseAlpha = SKAction.sequence([
            SKAction.fadeAlpha(to: 1.0, duration: 0.6),
            SKAction.fadeAlpha(to: 0.8, duration: 0.6)
        ])
        let pulseGroup  = SKAction.group([pulseScale, pulseAlpha])
        let pulseLoop   = SKAction.repeatForever(pulseGroup)
        let waitAndPulse = SKAction.sequence([SKAction.wait(forDuration: waitOffset), pulseLoop])
        run(waitAndPulse, withKey: "pulse")
    }

    private func setupPhysics() {
        let body = SKPhysicsBody(circleOfRadius: 24)
        body.categoryBitMask    = Contact.PowerUp
        body.collisionBitMask   = 0
        body.contactTestBitMask = Contact.Player
        body.isDynamic          = false
        physicsBody = body
    }

    // MARK: - Update

    func update(delta: TimeInterval) {
        let fallSpeed: CGFloat = kDeviceTablet
            ? CGFloat(delta * 60 * 4)
            : CGFloat(delta * 60 * 2)
        position.y -= fallSpeed

        if position.y < -60 {
            removeFromParent()
        }
    }
}
