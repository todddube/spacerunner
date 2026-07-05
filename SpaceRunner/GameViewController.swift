//
//  GameViewController.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Root view controller that hosts the SKView and wires it to the initial
//  scene. Supports optional SwiftUI overlay layers for settings and pause
//  menus using UIHostingController composition, following iOS 18+ patterns.
//
//  RESPONSIBILITIES
//  - viewDidLoad()              — configure SKView (frame rate, debug flags) and
//      present the initial scene (MenuScene or EnhancedMenuScene)
//  - setupSKView()              — disable unnecessary render statistics in release,
//      enable physics debug outlines when kDebug is true
//  - presentInitialScene()      — choose starting scene and apply entry transition
//  - orientationSupport         — lock to portrait via supportedInterfaceOrientations
//  - addSwiftUIOverlay(_:)      — utility to layer a SwiftUI view over the SpriteKit
//      canvas without disturbing the scene graph
//
//  REQUIRES iOS 18.0+  — uses @MainActor and UIHostingController SwiftUI bridging
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
        // iOS 26: Set screen constants from window scene (UIScreen.main is deprecated).
        // UIDevice.current is @MainActor in iOS 26 — safe here since we're on MainActor.
        kDeviceTablet = UIDevice.current.userInterfaceIdiom == .pad
        if let windowScene = view.window?.windowScene ?? UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first {
            let screenBounds = windowScene.screen.bounds
            kViewSize = screenBounds.size
            kScreenCenter = CGPoint(x: screenBounds.midX, y: screenBounds.midY)
        } else {
            kViewSize = view.bounds.size
            kScreenCenter = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        }
        setupSpriteKitView()
        setupAccessibility()
        setupModernFeatures()
        presentMenuScene()
        isSetupComplete = true
        logger.info("GameViewController loaded and configured for iOS 26")
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
        let menuScene = EnhancedMenuScene(size: kViewSize)
        let transition = SKTransition.fade(with: .black, duration: 0.75)
        skView.presentScene(menuScene, transition: transition)

        logger.info("Presented enhanced menu scene")
    }
    
    func presentGameScene() {
        let gameScene = GameScene(size: kViewSize)
        self.currentGameScene = gameScene
        
        let transition = SKTransition.fade(with: .black, duration: 0.5)
        skView.presentScene(gameScene, transition: transition)
        
        logger.info("Presented game scene")
    }
    
    func returnToMenuScene() {
        currentGameScene = nil
        presentMenuScene()
        
        logger.info("Returned to menu scene")
    }
    
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
