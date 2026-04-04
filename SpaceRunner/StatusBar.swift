//
//  StatusBar.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Persistent heads-up display rendered at the bottom of the gameplay screen.
//  Shows the player's current score, remaining lives, stars collected, and the
//  pause/resume toggle button in a compact dark glass strip.
//
//  RESPONSIBILITIES
//  - setupStatusBarBackground()     — create the dark glass background bar sized to
//      kViewSize.width, respecting device safe-area bottom insets
//  - setupStatusBarScore(score:)    — render score label at the right edge of the bar
//  - setupStatusBarStarsCollected() — render rotating star icon + count at left edge
//  - updateLives(lives:)            — rebuild life-icon row in the centre of the bar;
//      icons are sized proportionally to bar height (60 %) for any device
//  - setupPauseButton()             — embed and scale the PauseButton to 62 % of bar height
//  - updateScore(score:)            — refresh score label text in real time
//  - updateStarsCollected(…)        — refresh star count + animate bounce
//  - reset()                        — restore all displays to initial game values
//  - calculateBottomPosition()      — uses window.safeAreaInsets for precise placement
//  - Glass/animation extensions in StatusBar+GlassEffect.swift
//

import Foundation
import SpriteKit
import UIKit

class StatusBar: SKNode {
    
    // MARK: - Private class variables
    var statusBarBackground = SKSpriteNode()
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
        let starContainer = SKNode()
        let barHeight = self.statusBarBackground.size.height
        let centerY = barHeight / 2
        
        // Icon scaled to 55% of bar height so it fits comfortably inside the bar
        let iconHeight = barHeight * 0.55
        self.starsCollectedIcon = SKSpriteNode(texture: GameTextures.sharedInstance.textureWithName(name: SpriteName.StarIcon))
        let iconScale = iconHeight / self.starsCollectedIcon.size.height
        self.starsCollectedIcon.setScale(iconScale)
        
        // Subtle glow slightly larger than icon
        let starGlow = SKSpriteNode(texture: GameTextures.sharedInstance.textureWithName(name: SpriteName.StarIcon))
        starGlow.setScale(iconScale * 1.25)
        starGlow.alpha = 0.25
        starGlow.color = SKColor(white: 0.85, alpha: 1.0)
        starGlow.colorBlendFactor = 0.7
        starGlow.zPosition = -1
        
        let leftPadding: CGFloat = kDeviceTablet ? 10.0 : 8.0
        let iconRadius = self.starsCollectedIcon.size.width * 0.5
        let starSectionX = leftPadding + iconRadius
        
        starGlow.position = CGPoint(x: starSectionX, y: centerY)
        self.starsCollectedIcon.position = CGPoint(x: starSectionX, y: centerY)
        
        // Stars count label
        self.starsCollectedLabel = GameFonts.shared.createLabel(string: String(collected), labelType: GameFonts.LabelType.statusBar)
        self.starsCollectedLabel.fontColor = SKColor(white: 0.95, alpha: 1.0)
        self.starsCollectedLabel.fontSize = kDeviceTablet ? 16 : 13
        self.starsCollectedLabel.horizontalAlignmentMode = .left
        
        // Place label immediately right of icon with a small gap
        let labelX = starSectionX + iconRadius + (kDeviceTablet ? 6.0 : 4.0)
        self.starsCollectedLabel.position = CGPoint(x: labelX, y: centerY)
        
        starContainer.addChild(starGlow)
        starContainer.addChild(self.starsCollectedIcon)
        starContainer.addChild(self.starsCollectedLabel)
        
        self.statusBarBackground.addChild(starContainer)
        
        // Slow, elegant rotation
        self.starsCollectedIcon.run(
            SKAction.repeatForever(
                SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 6.0)))
    }
    
    fileprivate func setupStatusBarScore(score: Int) {
        let scoreContainer = SKNode()
        let centerY = self.statusBarBackground.size.height / 2
        
        // Score label — size tied to bar height for consistent proportions
        let fontSize: CGFloat = kDeviceTablet ? 18 : 14
        self.scoreLabel = GameFonts.shared.createLabel(string: formatScore(score), labelType: GameFonts.LabelType.statusBar)
        self.scoreLabel.fontColor = SKColor(white: 1.0, alpha: 1.0)
        self.scoreLabel.fontSize = fontSize
        self.scoreLabel.horizontalAlignmentMode = .right
        
        let rightPadding: CGFloat = kDeviceTablet ? 18 : 14
        let scoreX = self.statusBarBackground.size.width - rightPadding
        self.scoreLabel.position = CGPoint(x: scoreX, y: centerY)
        
        // Subtle glow copy
        let scoreGlow = GameFonts.shared.createLabel(string: formatScore(score), labelType: GameFonts.LabelType.statusBar)
        scoreGlow.fontColor = SKColor(white: 0.7, alpha: 0.35)
        scoreGlow.fontSize = fontSize
        scoreGlow.horizontalAlignmentMode = .right
        scoreGlow.position = self.scoreLabel.position
        scoreGlow.zPosition = -1
        
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
        let barHeight = self.statusBarBackground.size.height
        // Scale to 62% of bar height — readable without being oversized
        let desiredHeight = barHeight * 0.62
        let buttonScale = desiredHeight / self.pauseButton.size.height
        self.pauseButton.setScale(buttonScale)
        
        let centerY = barHeight / 2
        // Place in the right quarter of the bar, clear of lives and score
        let pauseButtonX = self.statusBarBackground.size.width * 0.76
        self.pauseButton.position = CGPoint(x: pauseButtonX, y: centerY)
        self.pauseButton.zPosition = 10
        
        // Single drop-shadow for depth without visual clutter
        let shadow = SKSpriteNode(texture: self.pauseButton.texture)
        shadow.size = self.pauseButton.size
        shadow.position = CGPoint(x: -1.5, y: -1.5)
        shadow.alpha = 0.25
        shadow.color = SKColor.black
        shadow.colorBlendFactor = 1.0
        shadow.zPosition = -1
        self.pauseButton.addChild(shadow)
        
        // Subtle ambient glow
        let buttonGlow = SKSpriteNode(texture: self.pauseButton.texture)
        buttonGlow.size = CGSize(width: self.pauseButton.size.width * 1.25,
                                 height: self.pauseButton.size.height * 1.25)
        buttonGlow.alpha = 0.18
        buttonGlow.color = SKColor(white: 0.9, alpha: 1.0)
        buttonGlow.colorBlendFactor = 0.8
        buttonGlow.zPosition = -2
        self.pauseButton.addChild(buttonGlow)
        
        self.statusBarBackground.addChild(self.pauseButton)
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
        
        // Lives displayed centered in the middle third of the bar
        let barHeight = self.statusBarBackground.size.height
        let centerY = barHeight / 2
        
        // Scale each life icon to 60% of the bar height
        let sampleSprite = GameTextures.sharedInstance.spriteWithName(name: SpriteName.PlayerLives)
        let desiredIconHeight = barHeight * 0.60
        let shipScale = desiredIconHeight / sampleSprite.size.height
        let iconWidth = sampleSprite.size.width * shipScale
        
        let spacing: CGFloat = iconWidth * 1.3
        let livesStartX = self.statusBarBackground.size.width * 0.42
        
        for i in 0..<lives {
            let livesSprite = GameTextures.sharedInstance.spriteWithName(name: SpriteName.PlayerLives)
            livesSprite.setScale(shipScale)
            
            // Subtle glow layer
            let lifeGlow = GameTextures.sharedInstance.spriteWithName(name: SpriteName.PlayerLives)
            lifeGlow.setScale(shipScale * 1.2)
            lifeGlow.alpha = 0.25
            lifeGlow.color = SKColor(white: 0.9, alpha: 1.0)
            lifeGlow.colorBlendFactor = 0.5
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
