//
//  StatusBar+GlassEffect.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Entrance / exit animations and reactive event animations for StatusBar.
//  The glass background itself is built in StatusBar.swift during init.
//
//  SHOW / HIDE
//  - show(with:)  — fades in and slides down from above the safe area
//  - hide(with:)  — fades out and slides up, then hides the node
//
//  REACTIVE ANIMATIONS (called by GameScene on game events)
//  - animateScoreUpdate(newScore:)  — scale pulse + cyan flash on the score label
//  - animateStarCollection()        — bounce + brief glow on the star icon
//  - animateLifeLoss()              — shake the lives section
//

import SpriteKit

extension StatusBar {

    // MARK: - Compatibility stub
    // Glass is now built in StatusBar.init — this is kept so GameScene callers
    // don't need to be updated immediately.
    func applyGlassEffect() { }

    // MARK: - Show / Hide

    func show(with transition: AnimationController.TransitionType) {
        isHidden = false
        alpha    = 0
        // Start 20 pt above final position, then slide down
        position.y += 20
        let fadeIn    = SKAction.fadeIn(withDuration: 0.45)
        let slideDown = SKAction.moveBy(x: 0, y: -20, duration: 0.45)
        slideDown.timingMode = .easeOut
        run(SKAction.group([fadeIn, slideDown]))
    }

    func hide(with transition: AnimationController.TransitionType) {
        let fadeOut  = SKAction.fadeOut(withDuration: 0.30)
        let slideUp  = SKAction.moveBy(x: 0, y: 20, duration: 0.30)
        slideUp.timingMode = .easeIn
        run(SKAction.group([fadeOut, slideUp])) { [weak self] in
            self?.isHidden = true
        }
    }

    // MARK: - Reactive Animations

    func animateScoreUpdate(newScore: Int) {
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.20, duration: 0.08),
            SKAction.scale(to: 1.00, duration: 0.14)
        ])
        let flashColor = UIColor(red: 0.30, green: 1.00, blue: 1.00, alpha: 1.0)
        let originalColor = scoreLabel.fontColor
        let flash = SKAction.sequence([
            SKAction.run { [weak self] in self?.scoreLabel.fontColor = flashColor },
            SKAction.wait(forDuration: 0.18),
            SKAction.run { [weak self] in self?.scoreLabel.fontColor = originalColor }
        ])
        scoreLabel.run(SKAction.group([pulse, flash]))
    }

    func animateStarCollection() {
        starIcon.run(bounce())
        // Brief yellow glow copy that expands and fades
        if let parent = starIcon.parent {
            let glow = starIcon.copy() as! SKSpriteNode
            glow.alpha = 0.7
            glow.setScale(starIcon.xScale * 2.0)
            glow.blendMode = .add
            glow.position = starIcon.position
            glow.zPosition = starIcon.zPosition - 1
            parent.addChild(glow)
            glow.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.30),
                SKAction.removeFromParent()
            ]))
        }
    }

    func animateLifeLoss() {
        let shake = SKAction.sequence([
            SKAction.moveBy(x:  3, y: 0, duration: 0.05),
            SKAction.moveBy(x: -6, y: 0, duration: 0.05),
            SKAction.moveBy(x:  6, y: 0, duration: 0.05),
            SKAction.moveBy(x: -3, y: 0, duration: 0.05)
        ])
        livesContainer.run(shake)
    }
}
