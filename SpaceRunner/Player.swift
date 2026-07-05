//
//  Player.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  The player-controlled spaceship. Moves smoothly toward the last touch
//  location using linear interpolation, maintains lives and score state,
//  and responds to meteor collisions and star pickups.
//
//  RESPONSIBILITIES
//  - init()                         — load Player texture, configure circular physics body
//  - update()                       — lerp position toward targetLocation each frame
//  - updateTargetLocation(newLocation:) — set the destination from a touch event
//  - enableMovement() / disableMovement() — toggle touch-following (tutorial vs gameplay)
//  - hitMeteor()                    — decrement lives, trigger invincibility flash
//  - collectStar()                  — increment score; used by GameScene on star contact
//  - gameOver()                     — freeze the ship and remove physics body
//  - startEnhancedEngineEffects() / stopEnhancedEngineEffects() — delegate to
//      Player+EnhancedEffects extension for multi-layer engine trail particles
//  - lives / score properties accessed by GameScene for state tracking
//

import Foundation
import SpriteKit

class Player: SKSpriteNode {
    
    // MARK: - Private class constants
    fileprivate let touchOffset: CGFloat = kDeviceTablet ? 64.0 : 32.0
    fileprivate let filter: CGFloat = 0.12

    // MARK: - Private class variables
    fileprivate var targetPosition = CGPoint()
    fileprivate var canMove = false
    fileprivate var streakCount: Int = 0

    // Horizontal velocity tracking for ship banking
    fileprivate var lastFrameX: CGFloat = 0

    // Dash mechanic
    private(set) var isDashing = false
    private(set) var dashChargeAvailable = true
    private var dashRechargeTimer: TimeInterval = 0
    fileprivate var dashVelocity = CGPoint.zero

    // MARK: - Public class variables
    internal var score: Int = 0
    internal var lives: Int = 3
    internal var immune = false
    internal var starsCollected: Int = 0
    internal var highStreak: Int = 0
    /// Set by GameScene when a shield power-up is active.
    internal var hasShield = false
    
    // MARK: - Init
    required init?(coder aDecoder:NSCoder){
        super.init(coder: aDecoder)
    }
    
    fileprivate override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    convenience init() {
        let texture = GameTextures.sharedInstance.textureWithName(name: SpriteName.Player)
        self.init(texture: texture, color: SKColor.white, size: texture.size())
        
        self.setupPlayer()
        self.setupPlayerPhysics()
        self.setupEngineParticles()
    }
    
    // MARK: - Setup
    fileprivate func setupEngineParticles() {
        // Create realistic rocket flame with layered particles
        // Layer 1: Outer green flame (coolest)
        let engineFlameOuter = GameParticles.sharedInstance.createParticle(particles: GameParticles.Particles.engineFlameOuter)
        engineFlameOuter.position = CGPoint(x: 0, y: -self.size.height * 0.4)
        engineFlameOuter.zPosition = self.zPosition - 3
        self.addChild(engineFlameOuter)
        
        // Layer 2: Yellow/orange core flame (medium heat)
        let engineFlameCore = GameParticles.sharedInstance.createParticle(particles: GameParticles.Particles.engineFlameCore)
        engineFlameCore.position = CGPoint(x: 0, y: -self.size.height * 0.35)
        engineFlameCore.zPosition = self.zPosition - 2
        self.addChild(engineFlameCore)
        
        // Layer 3: Red hot center (hottest)
        let engineFlameRed = GameParticles.sharedInstance.createParticle(particles: GameParticles.Particles.engineRed)
        engineFlameRed.position = CGPoint(x: 0, y: -self.size.height * 0.3)
        engineFlameRed.zPosition = self.zPosition - 1
        self.addChild(engineFlameRed)
    }
    
    fileprivate func setupPlayer() {
        position = CGPoint(x: kViewSize.width / 2, y: kViewSize.height * 0.2)
        targetPosition = position
        lastFrameX = position.x
        zPosition = GameLayer.Player
    }
    
    fileprivate func setupPlayerPhysics() {
        self.physicsBody = SKPhysicsBody(circleOfRadius: self.size.width / 2, center: self.anchorPoint)
        self.physicsBody?.allowsRotation = false
        self.physicsBody?.categoryBitMask = Contact.Player
        self.physicsBody?.collisionBitMask = Contact.Scene
        self.physicsBody?.contactTestBitMask = Contact.Meteor | Contact.Star
        
    }
    
    // MARK: - Update
    func update() {
        if self.canMove {
            self.move()
        }
    }
    
    // MARK: - Movement
    func updateTargetLocation(newLocation: CGPoint) {
        // set the targetLocation to the newLocation with the Y position adjusted by touchOffset
        self.targetPosition = CGPoint(x: newLocation.x, y: newLocation.y + self.touchOffset)
        
        // Draw the touch circle
        let touchCircle = TouchCircle()
        self.parent?.addChild(touchCircle)
        touchCircle.animateTouchCircle(atPosition: self.targetPosition)
    }
    
    // MARK: - Enable/Disable Movement
    func enableMovement() {
        self.canMove = true
    }

    func disableMovement() {
        self.canMove = false
    }

    // MARK: - Tilt Navigation
    /// Applies gyroscope tilt deltas to the target position each frame.
    /// Works alongside touch input: touch sets an absolute target; tilt nudges it
    /// continuously. Both inputs feed into the same lerp-smoothed movement system.
    ///
    /// - Parameters:
    ///   - tiltX: Normalised roll tilt in [-1, 1]. Positive = phone tilted right.
    ///   - tiltY: Normalised pitch tilt in [-1, 1]. Positive = phone tilted back.
    ///   - deltaTime: Seconds elapsed since last frame.
    ///   - sensitivity: Points per second at full tilt. Defaults to 320.
    func applyTilt(tiltX: CGFloat, tiltY: CGFloat, deltaTime: TimeInterval, sensitivity: CGFloat = 320.0) {
        guard canMove else { return }
        let dx = tiltX * sensitivity * CGFloat(deltaTime)
        let dy = tiltY * sensitivity * CGFloat(deltaTime)
        let margin = size.width * 0.5
        targetPosition.x = min(max(targetPosition.x + dx, margin), kViewSize.width - margin)
        targetPosition.y = min(max(targetPosition.y + dy, touchOffset), kViewSize.height - margin)
    }

    fileprivate func move() {
        // Lerp toward touch/tilt target
        let lerpX = Smooth(startPoint: position.x, endPoint: targetPosition.x, filter: filter)
        let lerpY = Smooth(startPoint: position.y, endPoint: targetPosition.y, filter: filter)

        // Layer dash velocity on top and clamp to screen bounds
        let margin = size.width * 0.5
        let rawX = lerpX + dashVelocity.x
        let rawY = lerpY + dashVelocity.y
        let clampedX = max(margin, min(rawX, kViewSize.width - margin))
        let clampedY = max(kViewSize.height * 0.08, min(rawY, kViewSize.height * 0.90))

        // Bank ship based on horizontal movement speed (max ±8°)
        let horizontalDelta = clampedX - position.x
        let maxBankAngle: CGFloat = 0.14
        let rawBank = -(horizontalDelta / max(size.width * 0.06, 1)) * maxBankAngle
        let targetBank = max(-maxBankAngle, min(rawBank, maxBankAngle))
        zRotation = Smooth(startPoint: zRotation, endPoint: targetBank, filter: 0.15)

        position = CGPoint(x: clampedX, y: clampedY)
        lastFrameX = clampedX

        // Decay dash velocity each frame
        if dashVelocity != .zero {
            dashVelocity.x *= 0.82
            dashVelocity.y *= 0.82
            if abs(dashVelocity.x) < 0.3 && abs(dashVelocity.y) < 0.3 {
                dashVelocity = .zero
            }
        }
    }

    // MARK: - Dash
    func dash(toward direction: CGPoint) {
        guard dashChargeAvailable, canMove else { return }

        let magnitude = sqrt(direction.x * direction.x + direction.y * direction.y)
        guard magnitude > 1 else { return }
        let norm = CGPoint(x: direction.x / magnitude, y: direction.y / magnitude)

        isDashing = true
        dashChargeAvailable = false
        immune = true
        dashRechargeTimer = 6.0
        dashVelocity = CGPoint(x: norm.x * 32, y: norm.y * 32)

        createBoostEffect()

        // End i-frames after dash completes (velocity decays in ~0.3 s)
        run(SKAction.wait(forDuration: 0.30)) { [weak self] in
            self?.isDashing = false
            self?.run(SKAction.wait(forDuration: 0.12)) {
                if self?.alpha == 1.0 { self?.immune = false }
            }
        }
    }

    func updateDash(deltaTime: TimeInterval) {
        if !dashChargeAvailable {
            dashRechargeTimer -= deltaTime
            if dashRechargeTimer <= 0 {
                dashChargeAvailable = true
                dashRechargeTimer = 0
            }
        }
        // Recharge progress 0→1 over 6s; 1.0 when ready
        let progress = dashChargeAvailable ? 1.0 : CGFloat(1.0 - (dashRechargeTimer / 6.0))
        updateDashIndicator(available: dashChargeAvailable, rechargeProgress: progress)
    }
    
    // MARK: - Update Score
    func updatePlayerScore(score: Int) {
        self.score += score
    }
    
    // MARK: - Update Lives
    fileprivate func updatePlayerLives() {
        self.lives -= 1
    }
    
    // MARK: - Actions
    fileprivate func blinkPlayer() {
        let blink = SKAction.sequence([SKAction.fadeOut(withDuration: 0.15), SKAction.fadeIn(withDuration: 0.15)])
        self.run(SKAction.repeatForever(blink), withKey: "Blink")
    }
    
    
    // MARK: - Contact
    // Actions for when player contacts meteor
    func hitMeteor() {
        // subtract from lives
        self.updatePlayerLives()
        
        // Set the streakCount back to 0
        self.streakCount = 0
        
        // Does the player have any lives left?
        if self.lives > 0 {
            // Make the player immune
            self.immune = true
            
            // Blink the player to show immunity
            self.blinkPlayer()
            
            GameAudio.shared.playSoundEffect(.shieldUp)
            
            // In 3 seconds remove the immunity and the blink action
            self.run(SKAction.wait(forDuration: 3.0), completion: {
                self.immune = false
                self.removeAction(forKey: "Blink")
                GameAudio.shared.playSoundEffect(.shieldDown)
            })
        }
    }
    
    // MARK: - Pickup
    fileprivate func checkStreak(streak:Int) {
        if streak > self.highStreak {
            self.highStreak = streak
        }
    }
    
    func pickedUpStar() {
        self.starsCollected += 1
        self.streakCount += 1
            
        self.checkStreak(streak: self.streakCount)
        
        var bonus = ""
        let bonusLabel = GameFonts.shared.createLabel(string: bonus, labelType: GameFonts.LabelType.bonus)
        
        switch self.streakCount {
            case 0..<5:
                self.score += 250
                bonus = String(250)
            case 5..<10:
                self.score += 500
                bonus = String(500)
            case 10..<15:
                self.score += 750
                bonus = String( 50)
            case 15..<20:
                self.score += 1000
                bonus = String(1000)
            case 20..<25:
                self.score += 1250
                bonus = String(1250)
            case 25..<30:
                self.score += 1500
                bonus = String(1500)
            case 30..<35:
                self.score += 1750
                bonus = String(1750)
            case 35..<40:
                self.score += 2000
                bonus = String(2000)
            case 40..<45:
                self.score += 2250
                bonus = String(2250)
            case 45..<50:
                self.score += 2500
                bonus = String(2500)
            default:
                self.score += 5000
                bonus = String(5000)
        }
        
        // Float the bonus on scren
        bonusLabel.position = self.position
        bonusLabel.text = bonus
        self.parent?.addChild(bonusLabel)
        bonusLabel.run(GameFonts.shared.animateFloatingLabel(node: bonusLabel))
    }
    
    // MARK: - Check and save best score
    func gameOver() {
        // Apply grayscale shader
        GameShaders.sharedInstance.shadeGray(node: self)
        
        // Update high scores using modern iOS 18+ settings
        let gameSettings = GameSettings.shared
        
        gameSettings.updateBestScore(self.score)
        gameSettings.updateBestStars(self.starsCollected)
        gameSettings.updateBestStreak(self.highStreak)
    }
    
    // MARK: - Reset
    func reset() {
        // Reset player stats to initial values
        score = 0
        lives = 3
        starsCollected = 0
        streakCount = 0
        highStreak = 0
        
        // Reset player state
        immune = false
        hasShield = false
        canMove = false
        isDashing = false
        dashChargeAvailable = true
        dashRechargeTimer = 0
        dashVelocity = .zero

        // Reset position to initial location
        position = CGPoint(x: kViewSize.width / 2, y: kViewSize.height * 0.2)
        targetPosition = position
        lastFrameX = position.x
        zRotation = 0
        
        // Remove any active actions
        removeAllActions()
        
        // Reset visual effects
        alpha = 1.0
        colorBlendFactor = 0.0
        
        // Remove existing flame particles
        children.filter { $0 is SKEmitterNode }.forEach { $0.removeFromParent() }
        
        // Re-setup enhanced engine particles
        setupEngineParticles()
    }
}
