//
//  GameTitleShip.swift
//  SpaceRunner
//
//  Created by Todd Dube : 2025
//  Purpose: Rotating ship sprite that accompanies the main title on the menu screen.
//

import Foundation
import SpriteKit

class GameTitleShip: SKSpriteNode {
    
    // MARK: - Private class variables
    fileprivate var animation = SKAction()
    fileprivate var shipFragments: [SKSpriteNode] = []
    fileprivate var isFragmented = false
    
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
        self.createShipFragments()
        self.animateIn()
        self.startBreakApartCycle()
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
    
    // MARK: - Fragment Setup
    fileprivate func createShipFragments() {
        // Create 5 larger fragments using actual ship texture to represent ship pieces
        let shipTexture = GameTextures.sharedInstance.textureWithName(name: SpriteName.Player)
        
        // Fragment data: position, size scale, rotation, and tint for variety (3x larger)
        let fragmentData: [(offset: CGPoint, scale: CGFloat, rotation: CGFloat, color: UIColor)] = [
            // Nose section (front of ship)
            (CGPoint(x: 0, y: 15), 1.8, 0.0, Colors.colorFromRGB(rgbvalue: Colors.EngineYellow)),
            // Left wing section  
            (CGPoint(x: -18, y: 5), 1.2, -0.3, Colors.colorFromRGB(rgbvalue: Colors.EngineRed)),
            // Right wing section
            (CGPoint(x: 18, y: 5), 1.2, 0.3, Colors.colorFromRGB(rgbvalue: Colors.EngineRed)),
            // Engine/rear section
            (CGPoint(x: 0, y: -12), 1.5, 0.0, Colors.colorFromRGB(rgbvalue: Colors.EngineGreen)),
            // Center body section
            (CGPoint(x: 0, y: 2), 1.05, 0.0, SKColor.white)
        ]
        
        for (_, data) in fragmentData.enumerated() {
            let fragment = SKSpriteNode(texture: shipTexture)
            
            // Scale fragment to represent a piece of the ship
            let baseSize = shipTexture.size()
            fragment.size = CGSize(
                width: baseSize.width * data.scale,
                height: baseSize.height * data.scale
            )
            
            fragment.position = data.offset
            fragment.zRotation = data.rotation
            fragment.alpha = 0.0 // Start invisible
            fragment.color = data.color
            fragment.colorBlendFactor = 0.6 // Blend with original texture
            fragment.zPosition = 10
            
            self.addChild(fragment)
            shipFragments.append(fragment)
        }
        // print("DEBUG: Created \(shipFragments.count) ship fragments using actual ship texture")
    }
    
    // MARK: - Break Apart Animation
    fileprivate func startBreakApartCycle() {
        // print("DEBUG: startBreakApartCycle called")
        // Wait for ship fly-in animation (3.0s) plus additional spinning time (4.0s) before first break-apart
        let waitForFlyInAndSpin = SKAction.wait(forDuration: 7.0)
        let startBreakApart = SKAction.run { [weak self] in
            // print("DEBUG: About to call performBreakApartCycle")
            self?.performBreakApartCycle()
        }
        
        self.run(SKAction.sequence([waitForFlyInAndSpin, startBreakApart]))
    }
    
    fileprivate func performBreakApartCycle() {
        // print("DEBUG: performBreakApartCycle called")
        // Perform break apart animation every 4 seconds for easier testing
        let breakApart = SKAction.run { [weak self] in
            // print("DEBUG: About to call animateBreakApart")
            self?.animateBreakApart()
        }
        let waitBetween = SKAction.wait(forDuration: 4.0)
        let cycle = SKAction.sequence([breakApart, waitBetween])
        
        self.run(SKAction.repeatForever(cycle), withKey: "breakApartCycle")
    }
    
    fileprivate func animateBreakApart() {
        guard !isFragmented else { 
            // print("DEBUG: animateBreakApart skipped - already fragmented")
            return 
        }
        // print("DEBUG: animateBreakApart started - fragments count: \(shipFragments.count)")
        isFragmented = true
        
        // Add explosion particle effect at the moment of breakapart
        let explosionParticles = GameParticles.sharedInstance.createParticle(particles: .player)
        explosionParticles.position = CGPoint.zero
        explosionParticles.zPosition = 15
        self.addChild(explosionParticles)
        
        // Remove explosion particles after effect
        let removeExplosion = SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.removeFromParent()
        ])
        explosionParticles.run(removeExplosion)
        
        // Play explosion sound effect
        GameAudio.shared.playSoundEffect(.explosion)
        
        // Hide main ship more dramatically
        let scaleDown = SKAction.scale(to: 0.1, duration: 0.2)
        let fadeOutShip = SKAction.fadeAlpha(to: 0.0, duration: 0.2)
        let shipBreakEffect = SKAction.group([scaleDown, fadeOutShip])
        self.run(shipBreakEffect)
        
        // Animate fragments breaking apart with more realistic physics
        for (_, fragment) in shipFragments.enumerated() {
            let originalPosition = fragment.position
            // print("DEBUG: Animating fragment \(index) from position \(originalPosition)")
            
            // Calculate break-apart position with random velocity vectors
            let randomAngle = CGFloat.random(in: 0...2 * .pi)
            let randomDistance = CGFloat.random(in: 80...150)
            let breakPosition = CGPoint(
                x: originalPosition.x + cos(randomAngle) * randomDistance,
                y: originalPosition.y + sin(randomAngle) * randomDistance
            )
            
            // Add fragment particle trails
            let fragmentTrail = GameParticles.sharedInstance.createParticle(particles: .magic)
            fragmentTrail.particleBirthRate = 20
            fragmentTrail.particleLifetime = 0.5
            fragmentTrail.particleScale = 0.3
            fragmentTrail.particleColor = fragment.color
            fragment.addChild(fragmentTrail)
            
            // Dynamic animation based on fragment position
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.1)
            let moveOut = SKAction.move(to: breakPosition, duration: CGFloat.random(in: 0.8...1.2))
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -8...8), duration: 1.0)
            let scaleVariation = SKAction.scale(to: CGFloat.random(in: 1.5...2.5), duration: 0.4)
            let fadeOutFragment = SKAction.fadeAlpha(to: CGFloat.random(in: 0.3...0.7), duration: 0.6)
            
            let breakActions = SKAction.group([fadeIn, moveOut, rotate, scaleVariation])
            let trailFade = SKAction.group([fadeOutFragment])
            
            // After breaking apart, reassemble with gravity-like effect
            let waitBeforeReassemble = SKAction.wait(forDuration: CGFloat.random(in: 1.0...1.5))
            let moveBack = SKAction.move(to: originalPosition, duration: 0.6)
            let rotateBack = SKAction.rotate(toAngle: 0, duration: 0.6)
            let scaleBack = SKAction.scale(to: 1.0, duration: 0.4)
            let hideFragment = SKAction.fadeAlpha(to: 0.0, duration: 0.3)
            
            let reassembleActions = SKAction.group([moveBack, rotateBack, scaleBack])
            
            let fullSequence = SKAction.sequence([
                breakActions,
                trailFade,
                waitBeforeReassemble,
                reassembleActions,
                hideFragment
            ])
            
            fragment.run(fullSequence) {
                // Remove particle trail when fragment animation completes
                fragmentTrail.removeFromParent()
            }
        }
        
        // Restore main ship with dramatic entrance
        let waitForReassemble = SKAction.wait(forDuration: 2.8)
        let scaleUpShip = SKAction.scale(to: 1.0, duration: 0.4)
        let fadeInShip = SKAction.fadeAlpha(to: 1.0, duration: 0.4)
        let shipRestoreEffect = SKAction.group([scaleUpShip, fadeInShip])
        let resetFlag = SKAction.run { [weak self] in
            self?.isFragmented = false
            // print("DEBUG: Animation cycle complete, ready for next cycle")
        }
        
        let restoreSequence = SKAction.sequence([waitForReassemble, shipRestoreEffect, resetFlag])
        self.run(restoreSequence)
    }
    
    // MARK: - Animations
    fileprivate func animateIn() {
        self.run(self.animation)
    }
}