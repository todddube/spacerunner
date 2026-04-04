//
//  StatusBar+GlassEffect.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Extension on StatusBar that layers a glass-frosted sheen over the status bar
//  background and adds reactive animation helpers called by GameScene.
//
//  GLASS EFFECT
//  - createGlassBackground()   — builds a gradient sheen texture (createGlassTexture)
//      anchored at (0,0) and added directly to statusBarBackground so it
//      overlays the bar at the correct screen position
//  - The sheen uses an additive blend for the gradient layer and a screen
//      blend for the frosted overlay, simulating a translucent glass surface
//
//  SHOW / HIDE ANIMATIONS
//  - show(with:)  — fade in + slide down from above (status bar entering gameplay)
//  - hide(with:)  — fade out + slide up (status bar hiding during tutorial)
//
//  REACTIVE ANIMATIONS (called by GameScene on events)
//  - animateScoreUpdate(newScore:)  — scale pulse + brief yellow flash on score
//  - animateStarCollection()        — glow burst + bounce on star pickup
//  - animateLifeLoss()              — shake + flash fade on life lost
//  - addSubtleAnimations()          — ambient float/pulse loops applied on init
//

import SpriteKit

extension StatusBar {
    
    func applyGlassEffect() {
        // Attach glass sheen directly on top of the status bar background sprite
        let glassBackground = createGlassBackground()
        glassBackground.zPosition = 1   // just above the solid background
        statusBarBackground.addChild(glassBackground)
        
        // Subtle UI animations
        addSubtleAnimations()
    }
    
    private func createGlassBackground() -> SKSpriteNode {
        // Match the status bar background's actual size
        let barHeight: CGFloat = kDeviceTablet ? 50.0 : 40.0
        let backgroundSize = CGSize(width: kViewSize.width, height: barHeight)
        let glassBackground = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.0), size: backgroundSize)
        
        // Anchor at bottom-left to match statusBarBackground anchor point
        glassBackground.anchorPoint = CGPoint.zero
        glassBackground.position = CGPoint.zero  // sits on top of the status bar background
        
        // Glass sheen texture
        let glassTexture = createGlassTexture(size: backgroundSize)
        let glassLayer = SKSpriteNode(texture: glassTexture)
        glassLayer.anchorPoint = CGPoint.zero
        glassLayer.position = CGPoint.zero
        glassLayer.blendMode = .add
        glassLayer.alpha = 0.25
        glassBackground.addChild(glassLayer)
        
        // Frosted overlay
        let blurLayer = SKSpriteNode(color: UIColor.white.withAlphaComponent(0.06), size: backgroundSize)
        blurLayer.anchorPoint = CGPoint.zero
        blurLayer.position = CGPoint.zero
        blurLayer.blendMode = .screen
        glassBackground.addChild(blurLayer)
        
        return glassBackground
    }
    
    private func createGlassTexture(size: CGSize) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // Create glass gradient
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: [
                                        UIColor.white.withAlphaComponent(0.4).cgColor,
                                        UIColor.clear.cgColor,
                                        UIColor.white.withAlphaComponent(0.2).cgColor,
                                        UIColor.clear.cgColor,
                                        UIColor.white.withAlphaComponent(0.3).cgColor
                                    ] as CFArray,
                                    locations: [0.0, 0.2, 0.4, 0.7, 1.0])!
            
            context.cgContext.drawLinearGradient(gradient,
                                               start: CGPoint(x: 0, y: 0),
                                               end: CGPoint(x: 0, y: size.height),
                                               options: [])
        }
        
        return SKTexture(image: image)
    }
    
    private func addSubtleAnimations() {
        // Add gentle floating animation to score elements
        if let scoreLabel = children.first(where: { $0.name?.contains("score") == true }) {
            let float = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 2, duration: 2.0),
                SKAction.moveBy(x: 0, y: -2, duration: 2.0)
            ])
            scoreLabel.run(SKAction.repeatForever(float))
        }
        
        // Add subtle pulse to lives indicators
        children.filter { $0.name?.contains("life") == true }.forEach { lifeNode in
            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.8, duration: 1.5),
                SKAction.fadeAlpha(to: 1.0, duration: 1.5)
            ])
            lifeNode.run(SKAction.repeatForever(pulse))
        }
    }
    
    func show(with transition: AnimationController.TransitionType) {
        isHidden = false
        alpha = 0
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let slideDown = SKAction.moveBy(x: 0, y: -20, duration: 0.5)
        slideDown.timingMode = .easeOut
        
        // Start from above screen
        position.y += 20
        
        run(SKAction.group([fadeIn, slideDown]))
    }
    
    func hide(with transition: AnimationController.TransitionType) {
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let slideUp = SKAction.moveBy(x: 0, y: 20, duration: 0.3)
        slideUp.timingMode = .easeIn
        
        run(SKAction.group([fadeOut, slideUp])) { [weak self] in
            self?.isHidden = true
        }
    }
    
    func animateScoreUpdate(newScore: Int) {
        // Find score label and animate the update
        if let scoreLabel = children.first(where: { $0.name?.contains("score") == true }) as? SKLabelNode {
            // Scale pulse animation
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.2, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.2)
            ])
            scoreLabel.run(pulse)
            
            // Color flash
            let originalColor = scoreLabel.fontColor
            let flash = SKAction.sequence([
                SKAction.run { scoreLabel.fontColor = .yellow },
                SKAction.wait(forDuration: 0.2),
                SKAction.run { scoreLabel.fontColor = originalColor }
            ])
            scoreLabel.run(flash)
        }
    }
    
    func animateStarCollection() {
        // Find star elements and create collection effect
        children.filter { $0.name?.contains("star") == true }.forEach { starNode in
            // Create brief glow effect
            let glow = starNode.copy() as! SKNode
            glow.alpha = 0
            glow.setScale(1.5)
            addChild(glow)
            
            let glowAnimation = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.8, duration: 0.1),
                SKAction.fadeAlpha(to: 0, duration: 0.3),
                SKAction.removeFromParent()
            ])
            glow.run(glowAnimation)
            
            // Main star animation
            let bounce = SKAction.sequence([
                SKAction.scale(to: 1.3, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ])
            starNode.run(bounce)
        }
    }
    
    func animateLifeLoss() {
        // Find life indicators and animate loss
        let lifeNodes = children.filter { $0.name?.contains("life") == true }
        guard let lastLife = lifeNodes.last else { return }
        
        // Dramatic fade out with shake
        let shake = SKAction.sequence([
            SKAction.moveBy(x: 2, y: 0, duration: 0.05),
            SKAction.moveBy(x: -4, y: 0, duration: 0.05),
            SKAction.moveBy(x: 4, y: 0, duration: 0.05),
            SKAction.moveBy(x: -2, y: 0, duration: 0.05)
        ])
        
        let flash = SKAction.sequence([
            SKAction.run { lastLife.alpha = 0.3 },
            SKAction.wait(forDuration: 0.1),
            SKAction.run { lastLife.alpha = 1.0 },
            SKAction.wait(forDuration: 0.1),
            SKAction.run { lastLife.alpha = 0.3 },
            SKAction.wait(forDuration: 0.1),
            SKAction.run { lastLife.alpha = 0.2 }
        ])
        
        lastLife.run(SKAction.group([shake, flash]))
    }
}