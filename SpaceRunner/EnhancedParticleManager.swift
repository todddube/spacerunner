//
//  EnhancedParticleManager.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  High-quality particle effects layer that supplements the basic GameParticles
//  system. Builds multi-phase explosions (flash → expanding ring → debris cloud)
//  and physics-driven debris fragments to maximise collision impact.
//
//  EFFECTS
//  - createExplosion(at:intensity:)  — tiered blast: flash + shockwave ring +
//      debris particles; intensity scales brightness and particle count
//  - createStarBurst(at:)            — golden sparkle burst for star pickups
//  - createEngineTrail(for:)         — dynamic engine glow updated each frame
//  - update(deltaTime:)              — advance any time-driven effect state
//  - setupForScene(_:)               — store scene reference for node insertion
//
//  REQUIRES @MainActor — particle node mutations must occur on the main thread
//

import SpriteKit

@MainActor
class EnhancedParticleManager: SKNode {
    
    enum ExplosionIntensity {
        case low, medium, high, extreme
        
        var particleCount: Int {
            switch self {
            case .low: return 20
            case .medium: return 40
            case .high: return 60
            case .extreme: return 100
            }
        }
        
        var lifetime: Double {
            switch self {
            case .low: return 1.0
            case .medium: return 1.5
            case .high: return 2.0
            case .extreme: return 2.5
            }
        }
    }
    
    private weak var parentScene: SKScene?

    func setupForScene(_ scene: SKScene) {
        self.parentScene = scene
    }
    
    func update(deltaTime: TimeInterval) {
        // Clean up old particle systems
        cleanupCompletedEffects()
    }
    
    private func cleanupCompletedEffects() {
        children.forEach { node in
            if let emitter = node as? SKEmitterNode {
                if emitter.particleBirthRate == 0 && emitter.numParticlesToEmit == 0 {
                    // Remove emitter after all particles have died
                    let wait = SKAction.wait(forDuration: Double(emitter.particleLifetime))
                    let remove = SKAction.removeFromParent()
                    emitter.run(SKAction.sequence([wait, remove]))
                }
            }
        }
    }
    
    func createExplosion(at position: CGPoint, intensity: ExplosionIntensity) -> SKEmitterNode {
        let explosion = SKEmitterNode()
        
        // Basic properties
        explosion.position = position
        explosion.particleTexture = GameTextures.sharedInstance.textureWithName(name: SpriteName.Magic)
        explosion.particleBirthRate = CGFloat(intensity.particleCount * 20)
        explosion.numParticlesToEmit = intensity.particleCount
        explosion.particleLifetime = CGFloat(intensity.lifetime)
        explosion.particleLifetimeRange = CGFloat(intensity.lifetime * 0.5)
        
        // Emission properties
        explosion.emissionAngle = 0
        explosion.emissionAngleRange = CGFloat.pi * 2
        explosion.particleSpeed = 150
        explosion.particleSpeedRange = 100
        
        // Visual properties
        explosion.particleScale = 0.5
        explosion.particleScaleRange = 0.3
        explosion.particleScaleSpeed = -0.8
        explosion.particleAlpha = 0.9
        explosion.particleAlphaSpeed = -1.0
        
        // Color animation
        explosion.particleColorSequence = createExplosionColorSequence()
        explosion.particleColorBlendFactor = 1.0
        
        // Physics
        explosion.xAcceleration = 0
        explosion.yAcceleration = -50
        explosion.particleSpeedRange = 50
        
        return explosion
    }
    
    private func createExplosionColorSequence() -> SKKeyframeSequence? {
        // Vibrant arcade palette: white core → cyan → magenta → yellow → clear
        let colors = [
            UIColor.white,
            UIColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 1.0),  // cyan
            UIColor(red: 1.0, green: 0.0, blue: 0.9, alpha: 1.0),  // magenta
            UIColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 1.0),  // yellow-gold
            UIColor.clear
        ]
        let times = [0.0, 0.15, 0.40, 0.70, 1.0]
        return SKKeyframeSequence(keyframeValues: colors, times: times as [NSNumber])
    }
    
    func createDebris(at position: CGPoint, velocity: CGVector) -> SKEmitterNode {
        let debris = SKEmitterNode()
        
        debris.position = position
        debris.particleTexture = GameTextures.sharedInstance.textureWithName(name: SpriteName.Magic)
        debris.particleBirthRate = 15
        debris.numParticlesToEmit = 10
        debris.particleLifetime = 3.0
        debris.particleLifetimeRange = 1.0
        
        debris.emissionAngle = atan2(velocity.dy, velocity.dx)
        debris.emissionAngleRange = CGFloat.pi / 4
        debris.particleSpeed = 80
        debris.particleSpeedRange = 40
        
        debris.particleScale = 0.3
        debris.particleScaleRange = 0.2
        debris.particleAlpha = 0.8
        debris.particleAlphaSpeed = -0.3
        
        debris.particleColor = UIColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1.0) // neon orange debris
        debris.particleColorBlendFactor = 0.9
        
        debris.xAcceleration = 0
        debris.yAcceleration = -100
        
        return debris
    }
    
    func createSparkles(at position: CGPoint) -> SKEmitterNode {
        let sparkles = SKEmitterNode()
        
        sparkles.position = position
        sparkles.particleTexture = GameTextures.sharedInstance.textureWithName(name: SpriteName.Magic)
        sparkles.particleBirthRate = 50
        sparkles.numParticlesToEmit = 20
        sparkles.particleLifetime = 1.5
        sparkles.particleLifetimeRange = 0.5
        
        sparkles.emissionAngle = 0
        sparkles.emissionAngleRange = CGFloat.pi * 2
        sparkles.particleSpeed = 60
        sparkles.particleSpeedRange = 30
        
        sparkles.particleScale = 0.2
        sparkles.particleScaleRange = 0.1
        sparkles.particleScaleSpeed = -0.2
        sparkles.particleAlpha = 1.0
        sparkles.particleAlphaSpeed = -0.8
        
        sparkles.particleColor = UIColor.yellow
        sparkles.particleColorBlendFactor = 1.0
        
        // Add twinkling effect
        sparkles.particleColorSequence = createSparkleColorSequence()
        
        return sparkles
    }
    
    private func createSparkleColorSequence() -> SKKeyframeSequence? {
        let colors = [
            UIColor.white,
            UIColor.yellow,
            UIColor.white,
            UIColor.cyan,
            UIColor.clear
        ]
        
        let times = [0.0, 0.25, 0.5, 0.75, 1.0]
        
        return SKKeyframeSequence(keyframeValues: colors, times: times as [NSNumber])
    }
    
    func createStarBurst(at position: CGPoint) -> SKEmitterNode {
        let burst = SKEmitterNode()
        
        burst.position = position
        burst.particleTexture = GameTextures.sharedInstance.textureWithName(name: SpriteName.Star)
        burst.particleBirthRate = 30
        burst.numParticlesToEmit = 8
        burst.particleLifetime = 2.0
        burst.particleLifetimeRange = 0.5
        
        burst.emissionAngle = 0
        burst.emissionAngleRange = CGFloat.pi * 2
        burst.particleSpeed = 100
        burst.particleSpeedRange = 50
        
        burst.particleScale = 0.3
        burst.particleScaleRange = 0.2
        burst.particleScaleSpeed = -0.1
        burst.particleAlpha = 1.0
        burst.particleAlphaSpeed = -0.6
        
        burst.particleColor = UIColor.yellow
        burst.particleColorBlendFactor = 1.0
        
        burst.xAcceleration = 0
        burst.yAcceleration = 50
        
        // Add rotation
        burst.particleRotation = 0
        burst.particleRotationRange = CGFloat.pi * 2
        burst.particleRotationSpeed = CGFloat.pi
        
        return burst
    }
    
    func createTrailEffect(at position: CGPoint, direction: CGVector) -> SKEmitterNode {
        let trail = SKEmitterNode()
        
        trail.position = position
        trail.particleTexture = GameTextures.sharedInstance.textureWithName(name: SpriteName.Magic)
        trail.particleBirthRate = 25
        trail.particleLifetime = 1.0
        trail.particleLifetimeRange = 0.3
        
        let angle = atan2(direction.dy, direction.dx)
        trail.emissionAngle = angle + CGFloat.pi // Opposite direction
        trail.emissionAngleRange = CGFloat.pi / 6
        trail.particleSpeed = 30
        trail.particleSpeedRange = 15
        
        trail.particleScale = 0.4
        trail.particleScaleSpeed = -0.5
        trail.particleAlpha = 0.6
        trail.particleAlphaSpeed = -0.8
        
        trail.particleColor = UIColor.cyan
        trail.particleColorBlendFactor = 0.8
        
        return trail
    }
}