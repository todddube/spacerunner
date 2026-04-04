//
//  NebulaSystem.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Renders a collection of softly glowing nebula sprites that drift and pulse
//  in the background, adding atmospheric depth beyond the star-field layers.
//
//  RESPONSIBILITIES
//  - setupNebulae(for:)  — spawn randomised nebula sprites across the scene
//  - startAnimation()    — begin per-nebula drift, rotation, and alpha pulse loops
//  - update(deltaTime:)  — advance any time-driven nebula state each frame
//  - Each nebula is placed at a randomised position, colour-tinted, and given
//      independent timing to prevent visual repetition
//

import SpriteKit

@MainActor
class NebulaSystem: SKNode {
    
    private var nebulae: [SKSpriteNode] = []
    private let nebulaColors: [UIColor] = [
        UIColor(red: 0.5, green: 0.2, blue: 0.8, alpha: 0.3),  // Purple
        UIColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 0.3),  // Blue
        UIColor(red: 0.8, green: 0.3, blue: 0.5, alpha: 0.3),  // Pink
        UIColor(red: 0.3, green: 0.8, blue: 0.6, alpha: 0.3)   // Cyan
    ]
    
    func setupNebulae(for size: CGSize) {
        let nebulaCount = 4
        
        for i in 0..<nebulaCount {
            let nebula = createNebula(size: size)
            nebula.position = CGPoint(
                x: CGFloat.random(in: -100...size.width + 100),
                y: CGFloat.random(in: size.height...size.height * 2)
            )
            nebula.name = "nebula_\(i)"
            nebulae.append(nebula)
            addChild(nebula)
        }
    }
    
    private func createNebula(size: CGSize) -> SKSpriteNode {
        // Create a large, soft cloud shape
        let nebulaSize = CGSize(
            width: CGFloat.random(in: 200...400),
            height: CGFloat.random(in: 150...300)
        )
        
        let nebula = SKSpriteNode(color: nebulaColors.randomElement() ?? nebulaColors[0], size: nebulaSize)
        
        // Create soft edges using blend mode
        nebula.blendMode = .alpha
        nebula.alpha = 0.2
        
        // Add subtle rotation
        let rotateAction = SKAction.rotate(byAngle: .pi * 2, duration: Double.random(in: 60...120))
        nebula.run(SKAction.repeatForever(rotateAction))
        
        // Add gentle floating motion
        let floatUp = SKAction.moveBy(x: CGFloat.random(in: -20...20), y: 30, duration: Double.random(in: 8...15))
        let floatDown = SKAction.moveBy(x: CGFloat.random(in: -20...20), y: -30, duration: Double.random(in: 8...15))
        let float = SKAction.sequence([floatUp, floatDown])
        nebula.run(SKAction.repeatForever(float))
        
        return nebula
    }
    
    func startAnimation() {
        // Additional pulsing animation for nebulae
        for nebula in nebulae {
            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.4, duration: Double.random(in: 3...8)),
                SKAction.fadeAlpha(to: 0.1, duration: Double.random(in: 3...8))
            ])
            nebula.run(SKAction.repeatForever(pulse))
        }
    }
    
    func update(deltaTime: TimeInterval) {
        // Slowly move nebulae downward for parallax effect
        let scrollSpeed: CGFloat = 15.0 * CGFloat(deltaTime)
        
        for nebula in nebulae {
            nebula.position.y -= scrollSpeed
            
            // Reset position when off screen
            if nebula.position.y < -200 {
                nebula.position.y = kViewSize.height + 200
                nebula.position.x = CGFloat.random(in: -100...kViewSize.width + 100)
            }
        }
    }
}