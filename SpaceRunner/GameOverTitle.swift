//
//  GameOverTitle.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  "GAME OVER" logo sprite displayed at the top of the Game Over scene.
//  Flies in with a short bounce animation to draw the player's eye before
//  the scoreboard slides in below it.
//
//  RESPONSIBILITIES
//  - Load the GameOverTitle texture and position it at y ≈ 70 % of screen height
//  - Animate entrance from off-screen top with a scale-bounce landing
//

import Foundation
import SpriteKit

class GameOverTitle: SKSpriteNode {
    
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
        let texture = GameTextures.sharedInstance.textureWithName(name: SpriteName.TitleGameOver)
        
        self.init(texture: texture, color: SKColor.white, size: texture.size())
        
        self.setupGameOverTitle()
        self.setupAnimation()
        self.animateIn()
    }
    
    // MARK: - Setup
    fileprivate func setupGameOverTitle() {
        self.position = CGPoint(x: kViewSize.width / 2, y: kViewSize.height * 0.7)
    }
    
    fileprivate func setupAnimation() {
        let moveIn = SKAction.move(to: CGPoint(x: kViewSize.width / 2, y: kViewSize.height * 0.7), duration: 0.5)
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.125)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.125)
        
        self.animation = SKAction.sequence([moveIn, scaleUp, scaleDown])
    }
    
    // MARK: - Animations
    fileprivate func animateIn() {
        self.run(self.animation)
    }
}
