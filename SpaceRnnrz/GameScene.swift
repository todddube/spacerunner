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
import SwiftUI

// MARK: - Modern Error Handling
enum GameError: LocalizedError, Sendable {
    case initializationFailed(String)
    case invalidCollisionObject
    case audioInitializationFailed
    case stateTransitionFailed(from: String, to: String)
    
    var errorDescription: String? {
        switch self {
        case .initializationFailed(let reason):
            return "Game initialization failed: \(reason)"
        case .invalidCollisionObject:
            return "Invalid collision object detected"
        case .audioInitializationFailed:
            return "Audio system initialization failed"
        case .stateTransitionFailed(let from, let to):
            return "Invalid state transition from \(from) to \(to)"
        }
    }
}

@available(iOS 18.0, *)
@MainActor
final class GameScene: SKScene, SKPhysicsContactDelegate, Sendable {
    
    // MARK: - Game State
    @Observable
    @MainActor
    final class GameState: Sendable {
        enum Phase: Sendable {
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
        
        // Modern state validation
        func isValidTransition(to newPhase: Phase) -> Bool {
            switch (currentPhase, newPhase) {
            case (.tutorial, .running), (.running, .paused), (.paused, .running), (.running, .gameOver):
                return true
            default:
                return false
            }
        }
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
    
    // Modern structured logging
    private let logger = Logger(subsystem: "com.todddube.spacernnrz", category: "GameScene")
    
    // iOS 18+ Task management
    private var gameLoopTask: Task<Void, Never>?
    private var setupTask: Task<Void, Never>?
    
    // MARK: - Modern Notification Names
    private enum GameNotification: String, CaseIterable, Sendable {
        case pauseGame = "com.todddube.spacernnrz.pauseGame"
        case resumeGame = "com.todddube.spacernnrz.resumeGame"
        case gameStateChanged = "com.todddube.spacernnrz.gameStateChanged"
        
        var notificationName: Notification.Name {
            Notification.Name(rawValue)
        }
    }
    
    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(size: CGSize) {
        super.init(size: size)
    }
    
    override func didMove(to view: SKView) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            await self.setupScene()
            self.setupNotifications()
            self.logger.info("GameScene initialized and moved to view")
        }
    }
    
    deinit {
        // Cancel any running tasks
        gameLoopTask?.cancel()
        setupTask?.cancel()
        
        // Clean up notifications
        NotificationCenter.default.removeObserver(self)
        
        logger.info("GameScene deinitialized with proper cleanup")
    }
    
    // MARK: - Setup
    private func setupScene() async {
        do {
            backgroundColor = .black
            setupPhysics()
            
            try await setupGameNodes()
            setupInterface()
            setupAccessibility()
            
            // Initialize game state with observation
            await MainActor.run {
                gameState.lives = player.lives
                gameState.score = player.score
                gameState.starsCollected = 0
            }
            
            // Start tutorial phase
            setCurrentPhase(.tutorial)
            
            logger.info("GameScene setup completed successfully")
        } catch {
            logger.error("Failed to setup GameScene: \(error.localizedDescription)")
        }
    }
    
    private func setupPhysics() {
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
    }
    
    private func setupGameNodes() async throws {
        // Add main game node
        addChild(gameNode)
        gameNode.zPosition = GameLayer.Background
        
        // Setup background
        background.zPosition = GameLayer.Background
        gameNode.addChild(background)
        
        // Setup player with error handling
        player.position = CGPoint(x: kViewSize.width / 2, y: kViewSize.height * 0.15)
        player.zPosition = GameLayer.Player
        gameNode.addChild(player)
        
        // Setup controllers
        gameNode.addChild(meteorController)
        gameNode.addChild(starController)
        
        // Initialize audio asynchronously
        await audioManager.initializeAudio()
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
        // Modern notification observation with structured concurrency
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            for await _ in NotificationCenter.default.notifications(named: GameNotification.pauseGame.notificationName) {
                await self.handlePauseNotification()
            }
        }
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            for await _ in NotificationCenter.default.notifications(named: GameNotification.resumeGame.notificationName) {
                await self.handleResumeNotification()
            }
        }
    }
    
    @MainActor
    private func handlePauseNotification() async {
        guard gameState.currentPhase == .running else { return }
        setCurrentPhase(.paused)
    }
    
    @MainActor
    private func handleResumeNotification() async {
        guard gameState.currentPhase == .paused else { return }
        setCurrentPhase(.running)
    }
    
    // MARK: - Modern Game State Management
    @MainActor
    private func setCurrentPhase(_ phase: GameState.Phase) {
<<<<<<< HEAD:SpaceRnnrz/GameScene.swift
        let previousPhase = gameState.currentPhase
        
        // Validate state transition
        guard gameState.isValidTransition(to: phase) || phase == previousPhase else {
            logger.error("Invalid state transition from \(String(describing: previousPhase)) to \(String(describing: phase))")
            return
        }
        
=======
>>>>>>> parent of 7a06f40 (Add resume functionality after pause in GameScene):SpaceRunner/GameScene.swift
        gameState.currentPhase = phase
        
        // Handle state transition with structured concurrency
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                try await self.handlePhaseTransition(from: previousPhase, to: phase)
                
                // Post state change notification
                NotificationCenter.default.post(
                    name: GameNotification.gameStateChanged.notificationName,
                    object: self,
                    userInfo: ["previousPhase": previousPhase, "currentPhase": phase]
                )
                
                self.logger.info("Game phase changed from \(String(describing: previousPhase)) to \(String(describing: phase))")
            } catch {
                self.logger.error("Failed to transition from \(String(describing: previousPhase)) to \(String(describing: phase)): \(error)")
            }
        }
    }
    
    @MainActor
    private func handlePhaseTransition(from previousPhase: GameState.Phase, to newPhase: GameState.Phase) async throws {
        switch newPhase {
        case .tutorial:
            showTutorial()
        case .running:
<<<<<<< HEAD:SpaceRnnrz/GameScene.swift
            if previousPhase == .paused {
                resumeGameplay()
            } else {
                startGame()
            }
=======
            startGame()
>>>>>>> parent of 7a06f40 (Add resume functionality after pause in GameScene):SpaceRunner/GameScene.swift
        case .paused:
            pauseGameplay()
        case .gameOver:
            await endGame()
        }
<<<<<<< HEAD:SpaceRnnrz/GameScene.swift
=======
        
        logger.info("Game phase changed to: \(String(describing: phase))")
>>>>>>> parent of 7a06f40 (Add resume functionality after pause in GameScene):SpaceRunner/GameScene.swift
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
    
<<<<<<< HEAD:SpaceRnnrz/GameScene.swift
    private func resumeGameplay() {
        // Resume physics
        physicsWorld.speed = 1.0
        
        // Resume gameplay systems
        player.enableMovement()
        meteorController.startSendingMeteors()
        starController.startSendingStars()
        audioManager.playBackgroundMusic()
        
        // Update UI
        updateStatusBar()
    }
    
    @MainActor
    private func endGame() async {
=======
    private func endGame() {
>>>>>>> parent of 7a06f40 (Add resume functionality after pause in GameScene):SpaceRunner/GameScene.swift
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
        
        // Modern async delay and transition
        try? await Task.sleep(for: .seconds(2.0))
        await transitionToGameOver()
    }
    
    @MainActor
    private func transitionToGameOver() async {
        guard let view = view else {
            logger.error("Cannot transition: view is nil")
            return
        }
        
        let gameOverScene = GameOverScene(
            size: size,
            score: gameState.score,
            stars: gameState.starsCollected,
            streak: 0
        )
        
        let transition = SKTransition.fade(with: .black, duration: 0.75)
        view.presentScene(gameOverScene, transition: transition)
        
        logger.info("Successfully transitioned to game over scene")
    }
    
    // MARK: - Modern Update Loop
    override func update(_ currentTime: TimeInterval) {
        guard gameState.isGameActive else { return }
        
        do {
            let deltaTime = calculateDeltaTime(currentTime)
            frameCount += deltaTime
            
            // Update game objects with error handling
            try updateGameObjects(deltaTime: deltaTime)
            
            // Update game state and UI
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                await self.updateGameState()
                self.updateStatusBar()
            }
        } catch {
            logger.error("Update loop error: \(error)")
        }
    }
    
    private func updateGameObjects(deltaTime: TimeInterval) throws {
        player.update()
        meteorController.update(delta: deltaTime)
        starController.update(delta: deltaTime)
    }
    
    private func calculateDeltaTime(_ currentTime: TimeInterval) -> TimeInterval {
        let deltaTime = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
        lastUpdateTime = currentTime
        return min(deltaTime, 1.0/30.0) // Cap at 30 FPS minimum
    }
    
    @MainActor
    private func updateGameState() async {
        // Update observable state
        gameState.score = player.score
        gameState.lives = player.lives
        
        // Check for game over with proper async handling
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
        // Check if pause button was tapped
        if statusBar.pauseButton.contains(location) {
            audioManager.playSoundEffect(.buttonTap)
            setCurrentPhase(.paused)
            return
        }
        
        // Otherwise, move player
        player.updateTargetLocation(newLocation: location)
    }
    
<<<<<<< HEAD:SpaceRnnrz/GameScene.swift
    private func handlePausedTouch(at location: CGPoint) {
        // When paused, any tap resumes the game
        // Could also check for specific pause button or resume area if desired
        audioManager.playSoundEffect(.buttonTap)
        setCurrentPhase(.running)
    }
    
    // MARK: - Modern Physics Contact
    nonisolated func didBegin(_ contact: SKPhysicsContact) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            await self.handlePhysicsContact(contact)
=======
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
>>>>>>> parent of 7a06f40 (Add resume functionality after pause in GameScene):SpaceRunner/GameScene.swift
        }
    }
    
    @MainActor
    private func handlePhysicsContact(_ contact: SKPhysicsContact) async {
        let contactA = contact.bodyA.categoryBitMask
        let contactB = contact.bodyB.categoryBitMask
        
        do {
            // Player collision with meteor
            if (contactA == Contact.Player && contactB == Contact.Meteor) ||
               (contactA == Contact.Meteor && contactB == Contact.Player) {
                try await handlePlayerMeteorCollision(contact)
            }
            
            // Player collection of star
            if (contactA == Contact.Player && contactB == Contact.Star) ||
               (contactA == Contact.Star && contactB == Contact.Player) {
                try await handlePlayerStarCollection(contact)
            }
        } catch {
            logger.error("Physics contact handling error: \(error)")
        }
    }
    
    @MainActor
    private func handlePlayerMeteorCollision(_ contact: SKPhysicsContact) async throws {
        guard gameState.isGameActive else { return }
        
        let meteor = contact.bodyA.categoryBitMask == Contact.Meteor ? 
                     contact.bodyA.node : contact.bodyB.node
        
        guard let meteorNode = meteor as? Meteor else {
            throw GameError.invalidCollisionObject
        }
        
        player.hitMeteor()
        meteorNode.hitMeteor()
        audioManager.playSoundEffect(.explosion)
        
        logger.info("Player hit by meteor - lives remaining: \(self.player.lives)")
    }
    
    @MainActor
    private func handlePlayerStarCollection(_ contact: SKPhysicsContact) async throws {
        guard gameState.isGameActive else { return }
        
        let star = contact.bodyA.categoryBitMask == Contact.Star ? 
                   contact.bodyA.node : contact.bodyB.node
        
        guard let starNode = star as? Star else {
            throw GameError.invalidCollisionObject
        }
        
        starNode.pickedUpStar()  // This handles the audio and removal
        gameState.starsCollected += 1
        player.pickedUpStar()     // Update player's star count
        
        logger.info("Star collected - total: \(self.gameState.starsCollected)")
    }
    
    // MARK: - Modern App Lifecycle
    @MainActor
    func handleAppBackground() async {
        if gameState.currentPhase == .running {
            setCurrentPhase(.paused)
        }
        
        // Pause any background tasks
        gameLoopTask?.cancel()
        
        logger.info("Game paused due to app backgrounding")
    }
    
    @MainActor
    func handleAppForeground() async {
        // Game will remain paused until user resumes
        logger.info("App foregrounded - game remains in current state")
    }
    
    // MARK: - Modern Performance Monitoring
    private func monitorPerformance() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                
                let memoryUsage = ProcessInfo.processInfo.physicalMemory
                self.logger.debug("Performance check - Memory usage: \(memoryUsage)")
                
                // Monitor frame rate and log performance issues
                if self.frameCount > 0 {
                    let avgFrameTime = self.lastUpdateTime / self.frameCount
                    if avgFrameTime > 1.0/30.0 { // Less than 30 FPS
                        self.logger.warning("Performance warning: Average frame time \(avgFrameTime)s")
                    }
                }
            }
        }
    }
}
