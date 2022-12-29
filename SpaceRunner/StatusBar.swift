//
//  StatusBar.swift
//  SpaceRunner
//
//  Created by Todd Dube on 3/23/16.
//  Copyright © 2020 Todd Dube. All rights reserved.
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
        
        self.setupStatusBar()
        self.setupStatusBarBackground()
        self.setupStatusBarScore(score: score)
        self.updateLives(lives: lives)
        self.setupStatusBarStarsCollected(collected: stars)
        self.setupPauseButton()
    }
    
    // MARK: - Setup
    fileprivate func setupStatusBar() {
        
    }
    
    fileprivate func setupStatusBarBackground() {
        // Make a CGRect that is as wide as the screen and 3% of the height of the screen
        let statusBarBackgroundSize = CGSize(width: kViewSize.width, height: kViewSize.height * 0.03)
    
        // Make an SKSpriteNode that is a dark gray color and the size of statusBarBackgroundSize
        self.statusBarBackground = SKSpriteNode(color: SKColor.darkGray, size: statusBarBackgroundSize)
        
        // Make the anchorPoint 0,0 so it is positioned using the lower left corner
        self.statusBarBackground.anchorPoint = CGPoint.zero
        
        // MARK: statusBarPostion
        // Position statusBarBackground on the left edge of the screen and 95% up the screen
        // Adjusted from .97 to .93 for notched phones
        // self.statusBarBackground.position = CGPoint(x: 0, y: kViewSize.height * 0.91)
        
        // Bottom of screen options testing dunno
        self.statusBarBackground.position = CGPoint(x: 0, y: kViewSize.height * 0.030)
        
        // Set the alpha to 75% opacity
        self.statusBarBackground.alpha = 0.75
        

        // Add statusBarBackground to the StatusBar node
        self.addChild(self.statusBarBackground)
    }
    
    fileprivate func setupStatusBarStarsCollected(collected: Int) {
        // Collected stars icon
        self.starsCollectedIcon = SKSpriteNode(texture: GameTextures.sharedInstance.textureWithName(name: SpriteName.StarIcon))
        
        let starOffsetX = self.statusBarBackground.size.width / 2 - self.starsCollectedIcon.size.width * 2
        let starOffsetY = self.statusBarBackground.size.height / 2
        
        // setup starIcon in status bar and scale
        self.starsCollectedIcon.position = CGPoint(x: starOffsetX, y: starOffsetY)
        self.starsCollectedIcon.setScale(0.70)
        
        // collected stars label
        self.starsCollectedLabel = GameFonts.sharedInstance.createLabel(string: String(collected), labelType: GameFonts.LabelType.statusBar)
        
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
        let scoreText = GameFonts.sharedInstance.createLabel(string: "Score: ", labelType: GameFonts.LabelType.statusBar)
        scoreText.position = CGPoint(x: self.statusBarBackground.size.width * 0.75, y: self.statusBarBackground.size.height / 2)
        self.statusBarBackground.addChild(scoreText)
        
        // Score Label
        self.scoreLabel = GameFonts.sharedInstance.createLabel(string: String(score), labelType: GameFonts.LabelType.statusBar)
        let offsetX = self.statusBarBackground.size.width * 0.90
        let offsetY = self.statusBarBackground.size.height / 2
        self.scoreLabel.position = CGPoint(x: offsetX, y: offsetY)
        self.statusBarBackground.addChild(self.scoreLabel)
    }
    
    fileprivate func setupPauseButton() {
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
}
