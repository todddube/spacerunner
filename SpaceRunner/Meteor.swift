//
//  Meteor.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  A single meteor obstacle that falls down the screen with neon glow, rotation,
//  and a trailing particle emitter. Four size variants (Huge, Large, Medium, Small)
//  are randomly selected by MeteorController. Each size has a distinct neon glow
//  color for clear visual identity. Circular physics bodies drive collision detection.
//
//  RESPONSIBILITIES
//  - init(type:)        — load texture variant, add glow halo, rotation, particle trail
//  - update(delta:)     — advance vertical position; remove when off-screen
//  - hitMeteor()        — play explosion sound, remove from parent
//  - gameOver()         — apply grayscale shader
//

import Foundation
import SpriteKit

class Meteor: SKSpriteNode {

    // MARK: - Types

    internal enum MeteorType: Int {
        case huge
        case large
        case medium
        case small
    }

    // MARK: - Properties

    internal var drift: CGFloat = 0
    private(set) var meteorType: MeteorType = .medium

    // Rotation speed in radians/sec — varied per size for visual interest
    private static let rotationSpeeds: [MeteorType: CGFloat] = [
        .huge:   0.3,
        .large:  0.7,
        .medium: 1.2,
        .small:  2.0
    ]

    // Neon glow colors per type — additive halo sprite for dark-background glow
    private static let glowColors: [MeteorType: UIColor] = [
        .huge:   UIColor(red: 1.0, green: 0.55, blue: 0.0,  alpha: 1.0), // orange
        .large:  UIColor(red: 0.0, green: 0.90, blue: 1.0,  alpha: 1.0), // cyan
        .medium: UIColor(red: 1.0, green: 0.0,  blue: 0.90, alpha: 1.0), // magenta
        .small:  UIColor(red: 1.0, green: 0.90, blue: 0.0,  alpha: 1.0), // yellow
    ]

    // MARK: - Init

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }

    convenience init(type: MeteorType) {
        let textureName: String
        switch type {
        case .huge:   textureName = SpriteName.MeteorHuge
        case .large:  textureName = SpriteName.MeteorLarge
        case .medium: textureName = SpriteName.MeteorMedium
        case .small:  textureName = SpriteName.MeteorSmall
        }
        let texture = GameTextures.sharedInstance.textureWithName(name: textureName)
        self.init(texture: texture, color: .white, size: texture.size())
        self.meteorType = type
        self.setupMeteor()
        self.setupMeteorPhysics()
    }

    // MARK: - Setup

    private func setupMeteor() {
        zPosition = GameLayer.Meteor

        // Neon glow halo — same texture, scaled 1.35x, additive blend, colored
        addGlowHalo()

        // Continuous spin at type-appropriate speed
        let rotSpeed = Meteor.rotationSpeeds[meteorType] ?? 1.0
        let rotDir: CGFloat = Bool.random() ? 1.0 : -1.0
        let fullRotation = SKAction.rotate(byAngle: rotDir * .pi * 2, duration: Double((.pi * 2) / rotSpeed))
        run(SKAction.repeatForever(fullRotation), withKey: "rotation")

        // Small trailing particle emitter
        addTrailParticles()
    }

    private func addGlowHalo() {
        guard let tex = texture, let glowColor = Meteor.glowColors[meteorType] else { return }

        let halo = SKSpriteNode(texture: tex, color: glowColor, size: size * 1.35)
        halo.colorBlendFactor = 1.0
        halo.blendMode = .add
        halo.alpha = 0.55
        halo.zPosition = -1

        // Pulse the glow slightly
        let glowPulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.75, duration: 0.6),
            SKAction.fadeAlpha(to: 0.35, duration: 0.6)
        ])
        halo.run(SKAction.repeatForever(glowPulse))
        addChild(halo)
    }

    private func addTrailParticles() {
        guard let glowColor = Meteor.glowColors[meteorType] else { return }

        let trail = SKEmitterNode()
        trail.particleTexture    = GameTextures.sharedInstance.textureWithName(name: SpriteName.Magic)
        trail.particleBirthRate  = 18
        trail.particleLifetime   = 0.6
        trail.particleLifetimeRange = 0.2
        trail.particleSpeed      = 20
        trail.particleSpeedRange = 10
        trail.emissionAngle      = .pi / 2  // upward (opposite to fall direction)
        trail.emissionAngleRange = 0.4
        trail.particleScale      = 0.2
        trail.particleScaleSpeed = -0.3
        trail.particleAlpha      = 0.7
        trail.particleAlphaSpeed = -1.2
        trail.particleColor             = glowColor
        trail.particleColorBlendFactor  = 1.0
        trail.zPosition                 = -2
        trail.position           = .zero
        addChild(trail)
    }

    private func setupMeteorPhysics() {
        physicsBody = SKPhysicsBody(circleOfRadius: size.width / 2, center: anchorPoint)
        physicsBody?.categoryBitMask    = Contact.Meteor
        physicsBody?.collisionBitMask   = 0x0
        physicsBody?.contactTestBitMask = 0x0
    }

    // MARK: - Update

    func update(delta: TimeInterval) {
        let fallSpeed: CGFloat = kDeviceTablet ? CGFloat(delta * 60 * 4) : CGFloat(delta * 60 * 2)
        position.y -= fallSpeed
        position.x += drift

        if position.y < -size.height ||
           position.x < -size.width ||
           position.x > kViewSize.width + size.width {
            removeFromParent()
        }
    }

    // MARK: - Actions

    func hitMeteor() {
        GameAudio.shared.playSoundEffect(.explosion)
        run(SKAction.wait(forDuration: 0.1)) {
            self.removeFromParent()
        }
    }

    func gameOver() {
        GameShaders.sharedInstance.shadeGray(node: self)
    }
}

// Convenience operator for CGSize scaling
private func * (size: CGSize, scale: CGFloat) -> CGSize {
    CGSize(width: size.width * scale, height: size.height * scale)
}
