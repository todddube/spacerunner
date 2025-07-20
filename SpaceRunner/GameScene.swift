//
//  GameScene.swift
//  SpaceRunner
//
//  Created by Todd Dube : 2025
//  Purpose: Modern game scene with reactive state management and iOS 18+ optimizations.
//

import SpriteKit
import OSLog
import Observation

@available(iOS 18.0, *)
@MainActor
final class GameScene: SKScene, @preconcurrency SKPhysicsContactDelegate {
    
    // MARK: - Game State
    @Observable
    final class GameState {
        enum Phase {
            case tutorial
            case running
            case paused
            case gameOver
        }
        
        var currentPhase: Phase = .tutorial
        var score: Int = 0
        var lives: Int = 3
        var starsCollected: Int = 0
        var isGameActive: Bool { currentPhase == .running }
    }
    
    // MARK: - Properties
    private(set) var gameState = GameState()
    private let gameSettings = GameSettings.shared
    private let audioManager = GameAudio.shared
    // private let accessibilityManager = AccessibilityManager.shared // TODO: Add AccessibilityManager to project
    
    private let gameNode = SKNode()
    private let interfaceNode = SKNode()
    private let background = Background()
    private let startButton = StartButton()
    private let player = Player()
    private let meteorController = MeteorController()
    private let starController = StarController()
    private var statusBar: StatusBar!
    
    private var lastUpdateTime: TimeInterval = 0.0
    private var frameCount: TimeInterval = 0.0
    
    private let logger = Logger(subsystem: "com.todddube.spacerunner", category: "GameScene")
    
    // MARK: - Notification Names
    private enum NotificationName {
        static let pauseGame = Notification.Name("PauseGame")
        static let resumeGame = Notification.Name("ResumeGame")
    }
    
    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(size: CGSize) {
        super.init(size: size)
    }
    
    override func didMove(to view: SKView) {
        Task {
            await setupScene()
        }
        setupNotifications()
        logger.info("GameScene initialized and moved to view")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        logger.info("GameScene deinitialized")
    }
    
    // MARK: - Setup
    private func setupScene() async {
        backgroundColor = .black
        setupPhysics()
        await setupGameNodes()
        setupInterface()
        setupAccessibility()
        
        // Initialize game state
        gameState.lives = player.lives
        gameState.score = player.score
        gameState.starsCollected = 0 // TODO: Track stars collected separately
        
        // Start tutorial phase
        setCurrentPhase(.tutorial)
    }
    
    private func setupPhysics() {
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
    }
    
    private func setupGameNodes() async {
        // Add main game node
        addChild(gameNode)
        gameNode.zPosition = GameLayer.Background
        
        // Setup background
        background.zPosition = GameLayer.Background
        gameNode.addChild(background)
        
        // Setup player
        player.position = CGPoint(x: kViewSize.width / 2, y: kViewSize.height * 0.15)
        player.zPosition = GameLayer.Player
        gameNode.addChild(player)
        
        // Setup controllers
        gameNode.addChild(meteorController)
        gameNode.addChild(starController)
        
        // Initialize audio
        audioManager.playBackgroundMusic()
    }
    
    private func setupInterface() {
        // Add interface node
        addChild(interfaceNode)
        interfaceNode.zPosition = GameLayer.Interface
        
        // Setup start button
        startButton.position = CGPoint(x: kViewSize.width / 2, y: kViewSize.height / 2)
        startButton.zPosition = GameLayer.Interface
        interfaceNode.addChild(startButton)
        
        // Setup status bar with proper initialization
        statusBar = StatusBar(lives: gameState.lives, score: gameState.score, stars: gameState.starsCollected)
        statusBar.position = CGPoint.zero // StatusBar handles its own positioning
        statusBar.zPosition = GameLayer.Interface
        interfaceNode.addChild(statusBar)
        
        // Debug logging
        // print("🎮 GameScene: Added StatusBar to interfaceNode")
        // print("🎮 GameScene: InterfaceNode position: \(interfaceNode.position), zPosition: \(interfaceNode.zPosition)")
        // print("🎮 GameScene: StatusBar position: \(statusBar.position), zPosition: \(statusBar.zPosition)")
        // print("🎮 GameScene: Scene size: \(size), kViewSize: \(kViewSize)")
    }
    
    private func setupAccessibility() {
        accessibilityLabel = "SpaceRunner Game Scene"
        isAccessibilityElement = false
        
        // Configure child element accessibility
        gameNode.accessibilityLabel = "Game World"
        interfaceNode.accessibilityLabel = "Game Interface"
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pauseGame),
            name: NotificationName.pauseGame,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(resumeGame),
            name: NotificationName.resumeGame,
            object: nil
        )
    }
    
    // MARK: - Game State Management
    private func setCurrentPhase(_ phase: GameState.Phase) {
        gameState.currentPhase = phase
        
        switch phase {
        case .tutorial:
            showTutorial()
        case .running:
            startGame()
        case .paused:
            pauseGameplay()
        case .gameOver:
            endGame()
        }
        
        logger.info("Game phase changed to: \(String(describing: phase))")
    }
    
    private func showTutorial() {
        startButton.isHidden = false
        statusBar.isHidden = true
        
        // Pause physics
        physicsWorld.speed = 0.0
        
        // Show tutorial elements
        player.disableMovement() // Start with movement disabled in tutorial
    }
    
    private func startGame() {
        startButton.isHidden = true
        statusBar.isHidden = false
        
        // Resume physics
        physicsWorld.speed = 1.0
        
        // Start gameplay
        player.enableMovement()
        meteorController.startSendingMeteors()
        starController.startSendingStars()
        
        // Update UI
        updateStatusBar()
    }
    
    private func pauseGameplay() {
        physicsWorld.speed = 0.0
        meteorController.stopSendingMetors()  // No pause method, use stop
        starController.stopSendingStars()     // No pause method, use stop
        audioManager.pauseBackgroundMusic()
    }
    
    private func endGame() {
        physicsWorld.speed = 0.0
        meteorController.stopSendingMetors()
        starController.stopSendingStars()
        
        // Update high scores
        gameSettings.updateBestScore(gameState.score)
        gameSettings.updateBestStars(gameState.starsCollected)
        
        // Show game over elements
        player.gameOver()
        meteorController.gameOver()
        starController.gameOver()
        
        // Transition to game over scene after delay
        let waitAction = SKAction.wait(forDuration: 2.0)
        let transitionAction = SKAction.run { [weak self] in
            self?.transitionToGameOver()
        }
        
        run(SKAction.sequence([waitAction, transitionAction]))
    }
    
    private func transitionToGameOver() {
        guard let view = view else { return }
        
        let gameOverScene = GameOverScene(size: size, score: gameState.score, stars: gameState.starsCollected, streak: 0)
        
        let transition = SKTransition.fade(with: .black, duration: 0.75)
        view.presentScene(gameOverScene, transition: transition)
        
        logger.info("Transitioned to game over scene")
    }
    
    // MARK: - Update Loop
    override func update(_ currentTime: TimeInterval) {
        guard gameState.isGameActive else { return }
        
        let deltaTime = calculateDeltaTime(currentTime)
        frameCount += deltaTime
        
        // Update game objects
        player.update()
        meteorController.update(delta: deltaTime)
        starController.update(delta: deltaTime)
        
        // Update game state
        updateGameState()
        updateStatusBar()
    }
    
    private func calculateDeltaTime(_ currentTime: TimeInterval) -> TimeInterval {
        let deltaTime = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
        lastUpdateTime = currentTime
        return min(deltaTime, 1.0/30.0) // Cap at 30 FPS minimum
    }
    
    private func updateGameState() {
        gameState.score = player.score
        gameState.lives = player.lives
        // starsCollected is tracked directly in gameState when stars are collected
        
        // Check for game over
        if player.lives <= 0 && gameState.currentPhase == .running {
            setCurrentPhase(.gameOver)
        }
    }
    
    private func updateStatusBar() {
        statusBar.updateScore(score: gameState.score)
        statusBar.updateLives(lives: gameState.lives)
        statusBar.updateStarsCollected(collected: gameState.starsCollected)
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        switch gameState.currentPhase {
        case .tutorial:
            handleTutorialTouch(at: location)
        case .running:
            handleGameplayTouch(at: location)
        case .paused, .gameOver:
            break
        }
    }
    
    private func handleTutorialTouch(at location: CGPoint) {
        if startButton.contains(location) {
            audioManager.playSoundEffect(.buttonTap)
            setCurrentPhase(.running)
        }
    }
    
    private func handleGameplayTouch(at location: CGPoint) {
        player.updateTargetLocation(newLocation: location)
    }
    
    // MARK: - Physics Contact
    func didBegin(_ contact: SKPhysicsContact) {
        let contactA = contact.bodyA.categoryBitMask
        let contactB = contact.bodyB.categoryBitMask
        
        // Player collision with meteor
        if (contactA == Contact.Player && contactB == Contact.Meteor) ||
           (contactA == Contact.Meteor && contactB == Contact.Player) {
            handlePlayerMeteorCollision(contact)
        }
        
        // Player collection of star
        if (contactA == Contact.Player && contactB == Contact.Star) ||
           (contactA == Contact.Star && contactB == Contact.Player) {
            handlePlayerStarCollection(contact)
        }
    }
    
    private func handlePlayerMeteorCollision(_ contact: SKPhysicsContact) {
        guard gameState.isGameActive else { return }
        
        let meteor = contact.bodyA.categoryBitMask == Contact.Meteor ? 
                     contact.bodyA.node : contact.bodyB.node
        
        if let meteorNode = meteor as? Meteor {
            player.hitMeteor()
            meteorNode.hitMeteor()
            audioManager.playSoundEffect(.explosion)
            
            logger.info("Player hit by meteor")
        }
    }
    
    private func handlePlayerStarCollection(_ contact: SKPhysicsContact) {
        guard gameState.isGameActive else { return }
        
        let star = contact.bodyA.categoryBitMask == Contact.Star ? 
                   contact.bodyA.node : contact.bodyB.node
        
        if let starNode = star as? Star {
            starNode.pickedUpStar()  // This handles the audio and removal
            gameState.starsCollected += 1
            player.pickedUpStar()     // Update player's star count
            
            logger.info("Star collected")
        }
    }
    
    // MARK: - Notification Handlers
    @objc private func pauseGame() {
        guard gameState.currentPhase == .running else { return }
        setCurrentPhase(.paused)
    }
    
    @objc private func resumeGame() {
        guard gameState.currentPhase == .paused else { return }
        setCurrentPhase(.running)
    }
    
    // MARK: - App Lifecycle
    func handleAppBackground() {
        if gameState.currentPhase == .running {
            setCurrentPhase(.paused)
        }
    }
    
    func handleAppForeground() {
        // Game will remain paused until user resumes
    }
}
