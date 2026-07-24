//
//  SceneDelegate.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  UIWindowScene lifecycle coordinator (iOS 13+ scene-based launch). Creates the
//  app's window programmatically, installs GameViewController as its root, and
//  forwards scene foreground / background transitions to GameAudio and the game
//  scene so music and gameplay pause and resume correctly.
//
//  Replaces the legacy Main.storyboard `UIMainStoryboardFile` launch path. The
//  storyboard is retained only as the launch screen (`UILaunchStoryboardName`).
//
//  LIFECYCLE HOOKS
//  - scene(_:willConnectTo:options:)  — build window + root view controller
//  - sceneWillResignActive(_:)        — pause SKView + music, post PauseGame
//  - sceneDidBecomeActive(_:)         — resume SKView + music, post ResumeGame
//  - sceneDidEnterBackground(_:)      — GameAudio.handleAppBackground()
//  - sceneWillEnterForeground(_:)     — GameAudio.handleAppForeground()
//

import UIKit
import SpriteKit

@MainActor
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = GameViewController()
        window.makeKeyAndVisible()
        self.window = window
    }

    // MARK: - Lifecycle

    private var rootSKView: SKView? {
        window?.rootViewController?.view as? SKView
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Pause the game and audio when the scene is no longer active.
        NotificationCenter.default.post(name: Notification.Name("PauseGame"), object: nil)
        GameAudio.shared.pauseBackgroundMusic()
        rootSKView?.isPaused = true
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Resume the SpriteKit view and music when the scene becomes active.
        rootSKView?.isPaused = false
        NotificationCenter.default.post(name: Notification.Name("ResumeGame"), object: nil)
        GameAudio.shared.handleAppForeground()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        GameAudio.shared.handleAppBackground()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Audio session is re-activated in sceneDidBecomeActive.
    }
}
