//
//  AnimationController.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Central hub for reusable SKAction sequences used across the UI. Keeps
//  animation logic out of scene and node files and makes timing adjustments
//  easy to apply globally.
//
//  TRANSITION TYPES  (AnimationController.TransitionType)
//  .springAnimation  — scale-up spring effect for showing elements
//  .scaleDown        — shrink to zero for hiding elements
//  .fadeOut          — fade alpha to 0
//  .slideFromTop     — move down from above screen with easeOut
//
//  AMBIENT ANIMATIONS
//  - startAmbientUIAnimations(for:) — attach subtle breathing / float loops to
//      UI nodes tagged with known names inside the given parent node
//  - update(deltaTime:)             — advance any time-based animation state
//
//  REQUIRES @MainActor — all SKAction and node mutations on the main thread
//

import SpriteKit

@MainActor
class AnimationController: NSObject {
    
    private var activeAnimations: [String: SKAction] = [:]
    
    // MARK: - UI Element Animations
    
    enum TransitionType {
        case fadeIn
        case fadeOut
        case slideFromTop
        case slideFromBottom
        case scaleUp
        case scaleDown
        case springAnimation
        
        var action: SKAction {
            switch self {
            case .fadeIn:
                return SKAction.sequence([
                    SKAction.fadeAlpha(to: 0, duration: 0),
                    SKAction.fadeIn(withDuration: 0.5)
                ])
            case .fadeOut:
                return SKAction.fadeOut(withDuration: 0.3)
            case .slideFromTop:
                return SKAction.sequence([
                    SKAction.moveBy(x: 0, y: 100, duration: 0),
                    SKAction.moveBy(x: 0, y: -100, duration: 0.6)
                ])
            case .slideFromBottom:
                return SKAction.sequence([
                    SKAction.moveBy(x: 0, y: -100, duration: 0),
                    SKAction.moveBy(x: 0, y: 100, duration: 0.6)
                ])
            case .scaleUp:
                return SKAction.sequence([
                    SKAction.scale(to: 0.1, duration: 0),
                    SKAction.scale(to: 1.0, duration: 0.4)
                ])
            case .scaleDown:
                return SKAction.scale(to: 0.1, duration: 0.3)
            case .springAnimation:
                return TransitionType.createSpringAnimation()
            }
        }
        
        private static func createSpringAnimation() -> SKAction {
            let scaleUp = SKAction.scale(to: 1.2, duration: 0.2)
            scaleUp.timingMode = .easeOut
            let scaleBack = SKAction.scale(to: 0.95, duration: 0.15)
            scaleBack.timingMode = .easeInEaseOut
            let scaleNormal = SKAction.scale(to: 1.0, duration: 0.1)
            scaleNormal.timingMode = .easeOut
            
            return SKAction.sequence([scaleUp, scaleBack, scaleNormal])
        }
    }
    
    func startAmbientUIAnimations(for node: SKNode) {
        // Add subtle breathing animation to UI elements
        let breathe = SKAction.sequence([
            SKAction.scale(to: 1.02, duration: 2.5),
            SKAction.scale(to: 0.98, duration: 2.5)
        ])
        
        node.run(SKAction.repeatForever(breathe), withKey: "breathe")
    }
    
    func createPulseAnimation(scale: CGFloat = 1.1, duration: TimeInterval = 1.0) -> SKAction {
        let scaleUp = SKAction.scale(to: scale, duration: duration / 2)
        scaleUp.timingMode = .easeInEaseOut
        let scaleDown = SKAction.scale(to: 1.0, duration: duration / 2)
        scaleDown.timingMode = .easeInEaseOut
        
        return SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown]))
    }
    
    func createFloatingAnimation(distance: CGFloat = 10, duration: TimeInterval = 2.0) -> SKAction {
        let moveUp = SKAction.moveBy(x: 0, y: distance, duration: duration / 2)
        moveUp.timingMode = .easeInEaseOut
        let moveDown = SKAction.moveBy(x: 0, y: -distance, duration: duration / 2)
        moveDown.timingMode = .easeInEaseOut
        
        return SKAction.repeatForever(SKAction.sequence([moveUp, moveDown]))
    }
    
    func createRotationAnimation(angle: CGFloat = .pi * 2, duration: TimeInterval = 4.0) -> SKAction {
        let rotate = SKAction.rotate(byAngle: angle, duration: duration)
        rotate.timingMode = .linear
        
        return SKAction.repeatForever(rotate)
    }
    
    // MARK: - Button Animations
    
    func animateButtonPress(_ button: SKNode, completion: @escaping () -> Void = {}) {
        let scaleDown = SKAction.scale(to: 0.9, duration: 0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        
        button.run(SKAction.sequence([scaleDown, scaleUp])) {
            completion()
        }
    }
    
    func animateButtonHover(_ button: SKNode, isHovering: Bool) {
        let targetScale: CGFloat = isHovering ? 1.05 : 1.0
        let scaleAction = SKAction.scale(to: targetScale, duration: 0.2)
        scaleAction.timingMode = .easeInEaseOut
        
        button.run(scaleAction)
    }
    
    // MARK: - Score Animations
    
    func animateScoreIncrease(_ label: SKLabelNode, from oldValue: Int, to newValue: Int) {
        // Number counting animation
        let duration: TimeInterval = 0.5
        let steps = 20
        
        for i in 0...steps {
            let delay = duration * Double(i) / Double(steps)
            let progress = Double(i) / Double(steps)
            let currentValue = oldValue + Int(Double(newValue - oldValue) * progress)
            
            let waitAction = SKAction.wait(forDuration: delay)
            let updateAction = SKAction.run {
                label.text = "\(currentValue)"
            }
            
            label.run(SKAction.sequence([waitAction, updateAction]))
        }
        
        // Add scale pulse for emphasis
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.4)
        ])
        label.run(pulse)
    }
    
    // MARK: - Transition Effects
    
    func crossFadeTransition(from fromNode: SKNode, to toNode: SKNode, duration: TimeInterval = 0.5) {
        let fadeOut = SKAction.fadeOut(withDuration: duration / 2)
        let fadeIn = SKAction.fadeIn(withDuration: duration / 2)
        
        toNode.alpha = 0
        toNode.isHidden = false
        
        fromNode.run(fadeOut) {
            fromNode.isHidden = true
        }
        
        toNode.run(SKAction.sequence([
            SKAction.wait(forDuration: duration / 2),
            fadeIn
        ]))
    }
    
    func slideTransition(node: SKNode, direction: CGVector, duration: TimeInterval = 0.5) {
        let move = SKAction.moveBy(x: direction.dx, y: direction.dy, duration: duration)
        move.timingMode = .easeInEaseOut
        
        node.run(move)
    }
    
    // MARK: - Particle-like UI Effects
    
    func createSparkleEffect(at position: CGPoint, in parent: SKNode) {
        for _ in 0..<5 {
            let sparkle = SKSpriteNode(color: .yellow, size: CGSize(width: 2, height: 2))
            sparkle.position = position
            parent.addChild(sparkle)
            
            let randomX = CGFloat.random(in: -50...50)
            let randomY = CGFloat.random(in: -50...50)
            let move = SKAction.moveBy(x: randomX, y: randomY, duration: 1.0)
            let fade = SKAction.fadeOut(withDuration: 1.0)
            let remove = SKAction.removeFromParent()
            
            sparkle.run(SKAction.sequence([
                SKAction.group([move, fade]),
                remove
            ]))
        }
    }
    
    // MARK: - Update Loop
    
    func update(deltaTime: TimeInterval) {
        // Update any time-based animations if needed
        // This can be used for custom animation timing
    }
}