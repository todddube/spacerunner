//
//  GameProgression.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Pure gameplay-progression state machine — score-driven tier escalation and
//  boss-wave scheduling — extracted from GameScene so the decision logic is
//  unit-testable without a live SpriteKit scene.
//
//  SEPARATION OF CONCERNS
//  This type owns ONLY state and decisions. All side effects (labels, screen
//  flashes, camera shake, controller speed/tier mutations, audio) remain in
//  GameScene, which drives this model each frame and reacts to what it returns.
//
//  PROGRESSION RULES (unchanged from the original in-scene logic)
//  - Tiers 1–4 unlock at score thresholds 500 / 1500 / 3000.
//  - A boss wave triggers each time the score crosses a 1000-point boundary,
//    provided one is not already active. It lasts `bossWaveDuration` seconds.
//

import Foundation

/// Score-driven tier and boss-wave state for a single gameplay session.
///
/// A value type: `GameScene` holds one `var progression` and mutates it in place.
struct GameProgression {

    // MARK: - Tuning

    /// Minimum score required to reach tiers 2, 3 and 4 respectively.
    static let tierThresholds: [(tier: Int, score: Int)] = [
        (4, 3000),
        (3, 1500),
        (2, 500)
    ]

    /// A boss wave is scheduled every time the score crosses a multiple of this.
    static let bossWaveInterval = 1000

    /// How long a boss wave lasts once started, in seconds.
    let bossWaveDuration: TimeInterval

    // MARK: - State

    private(set) var tier: Int = 1
    private(set) var isBossWaveActive: Bool = false
    private(set) var bossWaveTimeRemaining: TimeInterval = 0

    /// The highest 1000-point boundary that has already spawned a boss wave,
    /// so each boundary triggers exactly once.
    private var lastBossScore: Int = 0

    init(bossWaveDuration: TimeInterval = 15.0) {
        self.bossWaveDuration = bossWaveDuration
    }

    // MARK: - Tier

    /// The tier a given score maps to (pure; does not mutate state).
    static func tier(forScore score: Int) -> Int {
        for threshold in tierThresholds where score >= threshold.score {
            return threshold.tier
        }
        return 1
    }

    /// Recompute the tier for `score`. Returns the new tier **only if it
    /// changed** (so the caller can play the tier-advance effect once), else nil.
    mutating func advanceTier(forScore score: Int) -> Int? {
        let newTier = Self.tier(forScore: score)
        guard newTier != tier else { return nil }
        tier = newTier
        return newTier
    }

    // MARK: - Boss wave

    /// Whether `score` crosses a new boss-wave boundary that should start a wave
    /// now (not already active). Records the boundary so it fires only once —
    /// call this exactly once per state update and start the wave when it's true.
    mutating func shouldStartBossWave(forScore score: Int) -> Bool {
        let boundary = (score / Self.bossWaveInterval) * Self.bossWaveInterval
        guard boundary > 0, boundary > lastBossScore, !isBossWaveActive else { return false }
        lastBossScore = boundary
        return true
    }

    /// Begin the boss wave and start its countdown.
    mutating func startBossWave() {
        isBossWaveActive = true
        bossWaveTimeRemaining = bossWaveDuration
    }

    /// Advance the boss-wave countdown by `delta` seconds. Returns `true`
    /// exactly once — on the tick the wave ends — so the caller can play the
    /// "survived" reward and restore speed.
    mutating func tickBossWave(delta: TimeInterval) -> Bool {
        guard isBossWaveActive else { return false }
        bossWaveTimeRemaining -= delta
        guard bossWaveTimeRemaining <= 0 else { return false }
        isBossWaveActive = false
        bossWaveTimeRemaining = 0
        return true
    }

    /// End any active boss wave immediately without a reward (used on game over).
    mutating func cancelBossWave() {
        isBossWaveActive = false
        bossWaveTimeRemaining = 0
    }

    // MARK: - Lifecycle

    /// Reset to the tier-1, no-boss starting state for a new game.
    mutating func reset() {
        tier = 1
        isBossWaveActive = false
        bossWaveTimeRemaining = 0
        lastBossScore = 0
    }
}
