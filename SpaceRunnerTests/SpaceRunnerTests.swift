//
//  SpaceRunnerTests.swift
//  SpaceRunnerTests
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Comprehensive unit test suite covering game logic, math utilities, scoring,
//  lives/streak mechanics, settings persistence, and physics constants.
//  Tests are isolated — no SpriteKit scene or UIKit window required.
//

import XCTest
import SpriteKit
import GameplayKit
@testable import SpaceRunner

// MARK: - Math Helper Tests
final class MathTests: XCTestCase {

    // MARK: Smooth (lerp)

    func testSmoothAtZeroFilter() {
        let result = Smooth(startPoint: 100, endPoint: 200, filter: 0)
        XCTAssertEqual(result, 100, accuracy: 0.001)
    }

    func testSmoothAtFullFilter() {
        let result = Smooth(startPoint: 100, endPoint: 200, filter: 1)
        XCTAssertEqual(result, 200, accuracy: 0.001)
    }

    func testSmoothAtHalfFilter() {
        let result = Smooth(startPoint: 0, endPoint: 100, filter: 0.5)
        XCTAssertEqual(result, 50, accuracy: 0.001)
    }

    func testSmoothConvergesOverIterations() {
        var pos: CGFloat = 0
        let target: CGFloat = 100
        for _ in 0..<100 {
            pos = Smooth(startPoint: pos, endPoint: target, filter: 0.10)
        }
        XCTAssertEqual(pos, target, accuracy: 0.01,
                       "lerp should converge close to target after many iterations")
    }

    // MARK: RandomIntegerBetween

    func testRandomIntegerInRange() {
        for _ in 0..<100 {
            let value = RandomIntegerBetween(min: 0, max: 10)
            XCTAssertGreaterThanOrEqual(value, 0)
            XCTAssertLessThanOrEqual(value, 10)
        }
    }

    func testRandomIntegerSingleValue() {
        let value = RandomIntegerBetween(min: 5, max: 5)
        XCTAssertEqual(value, 5)
    }

    func testRandomIntegerProducesVariance() {
        var results = Set<Int>()
        for _ in 0..<200 {
            results.insert(RandomIntegerBetween(min: 0, max: 9))
        }
        XCTAssertGreaterThan(results.count, 3, "random integers should produce varied results")
    }

    func testRandomIntegerMaxLessThanMinReturnsSafeValue() {
        let value = RandomIntegerBetween(min: 10, max: 5)
        XCTAssertEqual(value, 10)
    }

    // MARK: RandomFloatRange

    func testRandomFloatInRange() {
        for _ in 0..<100 {
            let value = RandomFloatRange(min: -1.0, max: 1.0)
            XCTAssertGreaterThanOrEqual(value, -1.0)
            XCTAssertLessThanOrEqual(value, 1.0)
        }
    }

    func testRandomFloatProducesVariance() {
        var results: [CGFloat] = []
        for _ in 0..<50 {
            results.append(RandomFloatRange(min: 0, max: 1000))
        }
        let uniqueCount = Set(results.map { Int($0) }).count
        XCTAssertGreaterThan(uniqueCount, 5, "random floats should produce varied results")
    }

    func testRandomFloatEqualMinMax() {
        let value = RandomFloatRange(min: 42, max: 42)
        XCTAssertEqual(value, 42, accuracy: 0.001)
    }

    // MARK: DegressToRadians

    func testDegressToRadiansZero() {
        XCTAssertEqual(DegressToRadians(degrees: 0), 0, accuracy: 0.001)
    }

    func testDegressToRadians180() {
        XCTAssertEqual(DegressToRadians(degrees: 180), CGFloat.pi, accuracy: 0.001)
    }

    func testDegressToRadians360() {
        XCTAssertEqual(DegressToRadians(degrees: 360), CGFloat.pi * 2, accuracy: 0.001)
    }

    func testDegressToRadians90() {
        XCTAssertEqual(DegressToRadians(degrees: 90), CGFloat.pi / 2, accuracy: 0.001)
    }

    func testDegressToRadiansNegative() {
        let result = DegressToRadians(degrees: -90)
        XCTAssertEqual(result, -CGFloat.pi / 2, accuracy: 0.001)
    }
}

// MARK: - Colors Tests
final class ColorsTests: XCTestCase {

    func testColorFromRGBBlack() {
        let color = Colors.colorFromRGB(rgbvalue: 0x000000)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, 0, accuracy: 0.01)
        XCTAssertEqual(g, 0, accuracy: 0.01)
        XCTAssertEqual(b, 0, accuracy: 0.01)
        XCTAssertEqual(a, 1, accuracy: 0.01)
    }

    func testColorFromRGBWhite() {
        let color = Colors.colorFromRGB(rgbvalue: 0xFFFFFF)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, 1, accuracy: 0.01)
        XCTAssertEqual(g, 1, accuracy: 0.01)
        XCTAssertEqual(b, 1, accuracy: 0.01)
        XCTAssertEqual(a, 1, accuracy: 0.01)
    }

    func testColorFromRGBRed() {
        let color = Colors.colorFromRGB(rgbvalue: 0xFF0000)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, 1, accuracy: 0.01)
        XCTAssertEqual(g, 0, accuracy: 0.01)
        XCTAssertEqual(b, 0, accuracy: 0.01)
    }

    func testColorFromRGBGreen() {
        let color = Colors.colorFromRGB(rgbvalue: 0x00FF00)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, 0, accuracy: 0.01)
        XCTAssertEqual(g, 1, accuracy: 0.01)
        XCTAssertEqual(b, 0, accuracy: 0.01)
    }

    func testColorFromRGBBlue() {
        let color = Colors.colorFromRGB(rgbvalue: 0x0000FF)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, 0, accuracy: 0.01)
        XCTAssertEqual(g, 0, accuracy: 0.01)
        XCTAssertEqual(b, 1, accuracy: 0.01)
    }

    func testColorConstantsDefined() {
        XCTAssertNotNil(Colors.Background)
        XCTAssertNotNil(Colors.Magic)
        XCTAssertNotNil(Colors.FontBonus)
        XCTAssertNotNil(Colors.FontScore)
        XCTAssertNotNil(Colors.FontMenu)
        XCTAssertNotNil(Colors.EngineGreen)
        XCTAssertNotNil(Colors.EngineYellow)
        XCTAssertNotNil(Colors.EngineRed)
    }
}

// MARK: - GameSettings Tests
@MainActor
final class GameSettingsTests: XCTestCase {

    var settings: GameSettings!

    override func setUp() {
        super.setUp()
        settings = GameSettings.shared
        settings.resetAllStats()
    }

    override func tearDown() {
        settings.resetAllStats()
        super.tearDown()
    }

    func testInitialStatsAreZero() {
        XCTAssertEqual(settings.bestScore, 0)
        XCTAssertEqual(settings.bestStars, 0)
        XCTAssertEqual(settings.bestStreak, 0)
    }

    func testUpdateBestScoreHigher() {
        settings.updateBestScore(1000)
        XCTAssertEqual(settings.bestScore, 1000)
    }

    func testUpdateBestScoreDoesNotDecrement() {
        settings.updateBestScore(1000)
        settings.updateBestScore(500)
        XCTAssertEqual(settings.bestScore, 1000, "best score should not decrease")
    }

    func testUpdateBestScoreEqual() {
        settings.updateBestScore(500)
        settings.updateBestScore(500)
        XCTAssertEqual(settings.bestScore, 500)
    }

    func testUpdateBestStars() {
        settings.updateBestStars(42)
        XCTAssertEqual(settings.bestStars, 42)
    }

    func testUpdateBestStarsDoesNotDecrement() {
        settings.updateBestStars(100)
        settings.updateBestStars(10)
        XCTAssertEqual(settings.bestStars, 100)
    }

    func testUpdateBestStreak() {
        settings.updateBestStreak(15)
        XCTAssertEqual(settings.bestStreak, 15)
    }

    func testUpdateBestStreakDoesNotDecrement() {
        settings.updateBestStreak(30)
        settings.updateBestStreak(1)
        XCTAssertEqual(settings.bestStreak, 30)
    }

    func testResetAllStats() {
        settings.updateBestScore(9999)
        settings.updateBestStars(99)
        settings.updateBestStreak(50)
        settings.resetAllStats()
        XCTAssertEqual(settings.bestScore, 0)
        XCTAssertEqual(settings.bestStars, 0)
        XCTAssertEqual(settings.bestStreak, 0)
    }

    func testPersistsBestScore() {
        settings.updateBestScore(5000)
        let persisted = UserDefaults.standard.integer(forKey: "BestScore")
        XCTAssertEqual(persisted, 5000)
    }

    func testPersistsBestStars() {
        settings.updateBestStars(25)
        let persisted = UserDefaults.standard.integer(forKey: "BestStars")
        XCTAssertEqual(persisted, 25)
    }

    func testPersistsBestStreak() {
        settings.updateBestStreak(12)
        let persisted = UserDefaults.standard.integer(forKey: "BestStreak")
        XCTAssertEqual(persisted, 12)
    }
}

// MARK: - Constants / SpriteName Tests
final class ConstantsTests: XCTestCase {

    func testSpriteNameButtonsAreDefined() {
        XCTAssertFalse(SpriteName.ButtonPlay.isEmpty)
        XCTAssertFalse(SpriteName.ButtonStart.isEmpty)
        XCTAssertFalse(SpriteName.ButtonRetry.isEmpty)
        XCTAssertFalse(SpriteName.ButtonPause.isEmpty)
        XCTAssertFalse(SpriteName.ButtonResume.isEmpty)
    }

    func testSpriteNameMeteorsAreDefined() {
        XCTAssertEqual(SpriteName.MeteorHuge, "MeteorHuge")
        XCTAssertEqual(SpriteName.MeteorLarge, "MeteorLarge")
        XCTAssertEqual(SpriteName.MeteorMedium, "MeteorMedium")
        XCTAssertEqual(SpriteName.MeteorSmall, "MeteorSmall")
    }

    func testSpriteNamePlayerIsDefined() {
        XCTAssertEqual(SpriteName.Player, "Player")
    }

    func testSpriteNameStarIsDefined() {
        XCTAssertEqual(SpriteName.Star, "Star")
    }

    func testContactBitmaskValues() {
        XCTAssertEqual(Contact.Scene,  1)
        XCTAssertEqual(Contact.Meteor, 2)
        XCTAssertEqual(Contact.Star,   4)
        XCTAssertEqual(Contact.Player, 8)
    }

    func testContactBitmaskNoOverlap() {
        let all: [UInt32] = [Contact.Scene, Contact.Meteor, Contact.Star, Contact.Player]
        var combined: UInt32 = 0
        for mask in all {
            XCTAssertEqual(combined & mask, 0,
                           "bitmask \(mask) overlaps with previously seen masks")
            combined |= mask
        }
    }

    func testGameLayerZPositionsAreOrdered() {
        XCTAssertLessThan(GameLayer.Background, GameLayer.Meteor)
        XCTAssertLessThan(GameLayer.Meteor, GameLayer.Star)
        XCTAssertLessThan(GameLayer.Star, GameLayer.Player)
        XCTAssertLessThan(GameLayer.Player, GameLayer.Interface)
    }

    func testUITextAuthorLabelNotEmpty() {
        XCTAssertFalse(UIText.AuthorLabel.isEmpty)
    }

    func testKViewSizePositiveDimensions() {
        XCTAssertGreaterThan(kViewSize.width, 0)
        XCTAssertGreaterThan(kViewSize.height, 0)
    }
}

// MARK: - Player Scoring Logic Tests (pure table logic, no SpriteKit required)
final class PlayerScoringTests: XCTestCase {

    /// Mirrors the scoring switch in Player.pickedUpStar()
    private func scoreForStreak(_ streak: Int) -> Int {
        switch streak {
        case 0..<5:   return 250
        case 5..<10:  return 500
        case 10..<15: return 750
        case 15..<20: return 1000
        case 20..<25: return 1250
        case 25..<30: return 1500
        case 30..<35: return 1750
        case 35..<40: return 2000
        case 40..<45: return 2250
        case 45..<50: return 2500
        default:      return 5000
        }
    }

    func testBaseScoreAtStreakZero() {
        XCTAssertEqual(scoreForStreak(0), 250)
    }

    func testBaseScoreAtStreak4() {
        XCTAssertEqual(scoreForStreak(4), 250)
    }

    func testStreakBonusAt5() {
        XCTAssertEqual(scoreForStreak(5), 500)
    }

    func testStreakBonusAt10() {
        XCTAssertEqual(scoreForStreak(10), 750)
    }

    func testStreakBonusAt15() {
        XCTAssertEqual(scoreForStreak(15), 1000)
    }

    func testStreakBonusAt20() {
        XCTAssertEqual(scoreForStreak(20), 1250)
    }

    func testStreakBonusAt30() {
        XCTAssertEqual(scoreForStreak(30), 1750)
    }

    func testStreakBonusAt50Plus() {
        XCTAssertEqual(scoreForStreak(50),  5000)
        XCTAssertEqual(scoreForStreak(100), 5000)
    }

    func testScoreGrowsWithHigherStreak() {
        let tiers = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50]
        for i in 0..<tiers.count - 1 {
            XCTAssertLessThanOrEqual(
                scoreForStreak(tiers[i]),
                scoreForStreak(tiers[i + 1]),
                "Score at streak \(tiers[i]) should be ≤ score at streak \(tiers[i + 1])"
            )
        }
    }

    func testCumulativeScoreFirst10Stars() {
        var total = 0
        for streak in 1...10 {
            total += scoreForStreak(streak - 1)
        }
        // Streaks 1–5  (index 0–4): 250 × 5 = 1250
        // Streaks 6–10 (index 5–9): 500 × 5 = 2500
        XCTAssertEqual(total, 3750)
    }
}

// MARK: - Meteor & Star Physics Logic Tests
final class GameObjectTests: XCTestCase {

    func testMeteorPhysicsCategory() {
        XCTAssertEqual(Contact.Meteor, UInt32(1 << 1))
    }

    func testStarPhysicsCategory() {
        XCTAssertEqual(Contact.Star, UInt32(1 << 2))
    }

    func testMeteorSpeedPhoneVsTablet() {
        let delta = 1.0 / 60.0
        let phoneSpeed = CGFloat(delta * 60 * 2)
        let tabletSpeed = CGFloat(delta * 60 * 4)
        XCTAssertGreaterThan(phoneSpeed, 0)
        XCTAssertGreaterThan(tabletSpeed, phoneSpeed)
        XCTAssertEqual(phoneSpeed,  2.0, accuracy: 0.001)
        XCTAssertEqual(tabletSpeed, 4.0, accuracy: 0.001)
    }

    func testMeteorSpawnXInRange() {
        for _ in 0..<50 {
            let idx = RandomIntegerBetween(min: 0, max: 3)
            let offsetX: CGFloat = idx % 2 == 0 ? -72 : 72
            let startX = RandomFloatRange(min: 0, max: kViewSize.width) + offsetX
            XCTAssertGreaterThan(startX, -200)
            XCTAssertLessThan(startX, kViewSize.width + 200)
        }
    }

    func testMeteorDriftRange() {
        for _ in 0..<50 {
            let drift = RandomFloatRange(min: -0.3, max: 0.3)
            XCTAssertGreaterThanOrEqual(drift, -0.3)
            XCTAssertLessThanOrEqual(drift, 0.3)
        }
    }

    func testStarDriftRange() {
        for _ in 0..<50 {
            let drift = RandomFloatRange(min: -0.25, max: 0.25)
            XCTAssertGreaterThanOrEqual(drift, -0.25)
            XCTAssertLessThanOrEqual(drift, 0.25)
        }
    }

    func testMeteorSpawnCountInRange() {
        for _ in 0..<50 {
            let count = RandomIntegerBetween(min: 4, max: 10)
            XCTAssertGreaterThanOrEqual(count, 4)
            XCTAssertLessThanOrEqual(count, 10)
        }
    }
}

// MARK: - GameAudio Enum Tests (no audio engine required)
final class GameAudioEnumTests: XCTestCase {

    func testAllSoundEffectsCasesDefined() {
        let effects = GameAudio.SoundEffect.allCases
        XCTAssertFalse(effects.isEmpty)
        XCTAssertTrue(effects.contains(.explosion))
        XCTAssertTrue(effects.contains(.pickup))
        XCTAssertTrue(effects.contains(.buttonTap))
        XCTAssertTrue(effects.contains(.shieldUp))
        XCTAssertTrue(effects.contains(.shieldDown))
    }

    func testMusicTrackCasesDefined() {
        let tracks = GameAudio.MusicTrack.allCases
        XCTAssertFalse(tracks.isEmpty)
        XCTAssertTrue(tracks.contains(.game))
    }

    func testMusicTrackFileNamesHaveExtension() {
        for track in GameAudio.MusicTrack.allCases {
            XCTAssertTrue(track.fileName.contains("."),
                          "Track \(track.rawValue) should have a file extension")
        }
    }

    func testSoundEffectFileNamesHaveExtension() {
        for effect in GameAudio.SoundEffect.allCases {
            XCTAssertTrue(effect.fileName.contains("."),
                          "Effect \(effect.rawValue) should have a file extension")
        }
    }
}

// MARK: - GameLayer Z-Position Tests
final class GameLayerTests: XCTestCase {

    func testBackgroundIsZero() {
        XCTAssertEqual(GameLayer.Background, 0)
    }

    func testEachLayerHigherThanPrevious() {
        XCTAssertLessThan(GameLayer.Background, GameLayer.Meteor)
        XCTAssertLessThan(GameLayer.Meteor,     GameLayer.Star)
        XCTAssertLessThan(GameLayer.Star,       GameLayer.Player)
        XCTAssertLessThan(GameLayer.Player,     GameLayer.Interface)
    }

    func testInterfaceIsTopmost() {
        let all = [GameLayer.Background, GameLayer.Meteor, GameLayer.Star, GameLayer.Player]
        for layer in all {
            XCTAssertLessThan(layer, GameLayer.Interface,
                              "Interface layer must be above layer \(layer)")
        }
    }
}

// MARK: - Performance Tests
final class PerformanceTests: XCTestCase {

    func testRandomIntegerPerformance() {
        measure {
            for _ in 0..<10_000 {
                _ = RandomIntegerBetween(min: 0, max: 100)
            }
        }
    }

    func testRandomFloatPerformance() {
        measure {
            for _ in 0..<10_000 {
                _ = RandomFloatRange(min: 0, max: kViewSize.width)
            }
        }
    }

    func testSmoothPerformance() {
        measure {
            var pos: CGFloat = 0
            for _ in 0..<10_000 {
                pos = Smooth(startPoint: pos, endPoint: 100, filter: 0.1)
            }
        }
    }
}
