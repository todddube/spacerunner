//
//  ModernStartButton.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Responsive pill-shaped glass button used in the tutorial phase to start
//  gameplay. Width is 42 % of screen width (clamped 180 – 280 pt) and height
//  is device-adaptive, ensuring the button looks correct on every iOS device.
//
//  VISUAL DESIGN
//  - Outer glow ring         — cyan stroke that gently pulses
//  - Glass background        — rounded-rect fill with translucent blue tint
//  - Top-edge shimmer        — subtle white highlight for glass depth
//  - "TAP TO START" label    — AvenirNext-Bold, size scales with device
//
//  RESPONSIBILITIES
//  - setupButton()           — build and lay out all child shape / label nodes
//  - setupGlassEffect()      — start glow pulse and gentle float animation loops
//  - tapRect                 — computed property returning the hit-test CGRect in
//      parent coordinates, used by GameScene.handleTutorialTouch(at:)
//  - show(with:) / hide(with:) — run AnimationController transition actions
//
//  REQUIRES @MainActor — SpriteKit node mutations on the main thread
//

import SpriteKit

@MainActor
class ModernStartButton: SKNode {
    
    private let backgroundNode = SKShapeNode()
    private let titleLabel = SKLabelNode()
    private let glowNode = SKShapeNode()
    private let shimmerNode = SKSpriteNode()   // moving sweep highlight
    
    // Responsive sizing: 34 % of screen width — more compact and fresh
    private var buttonSize: CGSize {
        let width = min(max(kViewSize.width * 0.34, 140), 210)
        let height = kDeviceTablet ? 50.0 : 40.0
        return CGSize(width: width, height: height)
    }
    
    override init() {
        super.init()
        setupButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupButton()
    }
    
    private func setupButton() {
        let size = buttonSize
        let cornerRadius: CGFloat = size.height / 2
        let rect = CGRect(x: -size.width / 2, y: -size.height / 2,
                          width: size.width, height: size.height)
        
        // Outer glow ring — uses the game's cyan (Colors.Magic) palette
        glowNode.path = UIBezierPath(roundedRect: rect.insetBy(dx: -3, dy: -3),
                                     cornerRadius: cornerRadius + 3).cgPath
        glowNode.fillColor = .clear
        glowNode.strokeColor = SKColor(red: 0.02, green: 0.95, blue: 0.87, alpha: 0.42)
        glowNode.lineWidth = 3
        glowNode.zPosition = -1
        addChild(glowNode)

        // Slim pill background — dark teal tint, very translucent
        backgroundNode.path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).cgPath
        backgroundNode.fillColor = SKColor(red: 0.0, green: 0.18, blue: 0.22, alpha: 0.68)
        backgroundNode.strokeColor = SKColor(red: 0.02, green: 0.95, blue: 0.87, alpha: 0.28)
        backgroundNode.lineWidth = 1.0
        backgroundNode.zPosition = 0
        addChild(backgroundNode)
        
        // Sweeping shimmer beam — starts off left edge, animated in setupGlassEffect()
        // Width is ~18 % of button width so the sweep reads as a crisp light beam
        let beamWidth  = size.width * 0.18
        let beamHeight = size.height * 0.85
        shimmerNode.size  = CGSize(width: beamWidth, height: beamHeight)
        shimmerNode.color = SKColor(white: 1.0, alpha: 0.0) // invisible until setupGlassEffect runs
        shimmerNode.colorBlendFactor = 1.0
        // Start parked off the left edge so first sweep begins cleanly
        shimmerNode.position = CGPoint(x: -size.width / 2 - beamWidth, y: 0)
        shimmerNode.zPosition = 3   // above label so it reads as a surface reflection
        addChild(shimmerNode)
        
        // Title label — small, spaced, cyan-tinted to match game palette
        titleLabel.text = "TAP  TO  START"
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = kDeviceTablet ? 16.0 : 12.0
        titleLabel.fontColor = SKColor(red: 0.02, green: 0.95, blue: 0.87, alpha: 1.0)
        titleLabel.verticalAlignmentMode = .center
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.zPosition = 2
        addChild(titleLabel)
    }
    
    func setupGlassEffect() {
        // ── Glow ring pulse ──────────────────────────────────────────────────
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.18, duration: 1.4),
            SKAction.fadeAlpha(to: 0.55, duration: 1.4)
        ])
        glowNode.run(SKAction.repeatForever(pulse))
        
        // ── Gentle float ─────────────────────────────────────────────────────
        let float = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 4, duration: 1.8),
            SKAction.moveBy(x: 0, y: -4, duration: 1.8)
        ])
        run(SKAction.repeatForever(float))
        
        // ── Bidirectional shimmer sweep ───────────────────────────────────────
        // The beam starts just off the left edge and sweeps to just off the right
        // edge, pauses, sweeps back, pauses again, then repeats.
        let size      = buttonSize
        let beamWidth = size.width * 0.18
        let startX    = -size.width / 2 - beamWidth      // parked off left
        let endX      =  size.width / 2 + beamWidth      // parked off right
        let sweepDuration: TimeInterval = 0.85            // speed of each pass
        let pauseDuration: TimeInterval = 2.2             // wait between sweeps
        
        // Fade in as sweep begins, fade out before it stops
        let fadeIn  = SKAction.fadeAlpha(to: 0.32, duration: 0.12)
        let fadeOut = SKAction.fadeAlpha(to: 0.0,  duration: 0.12)
        
        // Left → right pass
        let sweepLR = SKAction.sequence([
            fadeIn,
            SKAction.moveTo(x: endX,   duration: sweepDuration - 0.12 * 2),
            fadeOut,
            SKAction.moveTo(x: endX,   duration: 0)    // ensure position is exact
        ])
        sweepLR.timingMode = .easeInEaseOut
        
        // Right → left pass
        let sweepRL = SKAction.sequence([
            fadeIn,
            SKAction.moveTo(x: startX, duration: sweepDuration - 0.12 * 2),
            fadeOut,
            SKAction.moveTo(x: startX, duration: 0)
        ])
        sweepRL.timingMode = .easeInEaseOut
        
        let shimmerLoop = SKAction.repeatForever(SKAction.sequence([
            SKAction.moveTo(x: startX, duration: 0),   // reset to left edge
            sweepLR,                                    // → right
            SKAction.wait(forDuration: pauseDuration),
            sweepRL,                                    // ← left
            SKAction.wait(forDuration: pauseDuration)
        ]))
        
        shimmerNode.run(shimmerLoop)
    }
    
    // Returns the tap-detection rect in the parent's coordinate space
    var tapRect: CGRect {
        let size = buttonSize
        // Expand hit area slightly for comfortable touch
        let padding: CGFloat = 10
        return CGRect(x: position.x - size.width / 2 - padding,
                      y: position.y - size.height / 2 - padding,
                      width: size.width + padding * 2,
                      height: size.height + padding * 2)
    }
    
    func show(with transition: AnimationController.TransitionType) {
        isHidden = false
        run(transition.action)
    }
    
    func hide(with transition: AnimationController.TransitionType) {
        run(SKAction.sequence([
            transition.action,
            SKAction.run { [weak self] in
                self?.isHidden = true
            }
        ]))
    }
}