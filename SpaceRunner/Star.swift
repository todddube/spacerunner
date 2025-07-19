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
    
    // MARK: - INit
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
        // pick up star, audio, and then animate it.. remove from parent
        self.run(GameAudio.sharedInstance.soundPickup, completion: {
            self.run(SKAction.repeat(SKAction.rotate(byAngle: 10.0, duration: 2.5), count: 10))
                
            self.removeFromParent()
        })
    }
    
    func gameOver() {
        // Apply grayscale shader
        GameShaders.sharedInstance.shadeGray(node: self)
    }
}
