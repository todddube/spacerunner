//
//  MeteorController.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Spawns and manages all active Meteor nodes. Uses a repeating SKAction timer
//  to add new meteors at randomised horizontal positions and escalating frequency
//  as the game progresses.
//
//  RESPONSIBILITIES
//  - startSendingMeteors()    — begin the spawn timer with initial difficulty settings
//  - stopSendingMetors()      — halt spawning (pause / game-over)
//  - update(delta:)           — forward delta time to every active Meteor child node
//  - gameOver()               — stop spawning and freeze all active meteors
//  - spawnMeteor()            — pick a random Meteor size variant, position it above
//      the top of the screen at a random X, and add it as a child node
//  - Difficulty ramps by shortening the spawn interval over time
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

    // MARK: - Tier / difficulty
    var currentTier: Int = 1
    var speedMultiplier: CGFloat = 1.0
    var spawnInterval: TimeInterval = 4.0
    
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
            
            if self.frameCount >= spawnInterval {
                // Approx 4 seconds have passsed, spawn more meteors
                self.spawnMeteors()
                
                // Reset the frameCount
                self.frameCount = 0.0
            }
        }
        
        // Move the meteors and laser beams on screen
        if self.movingMeteors {
            for node in self.children {
                if let meteor = node as? Meteor {
                    meteor.update(delta: delta)
                } else if let laser = node as? LaserBeam {
                    laser.update(delta: delta)
                }
            }
        }
    }
    
    // MARK: - Tier configuration

    func setTier(_ tier: Int) {
        currentTier     = tier
        spawnInterval   = GameTier.spawnIntervals[tier]    ?? 4.0
        speedMultiplier = GameTier.speedMultipliers[tier]  ?? 1.0
    }

    // MARK: - Spawn

    fileprivate func spawnMeteors() {
        guard self.sendingMeteors else { return }

        // Tier 3+: 15% chance to spawn a laser beam instead
        if currentTier >= 3 && Float.random(in: 0..<1) < 0.15 {
            let laser = LaserBeam()
            self.addChild(laser)
            return
        }

        // Tier 2+: 20% chance for a horizontal swarm of 6 small meteors
        if currentTier >= 2 && Float.random(in: 0..<1) < 0.20 {
            spawnSwarm()
            return
        }

        // Default: random mix of 4-10 meteors (tier-1 behaviour)
        let randomMeteorCount = kDeviceTablet
            ? RandomIntegerBetween(min: 2, max: 7)
            : RandomIntegerBetween(min: 4, max: 10)

        for _ in 0...randomMeteorCount {
            let randomMeteorIndex = RandomIntegerBetween(min: 0, max: 3)

            let offsetX: CGFloat = randomMeteorIndex % 2 == 0 ? -72 : 72
            let startX = RandomFloatRange(min: 0, max: kViewSize.width) + offsetX

            let offsetY: CGFloat = randomMeteorIndex % 2 == 0 ? 72 : -72
            let startY = kViewSize.height * 1.25 + offsetY

            let meteor = self.meteorArray[randomMeteorIndex].copy() as! Meteor
            meteor.drift = RandomFloatRange(min: -0.3, max: 0.3)
            meteor.speedMultiplier = speedMultiplier
            meteor.position = CGPoint(x: startX, y: startY)
            self.addChild(meteor)
        }
    }

    fileprivate func spawnSwarm() {
        let swarmCount = 6
        let spacing: CGFloat = 50
        let totalWidth = CGFloat(swarmCount - 1) * spacing
        let startX = RandomFloatRange(min: totalWidth / 2, max: kViewSize.width - totalWidth / 2)
        let startY = kViewSize.height * 1.25

        for i in 0..<swarmCount {
            let meteor = self.meteorArray[3].copy() as! Meteor  // small variant
            meteor.drift = 0
            meteor.speedMultiplier = speedMultiplier
            meteor.position = CGPoint(x: startX + CGFloat(i) * spacing, y: startY)
            self.addChild(meteor)
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
    
    // MARK: - Reset
    func reset() {
        // Stop sending meteors
        sendingMeteors = false
        movingMeteors = false

        // Reset frame counter
        frameCount = 0.0

        // Reset tier to defaults
        setTier(1)

        // Remove all active meteors / lasers from the scene
        removeAllChildren()

        // Reset meteor templates to initial state
        for meteor in meteorArray {
            meteor.removeFromParent()
            meteor.removeAllActions()
            meteor.alpha = 1.0
            meteor.colorBlendFactor = 0.0
        }
    }
}
