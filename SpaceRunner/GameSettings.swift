//
//  GameSettings.swift
//  SpaceRunner
//
//  Created by Todd Dube on 3/25/16.
//  Copyright © 2020 Todd Dube. All rights reserved.
//

import Foundation

let GameSettingsSharedInstance = GameSettings()

class GameSettings {
    class var sharedInstance:GameSettings {
        return GameSettingsSharedInstance
    }
    
    // MARK: - Private class constants
    fileprivate let localDefaults = UserDefaults.standard
    fileprivate let keyFirstRun = "FirstRun"
    fileprivate let keyBestScore = "BestScore"
    fileprivate let keyBestStars = "BestStars"
    fileprivate let keyBestStreak = "BestStreak"
    
    // MARK: - Init
    init() {
        if self.localDefaults.object(forKey: keyFirstRun) == nil {
            self.firstLaunch()
        }
    }
    
    // MARK: - Private Functions
    fileprivate func firstLaunch() {
        self.localDefaults.set(0, forKey: self.keyBestScore)
        self.localDefaults.set(false, forKey: self.keyFirstRun)
        self.localDefaults.set(0, forKey: self.keyBestStars)
        self.localDefaults.set(0, forKey: self.keyBestStreak)
        self.localDefaults.synchronize()
    }
    
    // MARK: - Public saving functions
    func saveBestScore(score: Int) {
        self.localDefaults.set(score, forKey: self.keyBestScore)
        self.localDefaults.synchronize()
    }
    
    func saveBestStars(stars: Int) {
        self.localDefaults.set(stars, forKey: self.keyBestStars)
        self.localDefaults.synchronize()
    }
    
    func saveBestStreak(streak: Int) {
        self.localDefaults.set(streak, forKey: self.keyBestStreak)
        self.localDefaults.synchronize()
    }
    
    
    // MARK: - Public retrieving functions
    func getBestScore() -> Int {
        return self.localDefaults.integer(forKey: self.keyBestScore)
    }
    
    func getBestStars() -> Int {
        return self.localDefaults.integer(forKey: self.keyBestStars)
    }
    
    func getBestStreak() -> Int {
        return self.localDefaults.integer(forKey: self.keyBestStreak)
    }
}
