//
//  StatusBar.swift
//  SpaceRunner
//
//  Created by Todd Dube : 2025
//  Purpose: In-game status bar displaying score, lives, collected stars, and pause button.
//

import Foundation
import SpriteKit

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
        // Calculate safe status bar height - larger for better visibility
        let statusBarHeight = max(kViewSize.height * 0.06, 35.0) // At least 44pt for touch targets
        let statusBarBackgroundSize = CGSize(width: kViewSize.width, height: statusBarHeight)
    
        // Use a highly visible background that stands out dramatically
        let backgroundColor = SKColor.systemGray.withAlphaComponent(0.80)
        self.statusBarBackground = SKSpriteNode(color: backgroundColor, size: statusBarBackgroundSize)
        
        // Add a bright border for maximum visibility
        let borderNode = SKShapeNode(rect: CGRect(origin: CGPoint.zero, size: statusBarBackgroundSize))
        borderNode.strokeColor = SKColor.darkGray
        borderNode.lineWidth = 1.0
        borderNode.fillColor = SKColor.clear
        borderNode.zPosition = 1
        
        // Add a subtle border for better definition
        self.statusBarBackground.physicsBody = nil
        
        // Make the anchorPoint 0,0 so it is positioned using the lower left corner
        self.statusBarBackground.anchorPoint = CGPoint.zero
        
        // Calculate safe area positioning - adjust for different device types
        let safeAreaTop: CGFloat
        if kDeviceTablet {
            // iPad positioning
            safeAreaTop = kViewSize.height * 0.96 - statusBarHeight
        } else {
            // iPhone positioning - account for notch/Dynamic Island
            safeAreaTop = kViewSize.height * 0.94 - statusBarHeight
        }
        
        self.statusBarBackground.position = CGPoint(x: 0, y: safeAreaTop)
        
        // Full opacity for better visibility
        self.statusBarBackground.alpha = 1.0
        
        // Add the bright border to background
        self.statusBarBackground.addChild(borderNode)
        
        // Add a subtle drop shadow effect using a second node
        let shadowNode = SKSpriteNode(color: SKColor.gray.withAlphaComponent(0.5), size: statusBarBackgroundSize)
        shadowNode.anchorPoint = CGPoint.zero
        shadowNode.position = CGPoint(x: 4, y: -4) // Larger offset for more visible shadow
        shadowNode.zPosition = -1
        self.statusBarBackground.addChild(shadowNode)

        // Add statusBarBackground to the StatusBar node
        self.addChild(self.statusBarBackground)
        
        // Debug logging
        // print("🔥 StatusBar: Created background at position \(self.statusBarBackground.position) with size \(statusBarBackgroundSize)")
        // print("🔥 StatusBar: Safe area top calculated as \(safeAreaTop)")
    }
    
    fileprivate func setupStatusBarStarsCollected(collected: Int) {
        // Collected stars icon
        self.starsCollectedIcon = SKSpriteNode(texture: GameTextures.sharedInstance.textureWithName(name: SpriteName.StarIcon))
        
        let starOffsetX = self.statusBarBackground.size.width / 2 - self.starsCollectedIcon.size.width
        let starOffsetY = self.statusBarBackground.size.height / 2
        
        // setup starIcon in status bar and scale
        self.starsCollectedIcon.position = CGPoint(x: starOffsetX, y: starOffsetY)
        self.starsCollectedIcon.setScale(1.0)
        
        // collected stars label
        self.starsCollectedLabel = GameFonts.shared.createLabel(string: String(collected), labelType: GameFonts.LabelType.statusBar)
        
        // Use bright white color for maximum contrast
        self.starsCollectedLabel.fontColor = SKColor.white
        self.starsCollectedLabel.fontSize = self.starsCollectedLabel.fontSize * 1.25 // Make text larger
        
        let labelOffsetX = self.statusBarBackground.size.width / 2
        let labelOffsetY = self.statusBarBackground.size.height / 2
        
        self.starsCollectedLabel.position = CGPoint(x: labelOffsetX, y: labelOffsetY)
        
        self.statusBarBackground.addChild(self.starsCollectedIcon)
        self.statusBarBackground.addChild(self.starsCollectedLabel)
        
        // Rotate the starsCollectedIcon forever
        self.starsCollectedIcon.run(
            SKAction.repeatForever(
                SKAction.rotate(byAngle: 5.0, duration: 1.5)))
        
    }
    
    fileprivate func setupStatusBarScore(score: Int) {
        // Static Label
        let scoreText = GameFonts.shared.createLabel(string: "Score: ", labelType: GameFonts.LabelType.statusBar)
        scoreText.fontColor = SKColor.white
        scoreText.fontSize = scoreText.fontSize * 0.75 // Make text larger
        scoreText.position = CGPoint(x: self.statusBarBackground.size.width * 0.75, y: self.statusBarBackground.size.height / 2)
        self.statusBarBackground.addChild(scoreText)
        
        // Score Label
        self.scoreLabel = GameFonts.shared.createLabel(string: String(score), labelType: GameFonts.LabelType.statusBar)
        self.scoreLabel.fontColor = SKColor.white
        self.scoreLabel.fontSize = self.scoreLabel.fontSize * 0.75 // Make text larger
        let offsetX = self.statusBarBackground.size.width * 0.90
        let offsetY = self.statusBarBackground.size.height / 2
        self.scoreLabel.position = CGPoint(x: offsetX, y: offsetY)
        self.statusBarBackground.addChild(self.scoreLabel)
        
        // Debug logging
        print("🔥 StatusBar: Added score labels at positions - scoreText: \(scoreText.position), scoreLabel: \(self.scoreLabel.position)")
    }
    
    fileprivate func setupPauseButton() {
        // Position pause button in the top-left corner of the status bar
        let buttonPadding: CGFloat = 8.0
        self.pauseButton.position = CGPoint(x: buttonPadding + self.pauseButton.size.width / 2, 
                                          y: self.statusBarBackground.position.y + self.statusBarBackground.size.height / 2)
        self.pauseButton.zPosition = 1 // Above status bar background
        self.addChild(self.pauseButton)
    }
    
    // MARK: - Public Functions
    func updateScore(score: Int) {
        self.scoreLabel.text = String(score)
    }
    
    func updateStarsCollected(collected: Int) {
        self.starsCollectedLabel.text = String(collected)
        
        self.starsCollectedIcon.run(self.animateBounce())
        self.scoreLabel.run(self.animateBounce())
    }
    
    func updateLives(lives: Int) {
        // First Clear all of the sprites
        self.statusBarBackground.enumerateChildNodes(withName: SpriteName.PlayerLives) { node, _ in
            if let livesSprite = node as? SKSpriteNode {
                livesSprite.removeFromParent()
            }
        }
        
        // Get the X and Y points where we should draw the sprites
        var offsetX = CGFloat()
        let offsetY = self.statusBarBackground.size.height / 2
        
        // Redraw the sprites
        for i in 0..<lives {
            let livesSprite = GameTextures.sharedInstance.spriteWithName(name: SpriteName.PlayerLives)
            offsetX = livesSprite.size.width + livesSprite.size.width * 1.5 * CGFloat(i)
            livesSprite.position = CGPoint(x: offsetX, y: offsetY)
            livesSprite.name = SpriteName.PlayerLives
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
