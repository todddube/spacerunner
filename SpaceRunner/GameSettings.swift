//
//  GameSettings.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Observable singleton that persists and exposes the player's all-time records.
//  Uses UserDefaults for durable storage and @Observable so SwiftUI / SpriteKit
//  views can react to changes without explicit binding glue.
//
//  PERSISTED VALUES
//  - bestScore   — highest single-run score ever achieved
//  - bestStars   — most stars collected in a single run
//  - bestStreak  — longest consecutive meteor-dodge streak
//
//  RESPONSIBILITIES
//  - updateBestScore(_:)  / updateBestStars(_:) / updateBestStreak(_:)
//      — compare new value against stored best and persist if higher
//  - resetAllStats()      — wipe all persisted records (debug / test use)
//
//  REQUIRES iOS 18.0+  — uses @Observable and @MainActor
//

import Foundation

import Observation

@available(iOS 18.0, *)
@MainActor
@Observable
final class GameSettings {
    static let shared = GameSettings()
    
    // MARK: - Published Properties
    private(set) var bestScore: Int = 0 {
        didSet { UserDefaults.standard.set(bestScore, forKey: Keys.bestScore) }
    }
    
    private(set) var bestStars: Int = 0 {
        didSet { UserDefaults.standard.set(bestStars, forKey: Keys.bestStars) }
    }
    
    private(set) var bestStreak: Int = 0 {
        didSet { UserDefaults.standard.set(bestStreak, forKey: Keys.bestStreak) }
    }
    
    private(set) var isFirstLaunch: Bool = true
    
    // MARK: - Private Constants
    private enum Keys {
        static let firstRun = "FirstRun"
        static let bestScore = "BestScore"
        static let bestStars = "BestStars"
        static let bestStreak = "BestStreak"
    }
    
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Initialization
    private init() {
        loadSettings()
    }
    
    // MARK: - Private Methods
    private func loadSettings() {
        isFirstLaunch = userDefaults.object(forKey: Keys.firstRun) == nil
        
        if isFirstLaunch {
            performFirstLaunchSetup()
        } else {
            bestScore = userDefaults.integer(forKey: Keys.bestScore)
            bestStars = userDefaults.integer(forKey: Keys.bestStars)
            bestStreak = userDefaults.integer(forKey: Keys.bestStreak)
        }
    }
    
    private func performFirstLaunchSetup() {
        bestScore = 0
        bestStars = 0
        bestStreak = 0
        userDefaults.set(false, forKey: Keys.firstRun)
    }
    
    // MARK: - Public Methods
    func updateBestScore(_ newScore: Int) {
        guard newScore > bestScore else { return }
        bestScore = newScore
    }
    
    func updateBestStars(_ newStars: Int) {
        guard newStars > bestStars else { return }
        bestStars = newStars
    }
    
    func updateBestStreak(_ newStreak: Int) {
        guard newStreak > bestStreak else { return }
        bestStreak = newStreak
    }
    
    func resetAllStats() {
        bestScore = 0
        bestStars = 0
        bestStreak = 0
    }
}
