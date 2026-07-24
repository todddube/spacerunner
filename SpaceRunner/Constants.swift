//
//  Constants.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Single source-of-truth for all project-wide constants. Grouping these here
//  avoids magic numbers scattered through the codebase and makes tuning easy.
//
//  CONTENTS
//  - Debug flag (kDebug)         — enable physics visualisation overlays
//  - Screen geometry             — kViewSize, kScreenCenter
//  - Device helpers              — kDeviceTablet for iPhone vs iPad branching
//  - SpriteName class            — string keys for every texture/node name
//  - Contact class               — physics category bitmasks for collision routing
//                                   Player, Meteor, Star, PowerUp
//  - UIText class                — localised UI string constants
//  - GameLayer class             — z-position values that define draw order
//  - GameTier class              — spawn intervals, speed multipliers, power-up
//                                   intervals for difficulty tiers 1–4
//

import Foundation
import UIKit
import SpriteKit

// MARK: - Debug
// Enabled circles around objects on screen
let kDebug = false

// MARK: - Screen Dimensions
// iOS 26 deprecates UIScreen.main. Use the connected window scene's screen at
// runtime instead.  kViewSize is set once in GameViewController.viewDidLoad and
// used throughout — it must remain a stable global for legacy call-sites.
// nonisolated(unsafe) satisfies Swift 6: value is written once on main thread
// before any background access occurs.
nonisolated(unsafe) var kViewSize: CGSize = CGSize(width: 390, height: 844) // iPhone 17 default
nonisolated(unsafe) var kScreenCenter: CGPoint = CGPoint(x: 195, y: 422)

// MARK: - Device size convenience
// Set to true for iPad at startup in GameViewController (UIDevice is @MainActor in iOS 26).
nonisolated(unsafe) var kDeviceTablet: Bool = false

// MARK: - Sprite Names
class SpriteName {
    // Button Sprite Names
    class var ButtonPause: String   { return "PauseButton" }
    class var ButtonResume: String  { return "ResumeButton" }

    // Interface title Names
    class var TitleGame: String     { return "GameTitle" }
    class var TitleGameShip: String { return "GameTitleShip" }

    // Meteors
    class var MeteorHuge: String    { return "MeteorHuge" }
    class var MeteorLarge: String   { return "MeteorLarge" }
    class var MeteorMedium: String  { return "MeteorMedium" }
    class var MeteorSmall: String   { return "MeteorSmall" }

    // Player
    class var Player: String        { return "Player" }
    class var TouchCircle: String   { return "TouchCircle" }

    // Particles
    class var Magic: String         { return "Magic" }
    class var Explosion: String     { return "ExplosionParticle.sks" }
    class var Explode: String       { return "explode.sks" }
    class var ExplodeStar: String   { return "StarParticle.sks" }

    // Status Bar
    class var PlayerLives: String   { return "PlayerLives" }

    // Stars
    class var Star: String          { return "Star" }
    class var StarIcon: String      { return "StarIcon" }

    // Power-ups
    class var PowerUpShield: String { return "PowerUpShield" }
    class var PowerUpMagnet: String { return "PowerUpMagnet" }
    class var PowerUpSlowMo: String { return "PowerUpSlowMo" }
}

// MARK: - Category Bitmasks
class Contact {
    class var Scene: UInt32         { return 1 << 0 }
    class var Meteor: UInt32        { return 1 << 1 }
    class var Star: UInt32          { return 1 << 2 }
    class var Player: UInt32        { return 1 << 3 }
    class var PowerUp: UInt32       { return 1 << 4 }
}

// MARK: - UI Text
class UIText {
    class var AuthorLabel: String   { return "(C) 2026 Todd Dube" }
}

// MARK: - zPosition Drawing
class GameLayer {
    class var Background: CGFloat   { return 0 }
    class var Meteor: CGFloat       { return 1 }
    class var Star: CGFloat         { return 2 }
    class var PowerUp: CGFloat      { return 2 }
    class var Player: CGFloat       { return 3 }
    class var Interface: CGFloat    { return 4 }
}

// MARK: - Difficulty Tiers
// Controls spawn frequency and speed as the game escalates.
class GameTier {
    /// Meteor spawn interval in seconds per tier (1-4).
    static let spawnIntervals: [Int: TimeInterval] = [1: 4.0, 2: 3.0, 3: 2.2, 4: 1.4]

    /// Meteor speed multipliers per tier (1-4).
    static let speedMultipliers: [Int: CGFloat]    = [1: 1.0, 2: 1.3, 3: 1.6, 4: 2.0]

    /// Power-up spawn intervals per tier (1-4) in seconds.
    static let powerUpIntervals: [Int: TimeInterval] = [1: 18.0, 2: 15.0, 3: 13.0, 4: 10.0]
}
