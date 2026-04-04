//
//  TouchCircle.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Transient visual indicator that renders briefly at the touch point when the
//  player taps or drags. Fades out automatically so it never clutters the HUD.
//
//  RESPONSIBILITIES
//  - init()       — create a semi-transparent circle shape node at the touch location
//  - show(at:)    — position the node and run a short fade-in + fade-out sequence
//  - The circle is sized relative to kViewSize so it reads clearly on all devices
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
