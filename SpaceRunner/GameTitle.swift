//
//  GameTitle.swift
//  SpaceRunner
//
//  Created by Todd Dube : 2025
//  Purpose: Animated main title sprite that appears on the menu screen.
//

import Foundation
import SpriteKit

class GameTitle: SKSpriteNode {
    
    // MARK: - Private class variables
    fileprivate var animation = SKAction()

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    convenience init() {
        let texture = GameTextures.sharedInstance.textureWithName(name: SpriteName.TitleGame)
        
        // Calculate size to be 80% of screen width while maintaining aspect ratio
        let originalSize = texture.size()
        let targetWidth = kViewSize.width * 0.8
        let aspectRatio = originalSize.height / originalSize.width
        let targetHeight = targetWidth * aspectRatio
        let scaledSize = CGSize(width: targetWidth, height: targetHeight)
        
        self.init(texture: texture, color: SKColor.white, size: scaledSize)
        
        self.setupGameTitle()
        self.setupAnimation()
        self.animateIn()
    }
    
    // MARK: - Setup
    fileprivate func setupGameTitle() {
        self.position = CGPoint(x: kViewSize.width / 2, y: kViewSize.height + kViewSize.height / 2)
    }
    
    fileprivate func setupAnimation() {
        // Position title higher to accommodate larger size and ensure readability
        let finalY = kViewSize.height * 0.75 // Moved up from 0.7 to give more space
        let moveIn = SKAction.move(to: CGPoint(x: kViewSize.width / 2, y: finalY), duration: 1.5)
        let scaleUp = SKAction.scale(to: 1.05, duration: 0.125) // Reduced from 1.1 since title is already large
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.125)
        
        self.animation = SKAction.sequence([moveIn, scaleUp, scaleDown])
    }
    
    // MARK: - Animations
    fileprivate func animateIn() {
        self.run(self.animation)
    }
    
}
