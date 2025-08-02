//
//  Star.swift
//  SpaceRunner
//
//  Created by Todd Dube : 2025
//  Purpose: Collectible star sprites that provide points and bonuses when collected by the player.
//

import Foundation
import SpriteKit

class Star: SKSpriteNode {
    // MARK: - Public Class properties
    internal var drift = CGFloat()
    
    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    convenience init() {
        let texture = GameTextures.sharedInstance.textureWithName(name: SpriteName.Star)
        self.init(texture: texture, color: SKColor.white, size: texture.size())
        
        self.setupStar()
        self.setupStarPhysics()
    }
    
    // MARK: - Setup
    fileprivate func setupStar() {
        self.zPosition = GameLayer.Star
        
    }
    
    fileprivate func setupStarPhysics() {
        self.physicsBody = SKPhysicsBody(circleOfRadius: self.size.width / 2, center: self.anchorPoint)
        self.physicsBody?.categoryBitMask = Contact.Star
        self.physicsBody?.collisionBitMask = 0x0
        self.physicsBody?.contactTestBitMask = 0x0
    }
    
    // MARK: - Update
    func update(delta: TimeInterval) {
        self.position.y = kDeviceTablet ? self.position.y - CGFloat(delta * 60 * 4) :
            self.position.y - CGFloat(delta * 60 * 2)
        
        self.position.x = self.position.x + self.drift
        
        // Remove from parent if off the bottom of the screen
        if self.position.y < (0 - self.size.height) {
            self.removeFromParent()
        }
        
        // Remove from parent if off the screen to the left or right
        if self.position.x < (0 - self.size.width) || self.position.x > (kViewSize.width + self.size.width) {
            self.removeFromParent()
        }
        
        // Rotate slowly while moving down the screen
        self.zRotation = self.zRotation + CGFloat(delta)
    }
    
    // MARK: - Action functions
    func pickedUpStar() {
        // Create realistic star explosion effect
        GameAudio.shared.playSoundEffect(.pickup)
        
        // Create particle explosion at star position
        if let starParticle = SKEmitterNode(fileNamed: SpriteName.ExplodeStar) {
            starParticle.position = self.position
            starParticle.zPosition = GameLayer.Star + 1
            
            // Configure for fast, realistic explosion
            starParticle.particleBirthRate = 150  // High burst for immediate effect
            starParticle.particleLifetime = 0.6   // Short-lived for fast effect
            starParticle.particleSpeed = 120      // Fast outward velocity
            starParticle.particleSpeedRange = 60  // Velocity variation
            starParticle.emissionAngleRange = CGFloat.pi * 2  // 360 degree explosion
            starParticle.particleScale = kDeviceTablet ? 0.8 : 0.5
            starParticle.particleScaleRange = 0.3
            starParticle.particleAlpha = 0.9
            starParticle.particleAlphaSpeed = -1.5  // Fast fade
            
            // Add to parent scene
            if let parent = self.parent {
                parent.addChild(starParticle)
                
                // Stop emission after brief burst and auto-remove
                let stopEmission = SKAction.run { starParticle.particleBirthRate = 0 }
                let wait = SKAction.wait(forDuration: 0.1)  // Very brief emission
                let removeParticle = SKAction.run { starParticle.removeFromParent() }
                let waitForFade = SKAction.wait(forDuration: 0.8)  // Wait for particles to fade
                
                starParticle.run(SKAction.sequence([wait, stopEmission, waitForFade, removeParticle]))
            }
        }
        
        // Animate star scaling and rotation for impact
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.05)  // Quick burst
        let scaleDown = SKAction.scale(to: 0.0, duration: 0.15)  // Fast shrink
        let fastSpin = SKAction.rotate(byAngle: CGFloat.pi * 4, duration: 0.2)  // Rapid spin
        let fadeOut = SKAction.fadeOut(withDuration: 0.15)
        
        // Run animations in parallel
        let scaleSequence = SKAction.sequence([scaleUp, scaleDown])
        let animationGroup = SKAction.group([scaleSequence, fastSpin, fadeOut])
        
        self.run(animationGroup) {
            self.removeFromParent()
        }
    }
    
    func gameOver() {
        // Apply grayscale shader
        GameShaders.sharedInstance.shadeGray(node: self)
    }
}
