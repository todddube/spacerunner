//
//  PowerUpController.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Spawns PowerUp orbs at tier-scaled intervals and tracks the duration of active
//  power-up effects. GameScene reads the isXxxActive flags each frame to apply
//  effects (shield, star magnet, slow-motion).
//

import Foundation
import SpriteKit

class PowerUpController: SKNode {

    // MARK: - Active-effect state (read by GameScene)

    private(set) var isShieldActive: Bool       = false
    private(set) var isMagnetActive: Bool       = false
    private(set) var isSlowMoActive: Bool       = false

    private(set) var shieldTimeRemaining: TimeInterval = 0
    private(set) var magnetTimeRemaining: TimeInterval = 0
    private(set) var slowMoTimeRemaining: TimeInterval = 0

    // MARK: - Configuration

    /// Updated by GameScene when the score crosses a tier threshold.
    var currentTier: Int = 1

    // MARK: - Private state

    private var spawnTimer: TimeInterval    = 0
    private var sendingPowerUps: Bool       = false

    // MARK: - Init

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override init() {
        super.init()
    }

    // MARK: - Lifecycle

    func startSpawning() {
        sendingPowerUps = true
    }

    func stopSpawning() {
        sendingPowerUps = false
    }

    // MARK: - Update

    func update(delta: TimeInterval) {
        // --- Spawn timer ---
        if sendingPowerUps {
            spawnTimer += delta
            let interval = GameTier.powerUpIntervals[currentTier] ?? 18.0
            if spawnTimer >= interval {
                spawnPowerUp()
                spawnTimer = 0
            }
        }

        // --- Active-effect countdown ---
        if isShieldActive {
            shieldTimeRemaining -= delta
            if shieldTimeRemaining <= 0 { isShieldActive = false; shieldTimeRemaining = 0 }
        }
        if isMagnetActive {
            magnetTimeRemaining -= delta
            if magnetTimeRemaining <= 0 { isMagnetActive = false; magnetTimeRemaining = 0 }
        }
        if isSlowMoActive {
            slowMoTimeRemaining -= delta
            if slowMoTimeRemaining <= 0 { isSlowMoActive = false; slowMoTimeRemaining = 0 }
        }

        // --- Forward delta to child orbs ---
        for node in children {
            if let powerUp = node as? PowerUp {
                powerUp.update(delta: delta)
            }
        }
    }

    // MARK: - Spawn

    private func spawnPowerUp() {
        let type = PowerUpType.allCases.randomElement() ?? .shield
        let orb  = PowerUp(type: type)

        let margin: CGFloat = 40
        let spawnX = RandomFloatRange(min: margin, max: kViewSize.width - margin)
        let spawnY = kViewSize.height * 1.15
        orb.position = CGPoint(x: spawnX, y: spawnY)

        addChild(orb)
    }

    // MARK: - Effect activation

    /// Called by GameScene when the player contacts a PowerUp node.
    func activateEffect(_ type: PowerUpType) {
        switch type {
        case .shield:
            isShieldActive      = true
            shieldTimeRemaining = type.duration
        case .magnet:
            isMagnetActive      = true
            magnetTimeRemaining = type.duration
        case .slowMo:
            isSlowMoActive      = true
            slowMoTimeRemaining = type.duration
        }
    }

    /// Clear all active effects (called on game-over / reset).
    func deactivateAll() {
        isShieldActive      = false
        isMagnetActive      = false
        isSlowMoActive      = false
        shieldTimeRemaining = 0
        magnetTimeRemaining = 0
        slowMoTimeRemaining = 0
    }

    // MARK: - Reset

    func reset() {
        stopSpawning()
        deactivateAll()
        spawnTimer = 0
        removeAllChildren()
    }
}
