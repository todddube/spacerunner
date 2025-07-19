//
//  TouchCircle.swift
//  SpaceRunner
//
//  Created by Todd Dube : 2025
//  Purpose: Visual feedback sprite that shows where the player has touched the screen.
//

import Foundation
import SpriteKit

class TouchCircle: SKSpriteNode {
    
    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    convenience init() {
        let texture = GameTextures.sharedInstance.textureWithName(name: SpriteName.TouchCircle)
        self.init(texture: texture, color: SKColor.white, size: texture.size())
        
        self.setupTouchCircle()
    }
    
    // MARK: - Setup
    fileprivate func setupTouchCircle() {
        self.alpha = 0.0
    }
    
    // MARK: - Animations
    func animateTouchCircle(atPosition: CGPoint) {
        self.position = atPosition
        
        // Fade / scale in
        let fadeIn = SKAction.fadeAlpha(to: 0.5, duration: 0.15)
        let scaleIn = SKAction.scale(to: 1.1, duration: 0.15)
        
        // Scale in group
        let scaleInGroup = SKAction.group([fadeIn, scaleIn])
        let scaleInNormal = SKAction.scale(to: 1.0, duration: 0.15)
        
        // Scale in sequence
        let scaleInSequence = SKAction.sequence([scaleInGroup, scaleInNormal])
        
        // Run the fade / sacle in sequence, then fade out
        self.run(SKAction.sequence([scaleInSequence, SKAction.fadeOut(withDuration: 0.15),
            SKAction.removeFromParent()]))
    }
}
