//
//  GameMenuScene
//  SpaceRunner
//
//  Created by Todd Dube : 2025
//  Purpose: Alternative game menu scene implementation with score display functionality.
//

import Foundation
import SpriteKit

class GameMenuScene: SKScene {
    
    // MAR: - Private class constants
    fileprivate let background = Background()
    fileprivate let retryButton = RetryButton()
    fileprivate let gameOverTitle = GameOverTitle()
    
    // MARK: - Private class variables
    fileprivate var sceneLabel = SKLabelNode()
    fileprivate var scoreBoard = ScoreBoard()
    
    // MARK: - Private convience constants
    fileprivate let fonts = GameFonts.sharedInstance
    fileprivate let fontType = GameFonts.LabelType.statusBar
    
    // MARK: - Init 
    required init?( coder aDecoder: NSCoder) {
        super.init( coder: aDecoder)
    }
    
    override init(size: CGSize) {
        super.init(size: size)
    }
    
    convenience init(size: CGSize, score: Int, stars: Int, streak: Int) {
        self.init(size: size)
        
        self.setupScoreBoard(score: score, stars: stars, streak: streak)
    }
    
    override func didMove( to view: SKView) {
        self.setupGameOverScene()
    }
    
    // MARK: - Setup 
    
    fileprivate func setupGameOverScene() {
        // Set the background color to Black 
        self.backgroundColor = Colors.colorFromRGB(rgbvalue: Colors.Background)
        self.addChild(self.background)
        self.addChild(self.retryButton)
        self.addChild(self.gameOverTitle)
        
        
        // Add Author / Copyright Information
        let authorLabel = fonts.createLabel(string: "Copyright 2023 - Todd Dube", labelType: fontType)
        
        authorLabel.position = CGPoint(x: kViewSize.width * 0.05, y: kViewSize.height * 0.05)

        
        self.addChild(authorLabel)

    }
    
    fileprivate func setupScoreBoard(score: Int, stars: Int, streak: Int) {
        // Retrieve the best score, starts, and streak
        let bestScore = GameSettings.shared.bestScore
        let bestStars = GameSettings.shared.bestStars
        let bestStreak = GameSettings.shared.bestStreak
    
        self.scoreBoard = ScoreBoard(score: score, bestScore: bestScore, streak: streak, bestStreak: bestStreak, stars: stars, bestStars: bestStars)
        
        self.addChild(self.scoreBoard)
    }
    
    // MARK: - Update
    override func update(_ currentTime: TimeInterval) {
        
    }
    
    // MARK: Touch Events
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch:UITouch = touches.first! as UITouch
        let touchLocation = touch.location(in: self)
        
        if self.retryButton.contains(touchLocation) {
            if kDebug {
                print("Game Over Scene: Retry Button Pressed")
            }
            
            self.retryButton.tapped()

            self.loadGameScene()
        }
    }
    
    // MARK: - Load Scene Menu
    fileprivate func loadMenuScene() {
        let menuScene = MenuScene(size: kViewSize)
        let transition = SKTransition.fade(with: SKColor.black, duration: 0.25)
        self.view?.presentScene(menuScene, transition: transition)
    }
    
    fileprivate func loadGameScene() {
        let gameScene = GameScene(size: kViewSize)
        let transition = SKTransition.fade(with: SKColor.black, duration: 0.25)
        self.view?.presentScene(gameScene, transition: transition)
    }
}
