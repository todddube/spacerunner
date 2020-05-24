//
//  MeteorController.swift
//  SpaceRunner
//
//  Created by Todd Dube on 3/23/16.
//  Copyright © 2020 Todd Dube. All rights reserved.
//

import Foundation
import SpriteKit

class MeteorController: SKNode {
    
    // MARK: - Private class constants
    fileprivate let meteor0 = Meteor(type: Meteor.MeteorType.huge)
    fileprivate let meteor1 = Meteor(type: Meteor.MeteorType.large)
    fileprivate let meteor2 = Meteor(type: Meteor.MeteorType.medium)
    fileprivate let meteor3 = Meteor(type: Meteor.MeteorType.small)
    
    // MARK: - Private class variables
    fileprivate var sendingMeteors = false
    fileprivate var movingMeteors = false
    fileprivate var frameCount = 0.0
    fileprivate var meteorArray = [SKSpriteNode]()
    
    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init() {
        super.init()
        
        self.setupMeteorController()
    }
    
    // MARK: - Setup
    fileprivate func setupMeteorController() {
        self.meteorArray = [self.meteor0, self.meteor1, self.meteor2, self.meteor3]
    }
    
    // MARK: - Update
    func update(delta:TimeInterval) {
        // is it time to send more meteors?
        if self.sendingMeteors {
            self.frameCount += delta
            
            if self.frameCount >= 4.0 {
                // Approx 4 seconds have passsed, spawn more meteors
                self.spawnMeteors()
                
                // Reset the frameCount
                self.frameCount = 0.0
            }
        }
        
        // Move the meteors on the screen
        if self.movingMeteors {
            for node in self.children {
                if let meteor = node as? Meteor {
                    meteor.update(delta: delta)
                }
            }
        }
    }
    
    // MARK: - Spawn
    fileprivate func spawnMeteors() {
        if self.sendingMeteors {
            // let randomMeteorCount = kDeviceTablet ? RandomIntegerBetween(min: 6, max: 10) : RandomIntegerBetween(min: 10, max: 14)
            let randomMeteorCount = kDeviceTablet ? RandomIntegerBetween(min: 2, max: 7) : RandomIntegerBetween(min: 4, max: 10)
            
            
            for _ in 0...randomMeteorCount {
                let randomMeteorIndex = RandomIntegerBetween(min: 0, max: 3)
                
                let offsetX:CGFloat = randomMeteorIndex % 2 == 0 ? -72:72
                let startX = RandomFloatRange(min: 0, max: kViewSize.width) + offsetX
                
                let offsetY:CGFloat = randomMeteorIndex % 2 == 0 ? 72:-72
                let startY = kViewSize.height * 1.25 + offsetY
                
                let meteor = self.meteorArray[randomMeteorIndex].copy() as! Meteor
                meteor.drift = RandomFloatRange(min: -0.3, max: 0.3)
                
                meteor.position = CGPoint(x: startX, y: startY)
                
                self.addChild(meteor)
            }
        }
    }
    
    // MARK: - Action functions
    func startSendingMeteors() {
        self.sendingMeteors = true
        self.movingMeteors = true
    }
    
    func stopSendingMetors() {
        self.sendingMeteors = false
        self.movingMeteors = false
    }
    
    func gameOver() {
        for node in self.children {
            if let meteor = node as? Meteor {
                meteor.gameOver()
            }
        }
    }
}
