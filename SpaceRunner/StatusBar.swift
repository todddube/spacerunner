//
//  StatusBar.swift
//  SpaceRunner
//
//  Created by Todd Dube : 2025
//  Purpose: In-game status bar displaying score, lives, collected stars, and pause button.
//

import Foundation
import SpriteKit
import UIKit

class StatusBar: SKNode {
    
    // MARK: - Private class variables
    fileprivate var statusBarBackground = SKSpriteNode()
    fileprivate var scoreLabel = SKLabelNode()
    fileprivate var starsCollectedIcon = SKSpriteNode()
    fileprivate var starsCollectedLabel = SKLabelNode()
    
    // MARK: Public class constants
    internal let pauseButton = PauseButton()
    
    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init() {
        super.init()
    }
    
    convenience init(lives: Int, score: Int, stars: Int) {
        self.init()
        
        // print("🔥 StatusBar: Initializing with lives: \(lives), score: \(score), stars: \(stars)")
        
        self.setupStatusBar()
        self.setupStatusBarBackground()
        self.setupStatusBarScore(score: score)
        self.updateLives(lives: lives)
        self.setupStatusBarStarsCollected(collected: stars)
        self.setupPauseButton()
        
        // Ensure StatusBar appears above game elements
        self.zPosition = 100
        
        // print("🔥 StatusBar: Initialization complete! Position: \(self.position), zPosition: \(self.zPosition)")
        // print("🔥 StatusBar: Background size: \(self.statusBarBackground.size), alpha: \(self.statusBarBackground.alpha)")
    }
    
    // MARK: - Setup
    fileprivate func setupStatusBar() {
        
    }
    
    fileprivate func setupStatusBarBackground() {
        // Calculate sleek status bar height - optimized for modern devices
        let statusBarHeight: CGFloat = kDeviceTablet ? 50.0 : 40.0
        let statusBarBackgroundSize = CGSize(width: kViewSize.width, height: statusBarHeight)
    
        // Create sleek space-themed gradient background
        let backgroundNode = createGradientBackground(size: statusBarBackgroundSize)
        self.statusBarBackground = backgroundNode
        
        // Make the anchorPoint 0,0 so it is positioned using the lower left corner
        self.statusBarBackground.anchorPoint = CGPoint.zero
        
        // Position at bottom of screen just above the edge
        let bottomPosition = calculateBottomPosition(statusBarHeight: statusBarHeight)
        self.statusBarBackground.position = CGPoint(x: 0, y: bottomPosition)
        
        // Add modern edge glow effect
        let glowEffect = createEdgeGlow(size: statusBarBackgroundSize)
        self.statusBarBackground.addChild(glowEffect)

        // Add statusBarBackground to the StatusBar node
        self.addChild(self.statusBarBackground)
    }
    
    private func calculateBottomPosition(statusBarHeight: CGFloat) -> CGFloat {
        if kDeviceTablet {
            // iPad - position just above bottom edge with padding
            return 10
        } else {
            // Try to get actual safe area from the scene's view
            var actualSafeAreaBottom: CGFloat = 0
            
            if let scene = self.scene,
               let view = scene.view,
               let window = view.window {
                let safeAreaInsets = window.safeAreaInsets
                actualSafeAreaBottom = safeAreaInsets.bottom
                print("📱 StatusBar: Actual safe area bottom: \(actualSafeAreaBottom)")
            }
            
            // If we can't get actual safe area, fall back to device detection
            if actualSafeAreaBottom == 0 {
                actualSafeAreaBottom = detectSafeAreaBottom()
            }
            
            // Position StatusBar above the safe area with some padding
            let calculatedBottom = actualSafeAreaBottom + 8
            
            // Debug logging for safe area calculations
            print("📱 StatusBar: Using safe area bottom: \(actualSafeAreaBottom), calculated position: \(calculatedBottom)")
            
            return calculatedBottom
        }
    }
    
    private func detectSafeAreaBottom() -> CGFloat {
        let screenHeight = kViewSize.height
        let screenWidth = kViewSize.width
        let aspectRatio = screenHeight / screenWidth
        
        // Safe area bottom insets for different iPhone models
        let safeAreaInset: CGFloat
        
        // iPhone with Face ID (X and newer) - have home indicator
        if aspectRatio > 2.0 {
            safeAreaInset = 34 // Standard bottom safe area for Face ID devices
        }
        // iPhone with home button (8 and older) - no home indicator
        else {
            safeAreaInset = 0 // No bottom safe area
        }
        
        print("📱 StatusBar: Device detection - Screen: \(screenWidth)x\(screenHeight), ratio: \(aspectRatio), bottom inset: \(safeAreaInset)")
        
        return safeAreaInset
    }
    
    // MARK: - Modern Visual Effects
    private func createGradientBackground(size: CGSize) -> SKSpriteNode {
        // Create modern grayscale background with elegant transparency
        let primaryColor = SKColor(white: 0.12, alpha: 0.95) // Dark charcoal gray
        let background = SKSpriteNode(color: primaryColor, size: size)
        
        // Add subtle texture overlay for depth using light gray
        let textureOverlay = SKSpriteNode(color: SKColor(white: 0.85, alpha: 0.04), size: size)
        textureOverlay.anchorPoint = CGPoint.zero
        textureOverlay.blendMode = .add
        background.addChild(textureOverlay)
        
        return background
    }
    
    private func createEdgeGlow(size: CGSize) -> SKNode {
        let glowContainer = SKNode()
        
        // Top edge glow - bright white accent
        let topGlow = SKSpriteNode(color: SKColor(white: 0.9, alpha: 0.7), 
                                 size: CGSize(width: size.width, height: 1.5))
        topGlow.anchorPoint = CGPoint(x: 0, y: 0)
        topGlow.position = CGPoint(x: 0, y: size.height - 1.5)
        topGlow.blendMode = .add
        
        // Bottom edge glow - soft gray
        let bottomGlow = SKSpriteNode(color: SKColor(white: 0.6, alpha: 0.4), 
                                    size: CGSize(width: size.width, height: 1.0))
        bottomGlow.anchorPoint = CGPoint(x: 0, y: 0)
        bottomGlow.position = CGPoint(x: 0, y: 0)
        bottomGlow.blendMode = .add
        
        glowContainer.addChild(topGlow)
        glowContainer.addChild(bottomGlow)
        
        return glowContainer
    }
    
    fileprivate func setupStatusBarStarsCollected(collected: Int) {
        // Create sleek star display section
        let starContainer = SKNode()
        
        // Collected stars icon with compact sizing to fit with number
        self.starsCollectedIcon = SKSpriteNode(texture: GameTextures.sharedInstance.textureWithName(name: SpriteName.StarIcon))
        self.starsCollectedIcon.setScale(kDeviceTablet ? 0.4 : 0.35) // Smaller size to accommodate star count number
        
        // Add subtle glow to star icon using grayscale
        let starGlow = SKSpriteNode(texture: GameTextures.sharedInstance.textureWithName(name: SpriteName.StarIcon))
        starGlow.setScale(kDeviceTablet ? 0.5 : 0.45) // Proportionally adjusted glow for compact size
        starGlow.alpha = 0.3
        starGlow.color = SKColor(white: 0.8, alpha: 1.0) // Light gray glow
        starGlow.colorBlendFactor = 0.8
        starGlow.zPosition = -1
        
        // Position star elements as close to left border as possible
        let starIconRadius = self.starsCollectedIcon.size.width * 0.5 // Half width for radius
        let leftPadding: CGFloat = kDeviceTablet ? 8.0 : 6.0 // Minimal padding to avoid cutoff
        let starSectionX = leftPadding + starIconRadius
        let centerY = self.statusBarBackground.size.height / 2
        
        starGlow.position = CGPoint(x: starSectionX, y: centerY)
        self.starsCollectedIcon.position = CGPoint(x: starSectionX, y: centerY)
        
        // Collected stars label with modern typography
        self.starsCollectedLabel = GameFonts.shared.createLabel(string: String(collected), labelType: GameFonts.LabelType.statusBar)
        
        // Sleek text styling with modern grayscale
        self.starsCollectedLabel.fontColor = SKColor(white: 0.95, alpha: 1.0) // Pure white
        self.starsCollectedLabel.fontSize = kDeviceTablet ? 18 : 14
        self.starsCollectedLabel.horizontalAlignmentMode = .left
        
        let labelOffsetX = starSectionX + self.starsCollectedIcon.size.width * 1.5 + (kDeviceTablet ? 12.0 : 8.0) + (self.statusBarBackground.size.width * 0.1)
        self.starsCollectedLabel.position = CGPoint(x: labelOffsetX, y: centerY)
        
        // Add elements to container
        starContainer.addChild(starGlow)
        starContainer.addChild(self.starsCollectedIcon)
        starContainer.addChild(self.starsCollectedLabel)
        
        self.statusBarBackground.addChild(starContainer)
        
        // Smooth rotation animation with optimized timing
        self.starsCollectedIcon.run(
            SKAction.repeatForever(
                SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 6.0))) // Slower, more elegant rotation
    }
    
    fileprivate func setupStatusBarScore(score: Int) {
        // Create modern score section
        let scoreContainer = SKNode()
        let centerY = self.statusBarBackground.size.height / 2
        
        // Score value with prominent styling using grayscale
        self.scoreLabel = GameFonts.shared.createLabel(string: formatScore(score), labelType: GameFonts.LabelType.statusBar)
        self.scoreLabel.fontColor = SKColor(white: 1.0, alpha: 1.0) // Pure white for prominence
        self.scoreLabel.fontSize = kDeviceTablet ? 20 : 16
        self.scoreLabel.horizontalAlignmentMode = .right
        
        // Position score at right edge with padding
        let scoreX = self.statusBarBackground.size.width - (kDeviceTablet ? 25 : 20)
        self.scoreLabel.position = CGPoint(x: scoreX, y: centerY)
        
        // Add subtle glow effect to score using grayscale
        let scoreGlow = GameFonts.shared.createLabel(string: formatScore(score), labelType: GameFonts.LabelType.statusBar)
        scoreGlow.fontColor = SKColor(white: 0.7, alpha: 0.4) // Medium gray glow
        scoreGlow.fontSize = self.scoreLabel.fontSize
        scoreGlow.horizontalAlignmentMode = .right
        scoreGlow.position = self.scoreLabel.position
        scoreGlow.zPosition = -1
        
        // Add elements to container
        scoreContainer.addChild(scoreGlow)
        scoreContainer.addChild(self.scoreLabel)
        
        self.statusBarBackground.addChild(scoreContainer)
    }
    
    // MARK: - Helper Methods
    private func formatScore(_ score: Int) -> String {
        // Add thousand separators for better readability
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: score)) ?? "\(score)"
    }
    
    fileprivate func setupPauseButton() {
        // Scale button to fit within status bar height with some padding
        let statusBarHeight = self.statusBarBackground.size.height
        let maxButtonHeight = statusBarHeight * 0.7 // 70% of status bar height
        let originalButtonHeight = self.pauseButton.size.height
        let buttonScale = maxButtonHeight / originalButtonHeight
        self.pauseButton.setScale(buttonScale)
        
        // Position between player lives and score sections
        let centerY = self.statusBarBackground.size.height / 2
        let pauseButtonX = self.statusBarBackground.size.width * 0.75 // Between lives (0.4-0.65) and score (0.85+)
        self.pauseButton.position = CGPoint(x: pauseButtonX, y: centerY)
        self.pauseButton.zPosition = 10 // Well above everything else
        
        // Create 3D effect with multiple shadow layers
        create3DButtonEffect()
        
        // Add pronounced glow effect using grayscale
        let buttonGlow = SKSpriteNode(texture: self.pauseButton.texture)
        buttonGlow.size = CGSize(width: self.pauseButton.size.width * 1.4, 
                               height: self.pauseButton.size.height * 1.4)
        buttonGlow.alpha = 0.4
        buttonGlow.color = SKColor(white: 0.8, alpha: 1.0) // Light gray glow
        buttonGlow.colorBlendFactor = 0.9
        buttonGlow.zPosition = -1
        self.pauseButton.addChild(buttonGlow)
        
        // Add pulsing animation to make it more noticeable
        let pulse = SKAction.sequence([
            SKAction.scale(to: buttonScale * 1.1, duration: 1.5),
            SKAction.scale(to: buttonScale, duration: 1.5)
        ])
        self.pauseButton.run(SKAction.repeatForever(pulse))
        
        self.statusBarBackground.addChild(self.pauseButton)
    }
    
    private func create3DButtonEffect() {
        // Create 3D depth effect with shadow layers
        let shadowOffsets: [(x: CGFloat, y: CGFloat, alpha: CGFloat)] = [
            (-3, -3, 0.3), // Main shadow
            (-2, -2, 0.2), // Mid shadow  
            (-1, -1, 0.1)  // Light shadow
        ]
        
        for (index, offset) in shadowOffsets.enumerated() {
            let shadow = SKSpriteNode(texture: self.pauseButton.texture)
            shadow.size = self.pauseButton.size
            shadow.position = CGPoint(x: offset.x, y: offset.y)
            shadow.alpha = offset.alpha
            shadow.color = SKColor.black
            shadow.colorBlendFactor = 1.0
            shadow.zPosition = -10 - CGFloat(index)
            self.pauseButton.addChild(shadow)
        }
        
        // Add highlight on top-left for 3D effect using refined grayscale
        let highlight = SKSpriteNode(texture: self.pauseButton.texture)
        highlight.size = CGSize(width: self.pauseButton.size.width * 0.8, 
                              height: self.pauseButton.size.height * 0.8)
        highlight.position = CGPoint(x: 1, y: 1)
        highlight.alpha = 0.4
        highlight.color = SKColor(white: 1.0, alpha: 1.0) // Pure white highlight
        highlight.colorBlendFactor = 0.7
        highlight.zPosition = 1
        self.pauseButton.addChild(highlight)
    }
    
    // MARK: - Public Functions
    func updateScore(score: Int) {
        let formattedScore = formatScore(score)
        self.scoreLabel.text = formattedScore
        
        // Update glow effect if it exists
        if let scoreGlow = self.scoreLabel.parent?.children.first(where: { $0.zPosition == -1 }) as? SKLabelNode {
            scoreGlow.text = formattedScore
        }
    }
    
    func updateStarsCollected(collected: Int) {
        self.starsCollectedLabel.text = String(collected)
        
        self.starsCollectedIcon.run(self.animateBounce())
        self.scoreLabel.run(self.animateBounce())
    }
    
    func updateLives(lives: Int) {
        // Clear existing life sprites
        self.statusBarBackground.enumerateChildNodes(withName: SpriteName.PlayerLives) { node, _ in
            if let livesSprite = node as? SKSpriteNode {
                livesSprite.removeFromParent()
            }
        }
        
        // Create modern lives display in center area
        let centerY = self.statusBarBackground.size.height / 2
        let livesStartX = self.statusBarBackground.size.width * 0.4
        let spacing: CGFloat = kDeviceTablet ? 35 : 28
        
        for i in 0..<lives {
            let livesSprite = GameTextures.sharedInstance.spriteWithName(name: SpriteName.PlayerLives)
            // Scale ships 2x bigger to be more prominent in status bar
            let shipScale: CGFloat = kDeviceTablet ? 1.4 : 1.2
            livesSprite.setScale(shipScale)
            
            // Add subtle glow to life icons using grayscale
            let lifeGlow = GameTextures.sharedInstance.spriteWithName(name: SpriteName.PlayerLives)
            lifeGlow.setScale(shipScale * 1.2) // Slightly larger glow
            lifeGlow.alpha = 0.3
            lifeGlow.color = SKColor(white: 0.9, alpha: 1.0) // Light gray glow
            lifeGlow.colorBlendFactor = 0.6
            lifeGlow.zPosition = -1
            
            let xPosition = livesStartX + (spacing * CGFloat(i))
            livesSprite.position = CGPoint(x: xPosition, y: centerY)
            lifeGlow.position = CGPoint(x: xPosition, y: centerY)
            
            livesSprite.name = SpriteName.PlayerLives
            
            self.statusBarBackground.addChild(lifeGlow)
            self.statusBarBackground.addChild(livesSprite)
        }
    }
    
    // MARK: - Animations
    fileprivate func animateBounce() -> SKAction {
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.12)
        let scaleNormal = SKAction.scale(to: 1.0, duration: 0.12)
        let scaleSequence = SKAction.sequence([scaleUp, scaleNormal])
        
        return scaleSequence
    }
    
    // MARK: - Reset
    func reset() {
        // Reset all displays to initial values
        updateScore(score: 0)
        updateLives(lives: 3)
        updateStarsCollected(collected: 0)
        
        // Remove any active animations
        removeAllActions()
        
        // Reset pause button state
        pauseButton.removeAllActions()
        pauseButton.alpha = 1.0
        
        // Reset visual effects
        alpha = 1.0
        
        // Reset labels to initial states
        scoreLabel.removeAllActions()
        starsCollectedLabel.removeAllActions()
        
        // Reset background
        statusBarBackground.removeAllActions()
        statusBarBackground.alpha = 1.0
        
        // Ensure grayscale text colors are maintained
        scoreLabel.fontColor = SKColor(white: 1.0, alpha: 1.0)
        starsCollectedLabel.fontColor = SKColor(white: 0.95, alpha: 1.0)
    }
}
