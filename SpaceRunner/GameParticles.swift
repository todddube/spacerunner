//
//  GameParticles.swift
//  SpaceRunner
//
//  Created by Todd Dube : 2025
//  Purpose: Particle effect system for engine trails, explosions, and background visual effects.
//

import Foundation
import SpriteKit

let GameParticlesSharedInstance = GameParticles()

class GameParticles {
    
    class var sharedInstance:GameParticles{
        return GameParticlesSharedInstance
    }
    
    // MARK: - Public class enum
    internal enum Particles:Int {
        case magic
        case engineGreen
        case engineYellow
        case player
    }
    
    // MARK: - Private class properties
    fileprivate var magicParticles = SKEmitterNode()
    fileprivate var engineParticlesGreen = SKEmitterNode()
    fileprivate var engineParticlesYellow = SKEmitterNode()
    fileprivate var playerParticles = SKEmitterNode()
    
    // MARK: - Init
    init() {
        self.setupMagicParticles()
        self.setupEngineParticles()
        self.setupPlayerParticles()
    }
    
    // MARK: - Setup
    fileprivate func setupMagicParticles() {
        
        // Birthrate and Lifetime
        self.magicParticles.particleBirthRate = 50.0
        self.magicParticles.particleLifetime = 8.0
        self.magicParticles.particleLifetimeRange = 2.25
    
        
        
        // Position Range
        self.magicParticles.particlePositionRange = CGVector(dx: kViewSize.width * 2, dy: kViewSize.height * 2)
        
        // Speed
        self.magicParticles.particleSpeed = -200.0
        self.magicParticles.particleSpeedRange = self.magicParticles.particleSpeed / 4
        
        // Emission Angle
        self.magicParticles.emissionAngle = DegressToRadians(degrees: 90.0)
        self.magicParticles.emissionAngleRange = DegressToRadians(degrees: 15)
        
        // Alpha
        self.magicParticles.particleAlpha = 0.5
        self.magicParticles.particleAlphaRange = 0.25
        self.magicParticles.particleAlphaSpeed = -0.125
        
        // Color blending
        self.magicParticles.particleColorBlendFactor = 0.5
        self.magicParticles.particleColorBlendFactorRange = 0.25
        
        // Color
        self.magicParticles.particleColor = Colors.colorFromRGB(rgbvalue: Colors.Magic)
        
        // Texture
        self.magicParticles.particleTexture = GameTextures.sharedInstance.textureWithName(name: SpriteName.Magic)
    }
    
    
    // MARK: - PlayerParticles
    fileprivate func setupPlayerParticles() {
        // Setup player explosion particles
        self.playerParticles.particleBirthRate = 45.0
        self.playerParticles.particleLifetimeRange = 2.5
        self.playerParticles.particlePositionRange = CGVector(dx: 0, dy: 0)
        self.playerParticles.emissionAngle = DegressToRadians(degrees: 55)
        self.playerParticles.emissionAngleRange = DegressToRadians(degrees: 25.0)
        self.playerParticles.particleSpeed = -80.0
        self.playerParticles.particleScale = kDeviceTablet ? 1.0 : 0.50
        self.playerParticles.particleColorBlendFactor = 0.0
        self.playerParticles.particleColor = Colors.colorFromRGB(rgbvalue: Colors.EngineYellow)
        self.playerParticles.particleTexture = GameTextures.sharedInstance.textureWithName(name: SpriteName.Magic)
        
    }
    
    
    // MARK: - EngineParticles
    fileprivate func setupEngineParticles() {
        // Setup Green Particles First
        // Birthrate and Lifetime
        self.engineParticlesGreen.particleBirthRate = 25.0
        self.engineParticlesGreen.particleLifetime = 0.25
        
        // Position Range
        self.engineParticlesGreen.particlePositionRange = CGVector(dx: 0, dy: 0)
        
        // Angle
        self.engineParticlesGreen.emissionAngle = DegressToRadians(degrees: 88)
        self.engineParticlesGreen.emissionAngleRange = DegressToRadians(degrees: 5.0)
        
        // Speed
        self.engineParticlesGreen.particleSpeed = -80.0
        
        // Scale
        self.engineParticlesGreen.particleScale = kDeviceTablet ? 0.75 : 0.25
        
        // Color Blending
        self.engineParticlesGreen.particleColorBlendFactor = 1.0
        
        // Color
        self.engineParticlesGreen.particleColor = Colors.colorFromRGB(rgbvalue: Colors.EngineGreen)
        
        // Texture
        self.engineParticlesGreen.particleTexture = GameTextures.sharedInstance.textureWithName(name: SpriteName.Magic)
        
        // Setup Yellow Particles
        // Birthrate and Lifetime
        self.engineParticlesYellow.particleBirthRate = 15.0
        self.engineParticlesYellow.particleLifetime = 0.25
        
        // Position Range
        self.engineParticlesYellow.particlePositionRange = CGVector(dx: 0, dy: 0)
        
        // Angle
        self.engineParticlesYellow.emissionAngle = DegressToRadians(degrees: 92)
        self.engineParticlesYellow.emissionAngleRange = DegressToRadians(degrees: 5.0)
        
        // Speed
        self.engineParticlesYellow.particleSpeed = -80.0
        
        // Scale
        self.engineParticlesYellow.particleScale = kDeviceTablet ? 0.75 : 0.25
        
        // Color Blending
        self.engineParticlesYellow.particleColorBlendFactor = 1.0
        
        // Color
        self.engineParticlesYellow.particleColor = Colors.colorFromRGB(rgbvalue: Colors.EngineYellow)
        
        // Texture
        self.engineParticlesYellow.particleTexture = GameTextures.sharedInstance.textureWithName(name: SpriteName.Magic)
        
    }
    
    // MARK: - Public Functions
    func createParticle(particles:Particles) -> SKEmitterNode {
        switch particles {
            case Particles.magic:
                return self.magicParticles.copy() as! SKEmitterNode
            case Particles.engineGreen:
                return self.engineParticlesGreen.copy() as! SKEmitterNode
            case Particles.engineYellow:
                return self.engineParticlesYellow.copy() as! SKEmitterNode
            case Particles.player:
                return self.playerParticles.copy() as! SKEmitterNode
        }
    }
}
