//
//  NebulaSystem.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Renders 7–8 vivid arcade-colored nebulae using radial-gradient textures and
//  additive blending so they glow against the dark background. Each nebula
//  independently pulses in scale and alpha, drifts downward for parallax depth,
//  and wraps back to the top when it exits the bottom.
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
        UIColor(red: 0.0,  green: 0.9,  blue: 1.0,  alpha: 1.0), // cyan (weight)
        UIColor(red: 1.0,  green: 0.0,  blue: 0.9,  alpha: 1.0), // magenta (weight)
    ]

    func setupNebulae(for size: CGSize) {
        for i in 0..<7 {
            let nebula = createNebula(size: size, index: i)
            nebula.position = CGPoint(
                x: CGFloat.random(in: size.width * 0.05 ... size.width * 0.95),
                y: CGFloat.random(in: size.height * 0.1  ... size.height * 1.8)
            )
            nebula.name = "nebula_\(i)"
            nebulae.append(nebula)
            addChild(nebula)
        }
    }

    private func createNebula(size: CGSize, index: Int) -> SKSpriteNode {
        let nebulaW = CGFloat.random(in: size.width  * 0.28 ... size.width  * 0.70)
        let nebulaH = CGFloat.random(in: size.height * 0.14 ... size.height * 0.32)
        let nebulaSize = CGSize(width: nebulaW, height: nebulaH)

        let color   = nebulaColors[index % nebulaColors.count]
        let texture = makeNebulaTexture(size: nebulaSize, color: color)
        let nebula  = SKSpriteNode(texture: texture, size: nebulaSize)
        nebula.blendMode = .add
        nebula.alpha     = CGFloat.random(in: 0.20 ... 0.50)

        // Gentle slow rotation
        let rotateDur = Double.random(in: 80...160)
        nebula.run(SKAction.repeatForever(
            SKAction.rotate(byAngle: .pi * 2, duration: rotateDur)
        ))

        // Breathing pulse (scale + alpha, staggered by index)
        let delay    = Double(index) * 1.3
        let pulseDur = Double.random(in: 6...11)
        let baseAlpha = nebula.alpha
        nebula.run(SKAction.sequence([
            SKAction.wait(forDuration: delay),
            SKAction.repeatForever(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 1.10, duration: pulseDur),
                    SKAction.fadeAlpha(to: baseAlpha * 1.85, duration: pulseDur)
                ]),
                SKAction.group([
                    SKAction.scale(to: 0.92, duration: pulseDur),
                    SKAction.fadeAlpha(to: baseAlpha * 0.45, duration: pulseDur)
                ])
            ]))
        ]))

        return nebula
    }

    // Radial gradient from solid color center → transparent edge.
    // This makes nebulae look like real diffuse gas clouds rather than rectangles.
    private func makeNebulaTexture(size: CGSize, color: UIColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let center  = CGPoint(x: size.width / 2, y: size.height / 2)
            // Use the longer axis as the outer radius so the gradient fills the shape
            let outerR  = max(size.width, size.height) / 2
            let innerR  = outerR * 0.05

            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    color.withAlphaComponent(1.0).cgColor,
                    color.withAlphaComponent(0.55).cgColor,
                    color.withAlphaComponent(0.0).cgColor
                ] as CFArray,
                locations: [0.0, 0.35, 1.0]) else { return }

            ctx.cgContext.drawRadialGradient(
                gradient,
                startCenter: center, startRadius: innerR,
                endCenter:   center, endRadius:   outerR,
                options:     [.drawsAfterEndLocation])
        }
        return SKTexture(image: image)
    }

    func startAnimation() {
        // Animations already started in createNebula
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
