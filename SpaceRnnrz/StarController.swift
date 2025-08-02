//
//  StarController.swift
//  SpaceRunner
//
//  Created by Todd Dube : 2025
//  Purpose: Manages spawning, movement, and lifecycle of collectible star objects during gameplay.
//

import Foundation
import SpriteKit

class StarController: SKNode {
    
    // MARK: - Private class constants
    fileprivate let star = Star()
    
    // MARK: - Private class variables
    fileprivate var sendingStars = false
    fileprivate var movingStars = false
    fileprivate var frameCount = 0.0
    
    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init() {
        super.init()
        
        self.setupStarController()
    }
    
    // MARK: - Setup
    fileprivate func setupStarController() {
        
    }
    
    // MARK: - Update
    func update(delta: TimeInterval) {
        // is it time to send another star?
        if self.sendingStars {
            self.frameCount += delta
            
            if self.frameCount >= 3.0 {
                // spawn a star
                self.spawnStar()
                
                // reset the frame counter
                self.frameCount = 0.0
            }
        }
        // Move the stars on screen
        if self.movingStars {
            for node in self.children {
                if let star = node as? Star {
                    star.update(delta: delta)
                }
            }
        }
    }
    
    // MARK: - Spawn
    fileprivate func spawnStar() {
        if self.sendingStars {
            let startX = RandomFloatRange(min: 0, max: kViewSize.width)
            let startY = kViewSize.height * 1.25
            
            let star = self.star.copy() as! Star
            star.position = CGPoint(x: startX, y: startY)
            star.drift = RandomFloatRange(min: -0.25, max: 0.25)
            self.addChild(star)
        }
    }
    
    // MARK: - Actions
    func startSendingStars() {
        self.sendingStars = true
        self.movingStars = true
    }
    
    func stopSendingStars() {
        self.sendingStars = false
        self.movingStars = false
    }
    
    func gameOver() {
        for node in self.children {
            if let star = node as? Star {
                star.gameOver()
            }
        }
    }
    
    // MARK: - Reset
    func reset() {
        // Stop sending stars
        sendingStars = false
        movingStars = false
        
        // Reset frame counter
        frameCount = 0.0
        
        // Remove all active stars from the scene
        removeAllChildren()
        
        // Reset star template to initial state
        star.removeFromParent()
        star.removeAllActions()
        star.alpha = 1.0
        star.colorBlendFactor = 0.0
    }
}
