//
//  Meteor.swift
//  SpaceRunner
//
//  Created by Todd Dube : 2025
//  Purpose: Individual meteor obstacle sprites with physics and collision properties.
//

import Foundation
import SpriteKit

class Meteor: SKSpriteNode {
    
    // MARK: - Public enum
    internal enum MeteorType:Int {
        case huge
        case large
        case medium
        case small
    }
    
    // MARK: - Public class variables
    internal var drift = CGFloat()
    
    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    convenience init(type: MeteorType) {
        var texture = SKTexture()
        
        switch type {
            case MeteorType.huge:
                texture = GameTextures.sharedInstance.textureWithName(name: SpriteName.MeteorHuge)
                break
            case MeteorType.large:
                texture = GameTextures.sharedInstance.textureWithName(name: SpriteName.MeteorLarge)
                break
            case MeteorType.medium:
                texture = GameTextures.sharedInstance.textureWithName(name: SpriteName.MeteorMedium)
                break
            case MeteorType.small:
                texture = GameTextures.sharedInstance.textureWithName(name: SpriteName.MeteorSmall)
                break
        }
        
        self.init(texture: texture, color: SKColor.white, size: texture.size())
    
        self.setupMeteor()
        self.setupMeteorPhysics()
        
    }
    
    // MARK: - Setup
    fileprivate func setupMeteor() {
        self.zPosition = GameLayer.Meteor
        
    }
    
    fileprivate func setupMeteorPhysics() {
        self.physicsBody = SKPhysicsBody(circleOfRadius: self.size.width / 2, center: self.anchorPoint)
        self.physicsBody?.categoryBitMask = Contact.Meteor
        self.physicsBody?.collisionBitMask = 0x0  // Ignore collisions
        self.physicsBody?.contactTestBitMask = 0x0 // Ignore contact
    }
    
    // MARK: - Update
    func update(delta:TimeInterval) {
        // move vertically down the screen based on the device type
        self.position.y = kDeviceTablet ? self.position.y - CGFloat(delta * 60 * 4) : self.position.y - CGFloat(delta * 60 * 2)
        
        // Add the drift to the X position
        self.position.x = self.position.x + self.drift
        
        // If meteor is complely off screen at the bottom remove from the parent
        if self.position.y < (0 - self.size.height) {
            self.removeFromParent()
        }
        
        // If meteor is completely off screen left or right remove from parent
        if self.position.x < (0 - self.size.width) || self.position.x > (kViewSize.width + self.size.width) {
            self.removeFromParent()
        }
    }
    
    // MARK: - Action functions
    func hitMeteor() {
        GameAudio.shared.playSoundEffect(.explosion)
        self.run(SKAction.wait(forDuration: 0.1), completion: {
            self.removeFromParent()
        })
    }
    
    func gameOver() {
        // Apply grayscale shader
        GameShaders.sharedInstance.shadeGray(node: self)
    }
}
