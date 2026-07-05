//
//  NebulaSystem.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Renders 7–8 vivid arcade-colored nebulae (cyan, magenta, yellow) using
//  additive blending so they glow against the dark background rather than
//  muddying it. Each nebula independently pulses in scale and alpha and
//  drifts slowly downward for a parallax depth effect.
//

import SpriteKit

@MainActor
class NebulaSystem: SKNode {

    private var nebulae: [SKSpriteNode] = []

    // Vibrant arcade nebula colors — additive blending makes these pop
    private let nebulaColors: [UIColor] = [
        UIColor(red: 0.0,  green: 0.9,  blue: 1.0,  alpha: 1.0), // cyan
        UIColor(red: 1.0,  green: 0.0,  blue: 0.9,  alpha: 1.0), // magenta
        UIColor(red: 1.0,  green: 0.9,  blue: 0.0,  alpha: 1.0), // yellow-gold
        UIColor(red: 0.25, green: 1.0,  blue: 0.5,  alpha: 1.0), // neon green
        UIColor(red: 0.5,  green: 0.0,  blue: 1.0,  alpha: 1.0), // violet
        UIColor(red: 0.0,  green: 0.9,  blue: 1.0,  alpha: 1.0), // cyan (repeat for weight)
        UIColor(red: 1.0,  green: 0.0,  blue: 0.9,  alpha: 1.0), // magenta (repeat)
    ]

    func setupNebulae(for size: CGSize) {
        let nebulaCount = 7

        for i in 0..<nebulaCount {
            let nebula = createNebula(size: size, index: i)
            // Distribute across the full scene height (including off-screen spawning area)
            nebula.position = CGPoint(
                x: CGFloat.random(in: size.width * 0.05 ... size.width * 0.95),
                y: CGFloat.random(in: size.height * 0.1 ... size.height * 1.8)
            )
            nebula.name = "nebula_\(i)"
            nebulae.append(nebula)
            addChild(nebula)
        }
    }

    private func createNebula(size: CGSize, index: Int) -> SKSpriteNode {
        let nebulaWidth  = CGFloat.random(in: size.width * 0.25 ... size.width * 0.65)
        let nebulaHeight = CGFloat.random(in: size.height * 0.12 ... size.height * 0.30)
        let nebulaSize   = CGSize(width: nebulaWidth, height: nebulaHeight)

        let color   = nebulaColors[index % nebulaColors.count]
        let nebula  = SKSpriteNode(color: color, size: nebulaSize)
        nebula.blendMode = .add
        nebula.alpha     = CGFloat.random(in: 0.04 ... 0.10)

        // Gentle slow rotation
        let duration = Double.random(in: 80...160)
        nebula.run(SKAction.repeatForever(
            SKAction.rotate(byAngle: .pi * 2, duration: duration)
        ))

        // Breathing pulse (scale + alpha, staggered by index)
        let delay    = Double(index) * 1.3
        let pulseDur = Double.random(in: 6 ... 11)
        let baseAlpha = nebula.alpha
        let pulseSeq = SKAction.sequence([
            SKAction.wait(forDuration: delay),
            SKAction.repeatForever(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 1.08, duration: pulseDur),
                    SKAction.fadeAlpha(to: baseAlpha * 1.9, duration: pulseDur)
                ]),
                SKAction.group([
                    SKAction.scale(to: 0.94, duration: pulseDur),
                    SKAction.fadeAlpha(to: baseAlpha * 0.5, duration: pulseDur)
                ])
            ]))
        ])
        nebula.run(pulseSeq)

        return nebula
    }

    func startAnimation() {
        // Animations already started in createNebula — no extra work needed
    }

    func update(deltaTime: TimeInterval) {
        let scrollSpeed: CGFloat = 18.0 * CGFloat(deltaTime)

        for nebula in nebulae {
            nebula.position.y -= scrollSpeed

            if nebula.position.y < -200 {
                nebula.position.y = kViewSize.height + CGFloat.random(in: 100...300)
                nebula.position.x = CGFloat.random(in: kViewSize.width * 0.05 ... kViewSize.width * 0.95)
            }
        }
    }
}
