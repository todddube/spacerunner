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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize audio system early
        Task { @MainActor in
            await GameAudio.shared.initializeAudio()
        }
        return true
    }

    // MARK: - Scene Configuration
    // The app is scene-based (see UIApplicationSceneManifest in Info.plist).
    // Foreground / background handling lives in SceneDelegate — the legacy
    // application(will/did …Active/Background) hooks are not called for
    // scene-based apps and have been removed.
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration",
                             sessionRole: connectingSceneSession.role)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // No cleanup needed; GameAudio deallocation handles engine teardown.
    }
}
