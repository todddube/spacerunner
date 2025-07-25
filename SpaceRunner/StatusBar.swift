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
        
        // Calculate safe area positioning accounting for notch/Dynamic Island
        let safeAreaTop = calculateSafeAreaTop(statusBarHeight: statusBarHeight)
        self.statusBarBackground.position = CGPoint(x: 0, y: safeAreaTop)
        
        // Add modern edge glow effect
        let glowEffect = createEdgeGlow(size: statusBarBackgroundSize)
        self.statusBarBackground.addChild(glowEffect)

        // Add statusBarBackground to the StatusBar node
        self.addChild(self.statusBarBackground)
    }
    
    private func calculateSafeAreaTop(statusBarHeight: CGFloat) -> CGFloat {
        if kDeviceTablet {
            // iPad - simple calculation, no notch
            return kViewSize.height - statusBarHeight - 20
        } else {
            // Try to get actual safe area from the scene's view
            var actualSafeAreaTop: CGFloat = 0
            
            if let scene = self.scene,
               let view = scene.view,
               let window = view.window {
                let safeAreaInsets = window.safeAreaInsets
                actualSafeAreaTop = safeAreaInsets.top
                print("📱 StatusBar: Actual safe area top: \(actualSafeAreaTop)")
            }
            
            // If we can't get actual safe area, fall back to device detection
            if actualSafeAreaTop == 0 {
                actualSafeAreaTop = detectSafeAreaFromDeviceType()
            }
            
            // Position StatusBar below the safe area with some padding
            let calculatedTop = kViewSize.height - actualSafeAreaTop - statusBarHeight - 8
            
            // Debug logging for safe area calculations
            print("📱 StatusBar: Using safe area top: \(actualSafeAreaTop), calculated position: \(calculatedTop)")
            
            return calculatedTop
        }
    }
    
    private func detectSafeAreaFromDeviceType() -> CGFloat {
        let screenHeight = kViewSize.height
        let screenWidth = kViewSize.width
        let aspectRatio = screenHeight / screenWidth
        
        // Safe area top insets for different iPhone models
        let safeAreaInset: CGFloat
        
        // iPhone 14 Pro Max, 15 Pro Max (Dynamic Island)
        if screenHeight >= 926 {
            safeAreaInset = 59
        }
        // iPhone 14 Pro, 15 Pro (Dynamic Island)
        else if screenHeight >= 852 {
            safeAreaInset = 54
        }
        // iPhone 12/13/14/15 series (Notch or Dynamic Island)
        else if aspectRatio > 2.1 {
            safeAreaInset = 47
        }
        // iPhone X/XS/11 Pro series (Notch)
        else if aspectRatio > 2.0 {
            safeAreaInset = 44
        }
        // iPhone 8 Plus and similar (No notch)
        else if screenHeight >= 736 {
            safeAreaInset = 20
        }
        // Standard iPhones (No notch)
        else {
            safeAreaInset = 20
        }
        
        print("📱 StatusBar: Device detection - Screen: \(screenWidth)x\(screenHeight), ratio: \(aspectRatio), inset: \(safeAreaInset)")
        
        return safeAreaInset
    }
    
    // MARK: - Modern Visual Effects
    private func createGradientBackground(size: CGSize) -> SKSpriteNode {
        // Create a dark space-themed background with subtle transparency
        let primaryColor = SKColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 0.92) // Deep space blue
        let background = SKSpriteNode(color: primaryColor, size: size)
        
        // Add subtle texture overlay for depth
        let textureOverlay = SKSpriteNode(color: SKColor(white: 1.0, alpha: 0.03), size: size)
        textureOverlay.anchorPoint = CGPoint.zero
        textureOverlay.blendMode = .add
        background.addChild(textureOverlay)
        
        return background
    }
    
    private func createEdgeGlow(size: CGSize) -> SKNode {
        let glowContainer = SKNode()
        
        // Top edge glow - cyan accent
        let topGlow = SKSpriteNode(color: SKColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.6), 
                                 size: CGSize(width: size.width, height: 1.5))
        topGlow.anchorPoint = CGPoint(x: 0, y: 0)
        topGlow.position = CGPoint(x: 0, y: size.height - 1.5)
        topGlow.blendMode = .add
        
        // Bottom edge glow - softer blue
        let bottomGlow = SKSpriteNode(color: SKColor(red: 0.2, green: 0.4, blue: 1.0, alpha: 0.4), 
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
        
        // Collected stars icon with font-matched sizing
        self.starsCollectedIcon = SKSpriteNode(texture: GameTextures.sharedInstance.textureWithName(name: SpriteName.StarIcon))
        self.starsCollectedIcon.setScale(kDeviceTablet ? 0.3 : 0.25) // Smaller to match font size
        
        // Add subtle glow to star icon
        let starGlow = SKSpriteNode(texture: GameTextures.sharedInstance.textureWithName(name: SpriteName.StarIcon))
        starGlow.setScale(kDeviceTablet ? 0.4 : 0.35)
        starGlow.alpha = 0.3
        starGlow.color = SKColor.cyan
        starGlow.colorBlendFactor = 0.8
        starGlow.zPosition = -1
        
        // Position star elements
        let starSectionX = self.statusBarBackground.size.width * 0.15
        let centerY = self.statusBarBackground.size.height / 2
        
        starGlow.position = CGPoint(x: starSectionX, y: centerY)
        self.starsCollectedIcon.position = CGPoint(x: starSectionX, y: centerY)
        
        // Collected stars label with modern typography
        self.starsCollectedLabel = GameFonts.shared.createLabel(string: String(collected), labelType: GameFonts.LabelType.statusBar)
        
        // Sleek text styling
        self.starsCollectedLabel.fontColor = SKColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0) // Cool white
        self.starsCollectedLabel.fontSize = kDeviceTablet ? 18 : 14
        self.starsCollectedLabel.horizontalAlignmentMode = .left
        
        let labelOffsetX = starSectionX + self.starsCollectedIcon.size.width * 0.7
        self.starsCollectedLabel.position = CGPoint(x: labelOffsetX, y: centerY)
        
        // Add elements to container
        starContainer.addChild(starGlow)
        starContainer.addChild(self.starsCollectedIcon)
        starContainer.addChild(self.starsCollectedLabel)
        
        self.statusBarBackground.addChild(starContainer)
        
        // Subtle rotation animation
        self.starsCollectedIcon.run(
            SKAction.repeatForever(
                SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 4.0)))
    }
    
    fileprivate func setupStatusBarScore(score: Int) {
        // Create modern score section
        let scoreContainer = SKNode()
        let centerY = self.statusBarBackground.size.height / 2
        
        // Score value with prominent styling
        self.scoreLabel = GameFonts.shared.createLabel(string: formatScore(score), labelType: GameFonts.LabelType.statusBar)
        self.scoreLabel.fontColor = SKColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 1.0) // Bright cyan
        self.scoreLabel.fontSize = kDeviceTablet ? 20 : 16
        self.scoreLabel.horizontalAlignmentMode = .right
        
        // Position score at right edge with padding
        let scoreX = self.statusBarBackground.size.width - (kDeviceTablet ? 25 : 20)
        self.scoreLabel.position = CGPoint(x: scoreX, y: centerY)
        
        // Add subtle glow effect to score
        let scoreGlow = GameFonts.shared.createLabel(string: formatScore(score), labelType: GameFonts.LabelType.statusBar)
        scoreGlow.fontColor = SKColor(red: 0.0, green: 0.6, blue: 0.8, alpha: 0.4)
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
        // Position pause button with modern spacing
        let buttonPadding: CGFloat = kDeviceTablet ? 15.0 : 12.0
        self.pauseButton.position = CGPoint(x: buttonPadding + self.pauseButton.size.width / 2, 
                                          y: self.statusBarBackground.position.y + self.statusBarBackground.size.height / 2)
        self.pauseButton.zPosition = 1 // Above status bar background
        
        // Add subtle glow to pause button
        let buttonGlow = SKSpriteNode(texture: self.pauseButton.texture)
        buttonGlow.size = CGSize(width: self.pauseButton.size.width * 1.2, 
                               height: self.pauseButton.size.height * 1.2)
        buttonGlow.alpha = 0.2
        buttonGlow.color = SKColor.cyan
        buttonGlow.colorBlendFactor = 0.8
        buttonGlow.zPosition = -1
        self.pauseButton.addChild(buttonGlow)
        
        self.addChild(self.pauseButton)
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
            livesSprite.setScale(kDeviceTablet ? 0.5 : 0.4) // Refined size
            
            // Add subtle glow to life icons
            let lifeGlow = GameTextures.sharedInstance.spriteWithName(name: SpriteName.PlayerLives)
            lifeGlow.setScale((kDeviceTablet ? 0.5 : 0.4) * 1.3)
            lifeGlow.alpha = 0.3
            lifeGlow.color = SKColor.green
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
        
        // Ensure white text colors are maintained
        scoreLabel.fontColor = SKColor.white
        starsCollectedLabel.fontColor = SKColor.white
    }
}
