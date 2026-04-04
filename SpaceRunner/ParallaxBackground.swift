//
//  ParallaxBackground.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Three-layer parallax star-field that creates convincing depth as the player
//  moves through space. Each layer scrolls at a different speed — far, mid, and
//  near — and wraps seamlessly when it scrolls off the bottom of the screen.
//
//  RESPONSIBILITIES
//  - setupLayers(for:)  — create three tiled star-field layers sized to the scene
//  - startScrolling()   — begin continuous downward scroll per layer speed
//  - stopScrolling()    — halt scroll (used on game over / pause)
//  - update(deltaTime:gameSpeed:) — advance each layer position each frame,
//      wrapping tiles when they exit the bottom of the visible area
//

import SpriteKit

@MainActor
class ParallaxBackground: SKNode {
    
    private struct Layer {
        let node: SKNode
        let speed: CGFloat
        let starCount: Int
        let starSize: CGSize
        let color: UIColor
        let alpha: CGFloat
    }
    
    private var layers: [Layer] = []
    private var isScrolling = false
    
    func setupLayers(for size: CGSize) {
        // Layer 1: Distant stars (slowest)
        let distantLayer = createStarLayer(
            size: size,
            starCount: 40,
            starSize: CGSize(width: 1, height: 1),
            color: .white,
            alpha: 0.3,
            speed: 0.2
        )
        
        // Layer 2: Mid-distance stars
        let midLayer = createStarLayer(
            size: size,
            starCount: 25,
            starSize: CGSize(width: 2, height: 2),
            color: .cyan,
            alpha: 0.5,
            speed: 0.5
        )
        
        // Layer 3: Close stars (fastest)
        let closeLayer = createStarLayer(
            size: size,
            starCount: 15,
            starSize: CGSize(width: 3, height: 3),
            color: .white,
            alpha: 0.8,
            speed: 1.0
        )
        
        layers = [
            Layer(node: distantLayer, speed: 0.2, starCount: 40, starSize: CGSize(width: 1, height: 1), color: .white, alpha: 0.3),
            Layer(node: midLayer, speed: 0.5, starCount: 25, starSize: CGSize(width: 2, height: 2), color: .cyan, alpha: 0.5),
            Layer(node: closeLayer, speed: 1.0, starCount: 15, starSize: CGSize(width: 3, height: 3), color: .white, alpha: 0.8)
        ]
        
        for layer in layers {
            addChild(layer.node)
        }
    }
    
    private func createStarLayer(size: CGSize, starCount: Int, starSize: CGSize, color: UIColor, alpha: CGFloat, speed: CGFloat) -> SKNode {
        let layerNode = SKNode()
        
        // Create two star fields for seamless scrolling
        let field1 = createStarField(size: size, starCount: starCount, starSize: starSize, color: color, alpha: alpha)
        let field2 = createStarField(size: size, starCount: starCount, starSize: starSize, color: color, alpha: alpha)
        
        field1.position = CGPoint(x: 0, y: 0)
        field2.position = CGPoint(x: 0, y: size.height)
        
        layerNode.addChild(field1)
        layerNode.addChild(field2)
        
        return layerNode
    }
    
    private func createStarField(size: CGSize, starCount: Int, starSize: CGSize, color: UIColor, alpha: CGFloat) -> SKNode {
        let field = SKNode()
        
        for _ in 0..<starCount {
            let star = SKSpriteNode(color: color, size: starSize)
            star.alpha = alpha
            
            // Random position
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            
            // Add subtle twinkling
            let twinkle = SKAction.sequence([
                SKAction.fadeAlpha(to: alpha * 0.5, duration: Double.random(in: 1.0...3.0)),
                SKAction.fadeAlpha(to: alpha, duration: Double.random(in: 1.0...3.0))
            ])
            star.run(SKAction.repeatForever(twinkle))
            
            field.addChild(star)
        }
        
        return field
    }
    
    func startScrolling() {
        isScrolling = true
    }
    
    func stopScrolling() {
        isScrolling = false
    }
    
    func update(deltaTime: TimeInterval, gameSpeed: Float) {
        guard isScrolling else { return }
        
        let baseSpeed: CGFloat = 100.0
        let speedMultiplier = CGFloat(gameSpeed)
        
        for layer in layers {
            let scrollSpeed = baseSpeed * layer.speed * speedMultiplier * CGFloat(deltaTime)
            layer.node.position.y -= scrollSpeed
            
            // Reset position for seamless scrolling
            if layer.node.position.y <= -kViewSize.height {
                layer.node.position.y = 0
            }
        }
    }
}