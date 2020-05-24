//
//  GameScene.swift
//  SpaceRunner
//
//  Created by Todd Dube on 3/19/16.
//  Copyright (c) 2020 Todd Dube. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - Private class enum
    fileprivate enum GameState:Int {
        case tutorial
        case running
        case paused
        case gameOver
    }
    
    // MARK: - Private class constants
    fileprivate let gameNode = SKNode()
    fileprivate let interfaceNode = SKNode()
    fileprivate let background = Background()
    fileprivate let startButton = StartButton()
    fileprivate let player = Player()
    fileprivate let meteorController = MeteorController()
    fileprivate let starController = StarController()
    
    // MARK: - Private class variables
    fileprivate var state = GameState.tutorial
    fileprivate var lastUpdateTime:TimeInterval = 0.0
    fileprivate var frameCount:TimeInterval = 0.0
    fileprivate var statusBar = StatusBar()
    
    
    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(size: CGSize) {
        super.init(size: size)
    }
    
    override func didMove(to view: SKView) {
        
        NotificationCenter.default.addObserver(self, selector: #selector(GameScene.pauseGame), name: NSNotification.Name(rawValue: "PauseGame"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(GameScene.resumeGame), name: NSNotification.Name(rawValue: "ResumeGame"), object: nil)
        self.setupGameScene()
    }
    
    // MARK: - Setup
    fileprivate func setupGameScene() {
        // set the background color to black
        self.backgroundColor = SKColor.black
        
        // Set up the physics for the world
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        // Create the physics body for the gameNode
        let screenBounds = CGRect(x: -self.player.size.width / 2, y: 0, width: kViewSize.width + self.player.size.width, height: kViewSize.height)
        self.gameNode.physicsBody = SKPhysicsBody(edgeLoopFrom: screenBounds)
        self.gameNode.physicsBody?.categoryBitMask = Contact.Scene
        
        // Add gameNode to the scene
        self.addChild(self.gameNode)
        
        // Add the background node to the game node
        self.gameNode.addChild(background)
        
        // Add the play button to the gameNode
        self.gameNode.addChild(self.startButton)
        
        // Add the meteor controller to the gameNode
        self.gameNode.addChild(self.meteorController)
        
        // Add the starController to the gameNode
        self.gameNode.addChild(self.starController)
        
        // Add the player to the gameNode
        self.gameNode.addChild(self.player)
        
        // Add the interfaceNode to the scene
        self.addChild(self.interfaceNode)
        
        // Add the statusBar to the InterfaceNode
        self.statusBar = StatusBar(lives: self.player.lives, score: self.player.score, stars: self.player.starsCollected)
        self.interfaceNode.addChild(self.statusBar)
        
    }
    
    // MARK: - Update
    override func update(_ currentTime: TimeInterval) {
        // Calc "delta"
        let delta = currentTime - self.lastUpdateTime
        self.lastUpdateTime = currentTime
        
        // Switch on GameState
        switch self.state {
            case GameState.tutorial:
                return
            
            case GameState.running:
                // check if the player has more than 0 lives
                if self.player.lives > 0 {
                    // manually run the update on the player
                    self.player.update()
                
                    // manually run the update on meteorController
                    self.meteorController.update(delta: delta)
                    
                    // manually run update on the StarController
                    self.starController.update(delta: delta)
                    
                    // increase frameCount by delta
                    self.frameCount += delta
                    
                    // if frameCount is greater than 1.0, approximately 1 second has passed
                    if self.frameCount >= 1.0 {
                        // increase the players score by 1 point
                        self.updateDistanceTick()
                        
                        // reset the frameCount to 0
                        self.frameCount = 0.0
                    }
                } else {
                    // the player is out of lives
                    self.switchToGameOver()
            }
            case GameState.paused:
                return
            
            case GameState.gameOver:
                return
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if self.state == GameState.tutorial || self.state == GameState.paused || self.state == GameState.gameOver {
            return
        } else {
            // Which body is not the player
            let other = contact.bodyA.categoryBitMask == Contact.Player ? contact.bodyB : contact.bodyA
            
            if other.categoryBitMask == Contact.Meteor {
                // Player is not immune
                if !self.player.immune {
                    
                    self.player.hitMeteor()
                    self.statusBar.updateLives(lives: self.player.lives)
                    
                    if let meteor = other.node as? Meteor {
                        meteor.hitMeteor()
                    }
                    
                    self.explodePlayer(self.player.position)
                    self.flashBackground()   // Run Flash Background
                    self.shakeScreen()       // shake the screen
                    
                } else {
                    // player is immune
                    return
                }
            }
            
            if other.categoryBitMask == Contact.Star {
                // update the players score
                self.player.pickedUpStar()
                
                // update the players score on the status bar
                self.statusBar.updateScore(score: self.player.score)
                
                // update the players star count on the status bar
                self.statusBar.updateStarsCollected(collected: self.player.starsCollected)
                
                if let star = other.node as? Star {
                    star.pickedUpStar()
                
                // star explode
                self.explodeStar(self.player.position)
                    
                }
            }
        }
    }
    
    // MARK: Touch Events
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch:UITouch = touches.first! as UITouch
        let touchLocation = touch.location(in: self)
        
        switch state {
            case GameState.tutorial:
                if self.startButton.contains(touchLocation) {
                    // Change the state to running
                    self.startButton.tapped()
                    self.switchToRunning()
                }
            
            // TODO: Pause while awaiting Start needs to be fixed
            // 05/01/16 - Commented this out as Pause w/ Start button waiting didnt work or make sense
//                if self.statusBar.pauseButton.containsPoint(touchLocation) {
//                    self.pauseButtonPressed()
//                }
            
            
            case GameState.running:
                if self.statusBar.pauseButton.contains(touchLocation) {
                    self.pauseButtonPressed()
                } else {
                    self.player.updateTargetLocation(newLocation: touchLocation)
            }
            
            case GameState.paused:
                if self.statusBar.pauseButton.contains(touchLocation) {
                    self.pauseButtonPressed()
                }
            
            case GameState.gameOver:
                return
        }
    }
    
    // MARK: - State Functions
    fileprivate func swithToTutorial() {
        // TODO: Need to setup some animations while in Tutorial mode. 
    }
    
    fileprivate func switchToRunning() {
        self.state = GameState.running
        
        // Enable Player Movement 
        self.player.enableMovement()
        
        // Move Player up to the StartButton location
        self.player.updateTargetLocation(newLocation: self.startButton.position)
        
        // Fade StartButton out and remove it from the scene
        self.startButton.fadeStartButton()
        
        // Start the background
        self.background.startBackgrond()
        
        // Start sending meteors
        self.meteorController.startSendingMeteors()
        
        // start sending stars
        self.starController.startSendingStars()
    }
    
    fileprivate func switchToPaused() {
        self.state = GameState.paused
    }
    
    // Was private but casued crashed because it couldnt find on resume this function.
    // public was changed by xcode to internal.
    @objc internal func switchToResume() {
        self.state = GameState.running
    }
    
    fileprivate func switchToGameOver() {
        self.state = GameState.gameOver
        
        // Disable Player movement
        self.player.disableMovement()
        
        // Run the gameOver function to check scores
        self.player.gameOver()
        
        // Run the gameOver function on the meteors
        self.meteorController.gameOver()
        
        // Run the gameOver function on the stars
        self.starController.gameOver()
        
        // Run the gameOver function on the backgrond
        self.background.gameOver()

        // Stop background
        self.background.stopBackground()
        
        // Stop sending meteors
        self.meteorController.stopSendingMetors()
        
        // stop sending stars
        self.starController.stopSendingStars()
        
        // load the GameOverScene after a 1.5 second delay
        self.run(SKAction.wait(forDuration: 1.5), completion: {
            self.loadGameOverScene()
        })
    }
    
    // MARK: - Pause Button Actions
    fileprivate func pauseButtonPressed() {
        self.statusBar.pauseButton.tapped()
        
        if self.statusBar.pauseButton.getPauseState() {
            // pause the gameNode
            self.gameNode.isPaused = true
            
            // set the state to paused
            self.switchToPaused()
            
            // pause the background music
            GameAudio.sharedInstance.pauseBackgroundMusic()
        } else {
            // resume the gameNode
            self.gameNode.isPaused = false
            
            // swtich state to running without doing the other init in switchToRunning()
            self.switchToResume()
            
            // resume the background music
            GameAudio.sharedInstance.resumeBackgroundMusic()
        }
    }
    
    // MARK: - Load Scene
    fileprivate func loadGameOverScene() {
        let gameOverScene = GameOverScene(size: kViewSize, score: self.player.score, stars: self.player.starsCollected, streak: self.player.highStreak)
//        let transition = SKTransition.fadeWithColor(SKColor.blackColor(), duration: 0.25)
        let transition = SKTransition.doorsCloseVertical(withDuration: 1.0)
        
        self.view?.presentScene(gameOverScene, transition: transition)
    }
    
    // MARK: - Scoring functions
    fileprivate func updateDistanceTick() {
        self.player.updatePlayerScore(score: 1)
        self.statusBar.updateScore(score: self.player.score)
    }
    
    // MARK: - NSNotifications functions
    @objc func pauseGame() {
        self.switchToPaused()
    }
    
    @objc func resumeGame() {
        // Run a timer that resumes the game after 1 second
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector (GameScene.switchToResume)    , userInfo:  nil, repeats:  false)
    }
    
    // MARK: - deinit 
    // best practice when using NSNotificationCenter - when GameScene exits we want it 
    // to "unregister" from notifications
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Animation Functions
    func flashBackground() {
        let colorFlash = SKAction.run({
            self.backgroundColor = Colors.colorFromRGB(rgbvalue: Colors.ScreenFlash)
            self.run(SKAction.wait(forDuration: 0.15), completion: {
                self.backgroundColor = Colors.colorFromRGB(rgbvalue: Colors.Background)
            })
        })
        self.run(colorFlash)
    }

    func explodeStar(_ pos: CGPoint) {
        let emitterNode = SKEmitterNode(fileNamed: SpriteName.ExplodeStar)
        // set emitterNode at the provide position
        emitterNode?.position = pos
        
        self.addChild(emitterNode!)
        
        // remove emitter after the explosion
        self.run(SKAction.wait(forDuration: 1.0), completion: {
            emitterNode?.removeFromParent()
        })
    }
    
    
    func explodePlayer(_ pos: CGPoint) {
        
        let emitterNode = SKEmitterNode(fileNamed: SpriteName.Explosion)
        // Set emitterNode at the provided position
        emitterNode?.position = pos
        
        self.addChild(emitterNode!)
        
        // Remove emitter after the explosion
        self.run(SKAction.wait(forDuration: 2.0), completion: {
            emitterNode?.removeFromParent()
        })
    }
    
    func shakeScreen() {
        let shake = SKAction.screenShakeWithNode(self.gameNode, amount: CGPoint(x: 20, y: 15), oscillations: 5, duration: 0.75)
        self.run(shake)
    }
}
