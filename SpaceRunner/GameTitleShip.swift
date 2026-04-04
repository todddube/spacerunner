//
//  GameTitleShip.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Decorative player-ship sprite on the main menu that spins continuously,
//  giving the title screen energy and hinting at the gameplay theme.
//
//  RESPONSIBILITIES
//  - Load the GameTitleShip texture at native size
//  - Animate entrance: slide in from off-screen corner, then bounce-settle
//  - Run a continuous 360° rotation (8-second period) as an idle effect
//  - MenuScene drives the rotation via a named SKAction key "mainRotation"
//

import Foundation
import SpriteKit

class GameTitleShip: SKSpriteNode {
    
    // MARK: - Private class variables
    fileprivate var animation = SKAction()
    
    // MARK: Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    convenience init() {
        let texture = GameTextures.sharedInstance.textureWithName(name: SpriteName.TitleGameShip)
        self.init(texture: texture, color: SKColor.white, size: texture.size())
        
        self.setupGameTitleShip()
        self.setupAnimation()
        self.animateIn()
    }
    
    // MARK: - Setup
    fileprivate func setupGameTitleShip() {
        // Offscreen lower left corner
        self.position = CGPoint(x: -kViewSize.width / 2, y: -kViewSize.height / 2)
    }
    
    fileprivate func setupAnimation() {
        // updated durations for better animation on the start up
        let moveIn = SKAction.move(to: kScreenCenter, duration: 2.5)
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.25)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.25)
        
        self.animation = SKAction.sequence([moveIn, scaleUp, scaleDown])
    }
    
    
    // MARK: - Animations
    fileprivate func animateIn() {
        self.run(self.animation)
    }
}