//
//  StartButton.swift
//  SpaceRunner
//
//  Created by Todd Dube : 2025
//  Purpose: Start button sprite that appears during the tutorial phase to begin gameplay.
//

import Foundation
import SpriteKit

class StartButton: SKSpriteNode {
    
    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    convenience init() {
        let texture = GameTextures.sharedInstance.textureWithName(name: SpriteName.ButtonStart)
        
        // Calculate size to be 35% of screen width (5x larger than 7%) while maintaining aspect ratio
        let originalSize = texture.size()
        let targetWidth = kViewSize.width * 0.35
        let aspectRatio = originalSize.height / originalSize.width
        let targetHeight = targetWidth * aspectRatio
        let scaledSize = CGSize(width: targetWidth, height: targetHeight)
        
        self.init(texture:texture, color:SKColor.white, size:scaledSize)
        self.setupStartButton()
    }
    
    // MARK: - Setup
    fileprivate func setupStartButton() {
        self.position = CGPoint(x: kViewSize.width / 2, y: kViewSize.height / 2)
    }
    
    
    // MARK: - Actions
    func fadeStartButton() {
        self.run(SKAction.fadeOut(withDuration: 1.5), completion: { () -> Void in self.removeFromParent()
        }) 
    }
    
    func tapped() {
        GameAudio.shared.playSoundEffect(.buttonTap)
    }
}
