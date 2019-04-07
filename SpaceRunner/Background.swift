//
//  Background.swift
//  SpaceRunner
//
//  Created by Todd Dube on 3/20/16.
//  Copyright © 2016 Todd Dube. All rights reserved.
//

import Foundation
import SpriteKit

class Background: SKNode {
    
    // MARK: - Private class constants
    fileprivate let backgroundRunSpeed: CGFloat = -200.0
    fileprivate let backgroundStopSpeed: CGFloat = -25.0
    
    // MARK: - Private class variables
    fileprivate var backgroundParticles = SKEmitterNode()
    fileprivate var backgroundParticlesSmall = SKEmitterNode()
    
    // MARK: - Init
    required init?(coder aDecoder:NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init() {
        super.init()
        
        self.setupBackground()
    }
    
    // MARK: - Setup
    fileprivate func setupBackground() {
        self.backgroundParticles = GameParticles.sharedInstance.createParticle(particles: GameParticles.Particles.magic)
        
        // Small white particles
        self.backgroundParticlesSmall = GameParticles.sharedInstance.createParticle(particles: GameParticles.Particles.magic)
        self.backgroundParticlesSmall.particleScale = 0.25
        
        self.addChild(self.backgroundParticles)
        self.addChild(self.backgroundParticlesSmall)
                
        self.stopBackground()
    }
    
    // MARK: - Action
    func startBackgrond() {
        self.backgroundParticles.particleSpeed = self.backgroundRunSpeed
        self.backgroundParticles.particleSpeedRange = self.backgroundRunSpeed / 4
        
        self.backgroundParticlesSmall.particleSpeed = self.backgroundRunSpeed * 1.5
        self.backgroundParticlesSmall.particleSpeedRange = self.backgroundParticlesSmall.particleSpeed / 4
    }
    
    func stopBackground() {
        self.backgroundParticles.particleSpeed = self.backgroundStopSpeed
        self.backgroundParticles.particleSpeedRange = self.backgroundStopSpeed / 4
        
        self.backgroundParticlesSmall.particleSpeed = self.backgroundStopSpeed * 1.5
        self.backgroundParticlesSmall.particleSpeedRange = self.backgroundParticlesSmall.particleSpeed / 4
    }
    
    func gameOver() {
        self.backgroundParticles.particleColor = SKColor.gray
        self.backgroundParticlesSmall.particleColor = SKColor.gray
    }
}
