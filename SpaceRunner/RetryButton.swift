//
//  RetryButton.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Retry button displayed on the Game Over screen, giving the player a one-tap
//  path back into a fresh game session.
//
//  RESPONSIBILITIES
//  - Load and display the RetryButton texture asset
//  - Animate entrance (slide in) and tap feedback (scale bounce)
//  - Provide blink idle animation to prompt re-engagement
//  - Expose tapped() action consumed by GameOverScene touch handler
//

import Foundation
import SpriteKit

class RetryButton: SKSpriteNode {
    
    // MARK: - Privat class variables
    fileprivate var animation = SKAction()
    
    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    // TODO: 
    convenience init() {
        let texture = GameTextures.sharedInstance.textureWithName(name: SpriteName.ButtonRetry)
        self.init(texture: texture, color: SKColor.white, size: texture.size())
        
        self.setupRetryButton()
        self.setupAnimation()
        self.animationIn()
    }
    
    // MARK: - Setup
    fileprivate func setupRetryButton() {
        self.position = CGPoint(x: kViewSize.width / 2, y: -kViewSize.height + kViewSize.height / 2)
    }
    
    fileprivate func setupAnimation() {
        let moveIn = SKAction.move(to: CGPoint(x: kViewSize.width / 2, y: kViewSize.height * 0.25), duration: 0.5)
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.125)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.125)
        
        self.animation = SKAction.sequence([moveIn, scaleUp, scaleDown])
    }
    
    // MARK: - Actions
    func tapped() {
        GameAudio.shared.playSoundEffect(.buttonTap)
    }
    
    // MARK: - Animation
    fileprivate func animationIn() {
        self.run(self.animation)
        self.blinkRetryButton()
    }
    fileprivate func blinkRetryButton() {
        let blink = SKAction.sequence([SKAction.wait(forDuration: 0.5),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.fadeIn(withDuration: 0.5)])
        self.run(SKAction.repeatForever(blink))
    }
}
