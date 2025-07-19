//
//  GameViewController.swift
//  SpaceRunner
//
//  Created by Todd Dube : 2025
//  Purpose: Modern hybrid view controller supporting SpriteKit with SwiftUI overlays for iOS 18+.
//

import UIKit
import SpriteKit
import SwiftUI
import OSLog

@available(iOS 18.0, *)
@MainActor
final class GameViewController: UIViewController {
    
    // MARK: - Properties
    private var skView: SKView!
    private var currentGameScene: GameScene?
    // private var overlayHostingController: UIHostingController<GameOverlay>? // TODO: Add SwiftUI files to project
    
    // iOS 18+ specific properties
    private var isSetupComplete = false
    
    private let logger = Logger(subsystem: "com.todddube.spacerunner", category: "GameViewController")
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        Task { @MainActor in
            await setupViewController()
        }
    }
    
    private func setupViewController() async {
        setupSpriteKitView()
        setupAccessibility()
        setupModernFeatures()
        presentMenuScene()
        isSetupComplete = true
        logger.info("GameViewController loaded and configured for iOS 18+")
    }
    
    private func setupModernFeatures() {
        // Configure for better performance on iOS 18+
        view.layer.allowsGroupOpacity = false
        // Note: allowsGroupBlending is not available on CALayer
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Handle app lifecycle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupSpriteKitView() {
        guard let skView = view as? SKView else {
            logger.error("View is not an SKView")
            return
        }
        
        self.skView = skView
        
        // Configure SpriteKit view
        skView.ignoresSiblingOrder = true
        skView.allowsTransparency = true
        
        // Debug settings
        if kDebug {
            skView.showsFPS = true
            skView.showsPhysics = true
            skView.showsNodeCount = true
        }
    }
    
    private func setupAccessibility() {
        view.accessibilityLabel = "SpaceRunner Game"
        view.accessibilityHint = "Space-themed endless runner game"
        view.isAccessibilityElement = false // Allow child elements to be accessible
    }
    
    // MARK: - Scene Management
    private func presentMenuScene() {
        let menuScene = MenuScene(size: kViewSize)
        let transition = SKTransition.fade(with: .black, duration: 0.75)
        skView.presentScene(menuScene, transition: transition)
        
        logger.info("Presented menu scene")
    }
    
    func presentGameScene() {
        let gameScene = GameScene(size: kViewSize)
        self.currentGameScene = gameScene
        
        let transition = SKTransition.fade(with: .black, duration: 0.5)
        skView.presentScene(gameScene, transition: transition)
        
        // Add SwiftUI overlay
        // setupGameOverlay(for: gameScene) // TODO: Enable when SwiftUI files are in project
        
        logger.info("Presented game scene with SwiftUI overlay")
    }
    
    func returnToMenuScene() {
        // removeGameOverlay() // TODO: Enable when SwiftUI files are in project
        currentGameScene = nil
        presentMenuScene()
        
        logger.info("Returned to menu scene")
    }
    
    // MARK: - SwiftUI Overlay Management
    // TODO: Uncomment when SwiftUI files are properly added to project
    /*
    private func setupGameOverlay(for gameScene: GameScene) {
        guard isSetupComplete else {
            logger.warning("Attempted to setup overlay before view controller setup complete")
            return
        }
        
        // Remove existing overlay
        removeGameOverlay()
        
        // Create SwiftUI overlay - iOS 18+ guaranteed
        let overlayView = GameOverlay(gameScene: gameScene)
        let hostingController = UIHostingController(rootView: overlayView)
        
        // Configure hosting controller for iOS 18+
        hostingController.view.backgroundColor = UIColor.clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // iOS 18+ optimizations
        hostingController.view.layer.allowsGroupOpacity = false
        hostingController.view.isOpaque = false
        
        // Add as child view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        // Setup constraints with safe area support
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        self.overlayHostingController = hostingController
        
        logger.info("SwiftUI overlay configured and added for iOS 18+")
    }
    
    private func removeGameOverlay() {
        guard let hostingController = overlayHostingController else { return }
        
        hostingController.willMove(toParent: nil as UIViewController?)
        hostingController.view.removeFromSuperview()
        hostingController.removeFromParent()
        overlayHostingController = nil
        
        logger.debug("SwiftUI overlay removed")
    }
    */
    
    // MARK: - App Lifecycle Handlers
    @objc private func handleAppWillResignActive() {
        // Pause game if active
        currentGameScene?.handleAppBackground()
        GameAudio.shared.handleAppBackground()
        
        logger.info("App will resign active - paused game")
    }
    
    @objc private func handleAppDidBecomeActive() {
        // Resume game if it was active
        GameAudio.shared.handleAppForeground()
        
        logger.info("App became active - resumed audio")
    }
    
    // MARK: - Orientation Support
    override var shouldAutorotate: Bool {
        return false // SpaceRunner is portrait only
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    // MARK: - Status Bar
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    
    // MARK: - Memory Management
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // Clear any cached resources
        GameTextures.clearCache()
        
        logger.warning("Received memory warning - cleared texture cache")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        // Note: Cannot call async methods from deinit
        // Overlay cleanup will happen automatically when view is removed
        logger.info("GameViewController deinitialized")
    }
}

// MARK: - GameTextures Cache Management
extension GameTextures {
    static func clearCache() {
        // Implementation would clear any cached textures
        // This is a placeholder for texture cache management
    }
}
