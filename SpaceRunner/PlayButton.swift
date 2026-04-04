//
//  PlayButton.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Animated play button sprite displayed on the main menu. Animates in from
//  off-screen, scales on tap, and triggers the transition to GameScene.
//
//  RESPONSIBILITIES
//  - Load and display the PlayButton texture asset
//  - Animate entrance (slide down from top) and tap feedback (scale bounce)
//  - Provide blink idle animation to attract player attention
//  - Expose tapped() action consumed by MenuScene touch handler
//

import Foundation
import SpriteKit

class PlayButton: SKSpriteNode {
    
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
        let texture = GameTextures.sharedInstance.textureWithName(name: SpriteName.ButtonPlay)
        
        // Make button 25% bigger
        let originalSize = texture.size()
        let scaledSize = CGSize(width: originalSize.width * 1.25, height: originalSize.height * 1.25)
        
        self.init(texture: texture, color: SKColor.white, size: scaledSize)
        
        self.setupPlayButton()
        self.setupAnimation()
        self.animateIn()
    }
    
    // MARK: - Setup
    fileprivate func setupPlayButton() {
        self.position = CGPoint(x: kViewSize.width / 2, y: kViewSize.height + kViewSize.height / 2)
    }
    
    fileprivate func setupAnimation() {
        let moveIn = SKAction.move(to: CGPoint(x: kViewSize.width / 2, y: kViewSize.height * 0.3), duration: 0.5)
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.125)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.125)
        
        self.animation = SKAction.sequence([moveIn, scaleUp, scaleDown])
    }
    
    // MARK: - Actions
    func tapped() {
        GameAudio.shared.playSoundEffect(.buttonTap)
    }
    
    // MARK: - Animations
    fileprivate func animateIn() {
        self.run(self.animation, completion: {
            self.blinkPlayButton()
        })
    }
    
    fileprivate func blinkPlayButton() {
        let blink = SKAction.sequence([SKAction.wait(forDuration: 0.5),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.fadeIn(withDuration: 0.5)])
        self.run(SKAction.repeatForever(blink))
    }
}
