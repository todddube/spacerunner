//
//  Player+EnhancedEffects.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Extension on Player that adds a multi-layered engine-trail particle system
//  and hit-flash animation, without cluttering the core Player.swift file.
//
//  ENGINE TRAIL LAYERS (back-to-front, all parented to the Player node)
//  1. Outer green flame  — wide, low-opacity, z = -3
//  2. Yellow/orange core — medium, brighter, z = -2
//  3. Red hot centre     — narrow, intense, z = -1
//
//  RESPONSIBILITIES
//  - setupEnhancedEngineEffects() async — async load and attach all three
//      SKEmitterNode layers positioned relative to player size
//  - startEnhancedEngineEffects()       — resume particle emission after pause
//  - stopEnhancedEngineEffects()        — zero birth-rate on all emitter layers
//  - flashHit()                         — brief red colour-flash when player
//      takes meteor damage (invincibility feedback)
//

import SpriteKit

extension Player {
    
    func setupEnhancedEngineEffects() async {
        // Remove existing engine particles
        children.filter { $0 is SKEmitterNode }.forEach { $0.removeFromParent() }
        
        // Create layered engine effects
        await createMultiLayeredEngineTrail()
        
        // Add dynamic engine sound
        startEnhancedEngineSound()
    }
    
    private func createMultiLayeredEngineTrail() async {
        // Layer 1: Core flame (blue/white center)
        let coreFlame = GameParticles.sharedInstance.createParticle(particles: .engineFlameCore)
        coreFlame.position = CGPoint(x: 0, y: -size.height * 0.3)
        coreFlame.zPosition = -1
        coreFlame.particleColor = UIColor.white
        coreFlame.particleAlpha = 0.9
        coreFlame.particleScale = 0.4
        addChild(coreFlame)
        
        // Layer 2: Mid flame (yellow/orange)
        let midFlame = GameParticles.sharedInstance.createParticle(particles: .engineFlameOuter)
        midFlame.position = CGPoint(x: 0, y: -size.height * 0.35)
        midFlame.zPosition = -2
        midFlame.particleColor = Colors.colorFromRGB(rgbvalue: Colors.EngineYellow)
        midFlame.particleAlpha = 0.8
        midFlame.particleScale = 0.5
        addChild(midFlame)
        
        // Layer 3: Outer flame (red/orange)
        let outerFlame = GameParticles.sharedInstance.createParticle(particles: .engineRed)
        outerFlame.position = CGPoint(x: 0, y: -size.height * 0.4)
        outerFlame.zPosition = -3
        outerFlame.particleScale = 0.6
        addChild(outerFlame)
        
        // Layer 4: Exhaust trail
        let exhaustTrail = createExhaustTrail()
        exhaustTrail.position = CGPoint(x: 0, y: -size.height * 0.5)
        exhaustTrail.zPosition = -4
        addChild(exhaustTrail)
    }
    
    private func createExhaustTrail() -> SKEmitterNode {
        let trail = SKEmitterNode()
        
        trail.particleTexture = GameTextures.sharedInstance.textureWithName(name: SpriteName.Magic)
        trail.particleBirthRate = 30
        trail.particleLifetime = 2.0
        trail.particleLifetimeRange = 0.5
        
        trail.emissionAngle = DegressToRadians(degrees: 90)
        trail.emissionAngleRange = DegressToRadians(degrees: 10)
        trail.particleSpeed = -120
        trail.particleSpeedRange = 30
        
        trail.particleScale = 0.3
        trail.particleScaleRange = 0.1
        trail.particleScaleSpeed = -0.2
        trail.particleAlpha = 0.6
        trail.particleAlphaSpeed = -0.4
        
        trail.particleColor = Colors.colorFromRGB(rgbvalue: Colors.EngineGreen)
        trail.particleColorBlendFactor = 0.8
        
        return trail
    }
    
    func startEnhancedEngineEffects() {
        children.compactMap { $0 as? SKEmitterNode }.forEach { emitter in
            emitter.isPaused = false
            
            // Add dynamic intensity based on movement
            let intensityAction = SKAction.customAction(withDuration: .infinity) { [weak self] node, _ in
                guard let self = self, let emitter = node as? SKEmitterNode else { return }
                
                // Adjust particle intensity based on movement speed
                let currentSpeed = self.calculateMovementSpeed()
                let intensityMultiplier = 0.5 + (currentSpeed / 200.0) // Scale with movement
                
                emitter.particleBirthRate = emitter.particleBirthRate * CGFloat(intensityMultiplier)
                emitter.particleSpeed = emitter.particleSpeed * CGFloat(intensityMultiplier)
            }
            
            emitter.run(intensityAction, withKey: "dynamicIntensity")
        }
    }
    
    func stopEnhancedEngineEffects() {
        children.compactMap { $0 as? SKEmitterNode }.forEach { emitter in
            emitter.removeAction(forKey: "dynamicIntensity")
            emitter.isPaused = true
        }
    }
    
    private func calculateMovementSpeed() -> CGFloat {
        // Calculate approximate movement speed based on position changes
        // This would need to track previous position and time delta
        return 100.0 // Placeholder - implement actual speed calculation
    }
    
    private func startEnhancedEngineSound() {
        // Engine sound effects could be added here when available
        // For now, we'll skip the engine sound
    }
    
    func createBoostEffect() {
        // Visual boost effect
        let boostFlash = SKSpriteNode(color: .cyan, size: CGSize(width: size.width * 2, height: size.height * 2))
        boostFlash.alpha = 0.0
        boostFlash.blendMode = .add
        addChild(boostFlash)
        
        let flash = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.8, duration: 0.1),
            SKAction.fadeAlpha(to: 0.0, duration: 0.3),
            SKAction.removeFromParent()
        ])
        boostFlash.run(flash)
        
        // Enhance engine particles temporarily
        children.compactMap { $0 as? SKEmitterNode }.forEach { emitter in
            let originalBirthRate = emitter.particleBirthRate
            let boostBirthRate = originalBirthRate * 2.0
            
            emitter.particleBirthRate = boostBirthRate
            
            let restore = SKAction.run {
                emitter.particleBirthRate = originalBirthRate
            }
            emitter.run(SKAction.sequence([SKAction.wait(forDuration: 1.0), restore]))
        }
    }
    
    func createShieldEffect() {
        guard immune else { return }
        
        // Create shield visual
        let shield = SKShapeNode(circleOfRadius: size.width)
        shield.strokeColor = .cyan
        shield.fillColor = UIColor.cyan.withAlphaComponent(0.1)
        shield.lineWidth = 3
        shield.alpha = 0.8
        shield.blendMode = .add
        addChild(shield)
        
        // Shield animation
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.5),
            SKAction.scale(to: 0.9, duration: 0.5)
        ])
        shield.run(SKAction.repeatForever(pulse))
        
        // Shield particles
        let shieldParticles = createShieldParticles()
        addChild(shieldParticles)
        
        // Remove shield effect when immunity ends
        let waitForImmunity = SKAction.wait(forDuration: 3.0)
        let removeShield = SKAction.run {
            shield.removeFromParent()
            shieldParticles.removeFromParent()
        }
        run(SKAction.sequence([waitForImmunity, removeShield]))
    }
    
    private func createShieldParticles() -> SKEmitterNode {
        let particles = SKEmitterNode()
        
        particles.particleTexture = GameTextures.sharedInstance.textureWithName(name: SpriteName.Magic)
        particles.particleBirthRate = 20
        particles.particleLifetime = 1.5
        particles.particleLifetimeRange = 0.5
        
        particles.emissionAngle = 0
        particles.emissionAngleRange = CGFloat.pi * 2
        particles.particleSpeed = 40
        particles.particleSpeedRange = 20
        
        particles.particleScale = 0.2
        particles.particleAlpha = 0.6
        particles.particleColor = .cyan
        particles.particleColorBlendFactor = 1.0
        
        // Orbit around player
        particles.particlePositionRange = CGVector(dx: size.width * 1.5, dy: size.height * 1.5)
        
        return particles
    }
}