//
//  GameOverScene.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  End-of-run screen shown after the player's ship is destroyed. Presents the
//  animated GameOverTitle, a ScoreBoard with current-vs-best stats, the
//  RetryButton, and a copyright label positioned above the safe-area bottom.
//
//  RESPONSIBILITIES
//  - setupGameOverScene()    — add background, title, retry button, author label
//  - setupScoreBoard(…)      — fetch best values from GameSettings and build the
//      ScoreBoard node with current run data
//  - touchesBegan(…)         — detect RetryButton tap and call loadGameScene()
//  - loadGameScene()         — push a fresh GameScene with a short fade transition
//  - loadMenuScene()         — return to MenuScene (currently unused, available
//      for a future "back to menu" button)
//

import Foundation
import SpriteKit

class GameOverScene: SKScene {
    
    // MAR: - Private class constants
    fileprivate let background = Background()
    fileprivate let retryButton = RetryButton()
    fileprivate let gameOverTitle = GameOverTitle()
    
    // MARK: - Private class variables
    fileprivate var sceneLabel = SKLabelNode()
    fileprivate var scoreBoard = ScoreBoard()
    
    // MARK: - Private convience constants
    fileprivate let fonts = GameFonts.shared
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
        
        
        // Add Author / Copyright Information above safe area
        let authorLabel = fonts.createLabel(string: UIText.AuthorLabel, labelType: fontType)
        
        authorLabel.horizontalAlignmentMode = .center
        let safeBottom: CGFloat = {
            if let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }) {
                return window.safeAreaInsets.bottom
            }
            return kDeviceTablet ? 10 : 20
        }()
        authorLabel.position = CGPoint(x: kViewSize.width * 0.5, y: safeBottom + 20)

        
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
