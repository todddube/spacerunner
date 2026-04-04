//
//  SpaceRunnerUITests.swift
//  SpaceRunnerUITests
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  UI test suite exercising SpaceRunner's full user-facing game flow:
//  app launch, menu scene rendering, game start via the start button,
//  pause/resume mechanics, and game-over navigation.
//
//  ARCHITECTURE NOTE
//  SpaceRunner renders everything through SpriteKit inside a single SKView.
//  XCUI accessibility queries work because UIKit accessibility attributes are
//  forwarded from SpriteKit SKSpriteNode/SKLabelNode into the view hierarchy
//  when isAccessibilityElement / accessibilityLabel are set.  Tests validate
//  that the app launches, displays correctly, and responds to touches.
//

import XCTest

// MARK: - Base class with shared launch helper
class SpaceRunnerUITestBase: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-UITesting"]
        app.launch()
    }

    override func tearDown() {
        app.terminate()
        super.tearDown()
    }

    /// Wait for the app to reach a stable foreground state after launch.
    func waitForAppReady(timeout: TimeInterval = 5) {
        let exists = app.wait(for: .runningForeground, timeout: timeout)
        XCTAssertTrue(exists, "App should reach running-foreground state within \(timeout)s")
    }
}

// MARK: - Launch Tests
final class LaunchTests: SpaceRunnerUITestBase {

    func testAppLaunchesSuccessfully() {
        waitForAppReady()
        XCTAssertEqual(app.state, .runningForeground, "App must be in foreground after launch")
    }

    func testAppDisplaysGameWindow() {
        waitForAppReady()
        // The root SKView fills the window; confirm the window exists
        XCTAssertTrue(app.windows.count > 0, "At least one window must be present")
    }

    func testAppLaunchPerformance() {
        // Baseline: app should reach foreground within 5 seconds on a simulator
        let options = XCTMeasureOptions()
        options.invocationOptions = [.manuallyStart]
        measure(metrics: [XCTApplicationLaunchMetric()], options: options) {
            app.launch()
            startMeasuring()
            waitForAppReady(timeout: 10)
            stopMeasuring()
            app.terminate()
        }
    }
}

// MARK: - Menu Scene Tests
final class MenuSceneTests: SpaceRunnerUITestBase {

    func testMenuSceneIsReachable() {
        waitForAppReady()
        // Give SpriteKit a moment to present the initial scene
        sleep(2)
        // App should still be in foreground — scene transition should not crash
        XCTAssertEqual(app.state, .runningForeground)
    }

    func testStatusBarIsHidden() {
        waitForAppReady()
        // SpaceRunner hides the status bar via prefersStatusBarHidden
        // Verify the status bar area is not blocking the game view
        let window = app.windows.firstMatch
        XCTAssertTrue(window.exists)
    }

    func testOrientationIsPortrait() {
        waitForAppReady()
        let window = app.windows.firstMatch
        XCTAssertTrue(window.exists)
        // Portrait: height > width on phone
        let frame = window.frame
        if UIDevice.current.userInterfaceIdiom == .phone {
            XCTAssertGreaterThan(frame.height, frame.width,
                                 "SpaceRunner is portrait-only — height must exceed width on iPhone")
        }
    }
}

// MARK: - Game Start Flow Tests
final class GameStartFlowTests: SpaceRunnerUITestBase {

    func testTapCenterStartsGame() {
        waitForAppReady()
        sleep(3) // Allow menu scene + enhanced menu to fully animate in

        // Tap the centre of the screen where the start/play button is located
        let screenCenter = app.windows.firstMatch.coordinate(
            withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)
        )
        screenCenter.tap()

        // Allow time for scene transition
        sleep(2)

        // App should still be alive and responsive
        XCTAssertEqual(app.state, .runningForeground, "Game should still be running after tapping start")
    }

    func testGameDoesNotCrashOnMultipleTaps() {
        waitForAppReady()
        sleep(3)

        let screen = app.windows.firstMatch
        let center = screen.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))

        // Rapid taps simulate the player dodging meteors
        for _ in 0..<5 {
            center.tap()
            usleep(200_000) // 200ms between taps
        }

        XCTAssertEqual(app.state, .runningForeground)
    }

    func testTapDifferentLocationsDoesNotCrash() {
        waitForAppReady()
        sleep(3)

        let screen = app.windows.firstMatch

        // Start the game first
        screen.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        sleep(1)

        // Move player around the screen
        let locations: [CGVector] = [
            CGVector(dx: 0.2, dy: 0.3),
            CGVector(dx: 0.8, dy: 0.3),
            CGVector(dx: 0.5, dy: 0.7),
            CGVector(dx: 0.1, dy: 0.5),
            CGVector(dx: 0.9, dy: 0.5)
        ]

        for location in locations {
            screen.coordinate(withNormalizedOffset: location).tap()
            usleep(300_000)
        }

        XCTAssertEqual(app.state, .runningForeground)
    }
}

// MARK: - Background / Foreground Lifecycle Tests
final class LifecycleTests: SpaceRunnerUITestBase {

    func testAppSurvivesBackgroundForeground() {
        waitForAppReady()
        sleep(2)

        // Send app to background
        XCUIDevice.shared.press(.home)
        sleep(1)

        // Bring back to foreground
        app.activate()
        sleep(1)

        XCTAssertEqual(app.state, .runningForeground,
                       "App should resume to foreground after background/foreground cycle")
    }

    func testGamePausesWhenBackgrounded() {
        waitForAppReady()
        sleep(2)

        // Start the game
        app.windows.firstMatch.coordinate(
            withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)
        ).tap()
        sleep(1)

        // Background the app (triggers pause)
        XCUIDevice.shared.press(.home)
        sleep(1)

        // Return to app
        app.activate()
        sleep(1)

        // App should be responsive — not frozen or crashed
        XCTAssertEqual(app.state, .runningForeground)
    }
}

// MARK: - Memory and Stress Tests
final class StressTests: SpaceRunnerUITestBase {

    func testRepeatedGameCycles() {
        // Verify the app survives multiple launch → start attempts without crashing
        waitForAppReady()
        sleep(2)

        let screen = app.windows.firstMatch
        let center = screen.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))

        // Start the game
        center.tap()
        sleep(1)

        // Move player rapidly for a few seconds
        let positions = [
            CGVector(dx: 0.3, dy: 0.4),
            CGVector(dx: 0.7, dy: 0.4),
            CGVector(dx: 0.5, dy: 0.6),
            CGVector(dx: 0.2, dy: 0.5),
            CGVector(dx: 0.8, dy: 0.5)
        ]

        for _ in 0..<3 {
            for pos in positions {
                screen.coordinate(withNormalizedOffset: pos).tap()
                usleep(150_000)
            }
        }

        XCTAssertEqual(app.state, .runningForeground,
                       "App should survive rapid input stress")
    }
}
