//
//  GameParticles.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Factory and configuration layer for all SKEmitterNode particle effects.
//  Centralises particle tuning so visual artists can adjust effects in one
//  place without touching scene or game-object files.
//
//  CONTENTS
//  - engineTrailOuter / engineTrailCore / engineTrailInner — three-layer
//      player engine flame effects with distinct colours and intensities
//  - explosion(at:)         — meteor hit burst (ExplosionParticle.sks)
//  - starPickup(at:)        — star collection sparkle (StarParticle.sks)
//  - backgroundStarfield()  — ambient deep-space particle field
//  - Each factory method configures birth rate, lifetime, speed, and scale
//      relative to kViewSize for device-adaptive appearance
//

import Foundation
import SpriteKit

@MainActor let GameParticlesSharedInstance = GameParticles()

@MainActor
class GameParticles {
    
    class var sharedInstance:GameParticles{
        return GameParticlesSharedInstance
    }
    
    // MARK: - Public class enum
    internal enum Particles:Int {
        case magic
        case engineGreen
        case engineYellow
        case engineRed
        case engineFlameCore
        case engineFlameOuter
        case player
    }
    
    // MARK: - Private class properties
    fileprivate var magicParticles = SKEmitterNode()
    fileprivate var engineParticlesGreen = SKEmitterNode()
    fileprivate var engineParticlesYellow = SKEmitterNode()
    fileprivate var engineParticlesRed = SKEmitterNode()
    fileprivate var engineFlameCore = SKEmitterNode()
    fileprivate var engineFlameOuter = SKEmitterNode()
    fileprivate var playerParticles = SKEmitterNode()
    
    // MARK: - Init
    init() {
        self.setupMagicParticles()
        self.setupEngineParticles()
        self.setupRocketFlameParticles()
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
    
    // MARK: - RocketFlameParticles
    fileprivate func setupRocketFlameParticles() {
        // Setup Red Engine Particles (Hottest part of flame)
        self.engineParticlesRed.particleBirthRate = 35.0
        self.engineParticlesRed.particleLifetime = 0.2
        self.engineParticlesRed.particleLifetimeRange = 0.1
        self.engineParticlesRed.particlePositionRange = CGVector(dx: 2, dy: 0)
        self.engineParticlesRed.emissionAngle = DegressToRadians(degrees: 90)
        self.engineParticlesRed.emissionAngleRange = DegressToRadians(degrees: 3.0)
        self.engineParticlesRed.particleSpeed = -120.0
        self.engineParticlesRed.particleSpeedRange = 20.0
        self.engineParticlesRed.particleScale = kDeviceTablet ? 0.6 : 0.2
        self.engineParticlesRed.particleScaleRange = 0.1
        self.engineParticlesRed.particleColorBlendFactor = 1.0
        self.engineParticlesRed.particleColor = Colors.colorFromRGB(rgbvalue: Colors.EngineRed)
        self.engineParticlesRed.particleTexture = GameTextures.sharedInstance.textureWithName(name: SpriteName.Magic)
        
        // Setup Flame Core (Bright yellow/orange center)
        self.engineFlameCore.particleBirthRate = 45.0
        self.engineFlameCore.particleLifetime = 0.3
        self.engineFlameCore.particleLifetimeRange = 0.15
        self.engineFlameCore.particlePositionRange = CGVector(dx: 4, dy: 0)
        self.engineFlameCore.emissionAngle = DegressToRadians(degrees: 90)
        self.engineFlameCore.emissionAngleRange = DegressToRadians(degrees: 8.0)
        self.engineFlameCore.particleSpeed = -100.0
        self.engineFlameCore.particleSpeedRange = 30.0
        self.engineFlameCore.particleScale = kDeviceTablet ? 0.8 : 0.3
        self.engineFlameCore.particleScaleRange = 0.2
        self.engineFlameCore.particleScaleSpeed = -0.5
        self.engineFlameCore.particleColorBlendFactor = 1.0
        self.engineFlameCore.particleColor = Colors.colorFromRGB(rgbvalue: Colors.EngineYellow)
        self.engineFlameCore.particleAlpha = 0.9
        self.engineFlameCore.particleAlphaSpeed = -2.5
        self.engineFlameCore.particleTexture = GameTextures.sharedInstance.textureWithName(name: SpriteName.Magic)
        
        // Setup Flame Outer (Green outer edge for cooler flame)
        self.engineFlameOuter.particleBirthRate = 25.0
        self.engineFlameOuter.particleLifetime = 0.4
        self.engineFlameOuter.particleLifetimeRange = 0.2
        self.engineFlameOuter.particlePositionRange = CGVector(dx: 6, dy: 0)
        self.engineFlameOuter.emissionAngle = DegressToRadians(degrees: 90)
        self.engineFlameOuter.emissionAngleRange = DegressToRadians(degrees: 12.0)
        self.engineFlameOuter.particleSpeed = -80.0
        self.engineFlameOuter.particleSpeedRange = 40.0
        self.engineFlameOuter.particleScale = kDeviceTablet ? 1.0 : 0.4
        self.engineFlameOuter.particleScaleRange = 0.3
        self.engineFlameOuter.particleScaleSpeed = -0.3
        self.engineFlameOuter.particleColorBlendFactor = 1.0
        self.engineFlameOuter.particleColor = Colors.colorFromRGB(rgbvalue: Colors.EngineGreen)
        self.engineFlameOuter.particleAlpha = 0.7
        self.engineFlameOuter.particleAlphaSpeed = -1.5
        self.engineFlameOuter.particleTexture = GameTextures.sharedInstance.textureWithName(name: SpriteName.Magic)
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
            case Particles.engineRed:
                return self.engineParticlesRed.copy() as! SKEmitterNode
            case Particles.engineFlameCore:
                return self.engineFlameCore.copy() as! SKEmitterNode
            case Particles.engineFlameOuter:
                return self.engineFlameOuter.copy() as! SKEmitterNode
            case Particles.player:
                return self.playerParticles.copy() as! SKEmitterNode
        }
    }
}
