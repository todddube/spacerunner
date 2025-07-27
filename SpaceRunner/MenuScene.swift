//
//  MenuScene.swift
//  SpaceRunner
//
//  Created by Todd Dube : 2025
//  Purpose: Main menu scene with title, play button, and author information.
//

import Foundation
import SpriteKit

class MenuScene:SKScene {
    // MARK: - Private class variables
    private var sceneLabel = SKLabelNode()
    
    // MARK: - Private convience constants
    fileprivate let fonts = GameFonts.shared
    fileprivate let fontType = GameFonts.LabelType.statusBar

    
    
    // MARK: - Private class constants
    fileprivate let background = Background()
    fileprivate let playButton = PlayButton()
    fileprivate let gameTitle = GameTitle()
    fileprivate let gameTitleShip = GameTitleShip()
    
    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(size:CGSize) {
        super.init(size: size)
    }
    
    override func didMove(to view: SKView) {
        GameAudio.shared.playBackgroundMusic()
        self.setupMenuScene()
    }
    
    // MARK: - Setup
    fileprivate func setupMenuScene() {
        // Set the background color to black
        self.backgroundColor = Colors.colorFromRGB(rgbvalue: Colors.Background)
        self.addChild(self.background)
        self.addChild(self.playButton)
        self.addChild(self.gameTitle)
        self.addChild(self.gameTitleShip)
        
        // Add Author / Copyright Information / Version and Build (moved to bottom)
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        let versionLabel = fonts.createLabel(string: "v\(appVersion).\(buildNumber)", labelType: GameFonts.LabelType.statusBar)
        let authorLabel = fonts.createLabel(string: "Created by Todd Dube", labelType: GameFonts.LabelType.statusBar)
        
        // Center align the text horizontally
        authorLabel.horizontalAlignmentMode = .center
        versionLabel.horizontalAlignmentMode = .center
        
        // Position labels at bottom center with proper spacing
        authorLabel.position = CGPoint(x: kViewSize.width * 0.50, y: 45)
        versionLabel.position = CGPoint(x: kViewSize.width * 0.50, y: 20)
        
        // Set initial state for animation (fade in from bottom)
        authorLabel.alpha = 0.0
        versionLabel.alpha = 0.0
        
        self.addChild(authorLabel)
        self.addChild(versionLabel)
        
        // Animate the bottom labels with delay
        self.animateBottomLabels(authorLabel: authorLabel, versionLabel: versionLabel)
        
        // Rotate the gameTitleShip forever with smooth continuous rotation
        self.gameTitleShip.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 8.0)), withKey: "mainRotation")
        

    }
    
    // MARK: - Animations
    fileprivate func animateBottomLabels(authorLabel: SKLabelNode, versionLabel: SKLabelNode) {
        // Author label animation - fade in with slight upward movement
        let authorDelay = SKAction.wait(forDuration: 2.0)
        let authorMoveUp = SKAction.moveBy(x: 0, y: 10, duration: 0.8)
        let authorFadeIn = SKAction.fadeAlpha(to: 0.7, duration: 0.8)
        let authorBounce = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2)
        ])
        let authorAnimation = SKAction.group([authorMoveUp, authorFadeIn, authorBounce])
        let authorSequence = SKAction.sequence([authorDelay, authorAnimation])
        
        // Version label animation - fade in with slight delay after author
        let versionDelay = SKAction.wait(forDuration: 2.5)
        let versionMoveUp = SKAction.moveBy(x: 0, y: 8, duration: 0.6)
        let versionFadeIn = SKAction.fadeAlpha(to: 0.6, duration: 0.6)
        let versionBounce = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.15),
            SKAction.scale(to: 1.0, duration: 0.15)
        ])
        let versionAnimation = SKAction.group([versionMoveUp, versionFadeIn, versionBounce])
        let versionSequence = SKAction.sequence([versionDelay, versionAnimation])
        
        // Add subtle breathing animation to keep labels alive
        let breathe = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.4, duration: 3.0),
            SKAction.fadeAlpha(to: 0.7, duration: 3.0)
        ])
        let versionBreathe = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 4.0),
            SKAction.fadeAlpha(to: 0.6, duration: 4.0)
        ])
        
        // Run animations
        authorLabel.run(authorSequence) {
            authorLabel.run(SKAction.repeatForever(breathe))
        }
        
        versionLabel.run(versionSequence) {
            versionLabel.run(SKAction.repeatForever(versionBreathe))
        }
    }
    
    // MARK: - Update
    override func update(_ currentTime: TimeInterval) {
    }
    
    // MARK: - Touch Event
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch:UITouch = touches.first! as UITouch
        let touchLocation = touch.location(in: self)
        
        if self.playButton.contains(touchLocation) {

            self.playButton.tapped()
        
            self.loadGameScene()
        }
    }
    
    // MARK: - Load Scene
    fileprivate func loadGameScene() {
        let gameScene = GameScene(size: kViewSize)
        let transition = SKTransition.fade(with: SKColor.black, duration: 1.0)
        
        self.view?.presentScene(gameScene, transition: transition)
    }
}
