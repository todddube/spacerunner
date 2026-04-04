//
//  AppDelegate.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  iOS application entry point and lifecycle coordinator. Initialises shared
//  services on launch and forwards foreground / background transitions to
//  GameAudio so music resumes and pauses correctly.
//
//  LIFECYCLE HOOKS
//  - application(_:didFinishLaunchingWithOptions:)
//      — async-initialise GameAudio so buffers are ready before gameplay
//  - applicationDidEnterBackground(_:)
//      — notify GameAudio.shared.handleAppBackground()
//  - applicationWillEnterForeground(_:)
//      — notify GameAudio.shared.handleAppForeground()
//  - applicationWillTerminate(_:)
//      — any final clean-up before process exit
//

import UIKit
import SpriteKit
import AVFoundation

// iOS 26 / Swift 6: Use @main on a struct instead of @UIApplicationMain on AppDelegate.
// The @UIApplicationMain attribute is deprecated in iOS 26.
@main
struct SpaceRunnerApp {
    static func main() {
        UIApplicationMain(
            CommandLine.argc,
            CommandLine.unsafeArgv,
            nil,
            NSStringFromClass(AppDelegate.self)
        )
    }
}

@MainActor
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize audio system early
        Task { @MainActor in
            await GameAudio.shared.initializeAudio()
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Post message to pause the game
        NotificationCenter.default.post(name: Notification.Name(rawValue: "PauseGame"), object: nil)

        // Pause the music
        GameAudio.shared.pauseBackgroundMusic()

        // Pause the SpriteKit view
        if let skView = window?.rootViewController?.view as? SKView {
            skView.isPaused = true
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        GameAudio.shared.handleAppBackground()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Audio session will be re-activated in applicationDidBecomeActive
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Resume the SpriteKit view
        if let skView = window?.rootViewController?.view as? SKView {
            skView.isPaused = false
        }

        // Post message to resume the game
        NotificationCenter.default.post(name: Notification.Name(rawValue: "ResumeGame"), object: nil)

        // Resume music
        GameAudio.shared.handleAppForeground()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // No cleanup needed; GameAudio deallocation handles engine teardown.
    }
}
