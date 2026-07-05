//
//  ParallaxBackground.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Five-layer parallax star-field creating convincing depth and speed.
//  Layers 1–3 are round dot stars scrolling slowly; layers 4–5 are elongated
//  streak sprites (motion-blur look) that scroll fast, amplifying the sense
//  of speed. Layer scroll speeds increase with the current difficulty tier.
//
//  RESPONSIBILITIES
//  - setupLayers(for:)            — create all five tiled layers
//  - startScrolling() / stopScrolling() — toggle continuous scroll
//  - setSpeedMultiplier(_:)       — called by progression system to ramp streaks
//  - update(deltaTime:gameSpeed:) — advance each layer each frame, wrapping tiles
//

import SpriteKit

@MainActor
class ParallaxBackground: SKNode {

    private struct Layer {
        let node: SKNode
        let baseSpeed: CGFloat
        let isStreak: Bool
    }

    private var layers: [Layer] = []
    private var isScrolling = false

    // Multiplier bumped by progression system (e.g. 1.0 → 2.0 at tier 4)
    var speedMultiplier: CGFloat = 1.0

    // MARK: - Setup

    func setupLayers(for size: CGSize) {
        let configs: [(count: Int, dotSize: CGSize, color: UIColor, alpha: CGFloat, speed: CGFloat, isStreak: Bool)] = [
            // Layer 1 — tiny distant dots, very slow
            (50, CGSize(width: 1, height: 1),
             .white, 0.25, 15, false),
            // Layer 2 — small dots, slightly warmer, slow
            (35, CGSize(width: 1.5, height: 1.5),
             UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1), 0.40, 35, false),
            // Layer 3 — medium dots with subtle color, medium
            (22, CGSize(width: 2.5, height: 2.5),
             UIColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 1), 0.60, 70, false),
            // Layer 4 — star streaks, fast
            (18, CGSize(width: 1.5, height: 7),
             UIColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 1), 0.70, 160, true),
            // Layer 5 — wide streaks, fastest — really sells the speed
            (12, CGSize(width: 2, height: 12),
             UIColor(red: 0.6, green: 0.85, blue: 1.0, alpha: 1), 0.55, 280, true),
        ]

        for config in configs {
            let layerNode = createLayer(
                size: size,
                starCount: config.count,
                starSize: config.dotSize,
                color: config.color,
                alpha: config.alpha,
                isStreak: config.isStreak
            )
            let layer = Layer(node: layerNode, baseSpeed: config.speed, isStreak: config.isStreak)
            layers.append(layer)
            addChild(layerNode)
        }
    }

    private func createLayer(size: CGSize, starCount: Int, starSize: CGSize, color: UIColor, alpha: CGFloat, isStreak: Bool) -> SKNode {
        let layerNode = SKNode()
        // Two tiled fields for seamless wrapping
        let field1 = createStarField(size: size, count: starCount, starSize: starSize,
                                     color: color, alpha: alpha, isStreak: isStreak)
        let field2 = createStarField(size: size, count: starCount, starSize: starSize,
                                     color: color, alpha: alpha, isStreak: isStreak)
        field1.position = .zero
        field2.position = CGPoint(x: 0, y: size.height)
        layerNode.addChild(field1)
        layerNode.addChild(field2)
        return layerNode
    }

    private func createStarField(size: CGSize, count: Int, starSize: CGSize, color: UIColor, alpha: CGFloat, isStreak: Bool) -> SKNode {
        let field = SKNode()
        for _ in 0..<count {
            let star = SKSpriteNode(color: color, size: starSize)
            star.alpha = CGFloat.random(in: alpha * 0.6 ... alpha)
            star.blendMode = isStreak ? .add : .alpha
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            if !isStreak {
                // Subtle twinkle on dot stars only
                let twinkleDur = Double.random(in: 1.5...4.0)
                let twinkle = SKAction.sequence([
                    SKAction.fadeAlpha(to: alpha * 0.4, duration: twinkleDur),
                    SKAction.fadeAlpha(to: alpha, duration: twinkleDur)
                ])
                star.run(SKAction.repeatForever(twinkle))
            }
            field.addChild(star)
        }
        return field
    }

    // MARK: - Control

    func startScrolling() {
        isScrolling = true
    }

    func stopScrolling() {
        isScrolling = false
    }

    func setSpeedMultiplier(_ multiplier: CGFloat) {
        speedMultiplier = multiplier
    }

    // MARK: - Update

    func update(deltaTime: TimeInterval, gameSpeed: Float) {
        guard isScrolling else { return }

        let dt = CGFloat(deltaTime)

        for (i, layer) in layers.enumerated() {
            // Streak layers scale with speedMultiplier; dot layers scale less
            let tierScale: CGFloat = layer.isStreak ? speedMultiplier : (1.0 + (speedMultiplier - 1.0) * 0.4)
            let scroll = layer.baseSpeed * tierScale * CGFloat(gameSpeed) * dt
            layer.node.position.y -= scroll

            // Seamless wrap — tile height = kViewSize.height
            if layer.node.position.y <= -kViewSize.height {
                layer.node.position.y = 0
            }
            _ = i // suppress unused warning
        }
    }
}
