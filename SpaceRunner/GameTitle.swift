//
//  GameTitle.swift
//  SpaceRunner
//
//  Created by Todd Dube on 3/22/16.
//  Copyright © 2016 Todd Dube. All rights reserved.
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
        self.init(texture: texture, color: SKColor.white, size: texture.size())
        
        self.setupGameTitle()
        self.setupAnimation()
        self.animateIn()
    }
    
    // MARK: - Setup
    fileprivate func setupGameTitle() {
        self.position = CGPoint(x: kViewSize.width / 2, y: kViewSize.height + kViewSize.height / 2)
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
