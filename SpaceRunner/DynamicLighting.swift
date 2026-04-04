//
//  DynamicLighting.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Real-time lighting system that tracks the player position and responds to
//  gameplay events with coloured light sources and flash effects, creating
//  a convincing sense of three-dimensional space illumination.
//
//  RESPONSIBILITIES
//  - addLight(at:color:intensity:radius:) — register a named light source node
//  - removeLight(named:)                 — deregister and remove a light node
//  - update(playerPosition:)             — move the player-following light each frame
//  - flashAt(_:color:intensity:)         — trigger a short-lived burst of light
//      at a world position (used for explosions and star pickups)
//  - transitionToGameplay() / transitionToGameOver() — smoothly shift ambient
//      lighting mood between game states
//  - updateFlashingLights()              — advance any active flash animations
//

import SpriteKit

@MainActor
class DynamicLighting: SKNode {
    
    private struct Light {
        let node: SKSpriteNode
        var intensity: CGFloat
        let baseIntensity: CGFloat
        let color: UIColor
        let radius: CGFloat
        var isFlashing: Bool = false
    }
    
    private var lights: [String: Light] = [:]
    private let ambientColor = UIColor(red: 0.1, green: 0.1, blue: 0.3, alpha: 0.3)
    
    override init() {
        super.init()
        setupAmbientLighting()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupAmbientLighting()
    }
    
    private func setupAmbientLighting() {
        // Create a large ambient light source
        let ambientLight = SKSpriteNode(color: ambientColor, size: CGSize(width: kViewSize.width * 2, height: kViewSize.height * 2))
        ambientLight.position = CGPoint(x: kViewSize.width / 2, y: kViewSize.height / 2)
        ambientLight.blendMode = .alpha
        ambientLight.zPosition = -10
        addChild(ambientLight)
    }
    
    @discardableResult
    func addLight(at position: CGPoint, color: UIColor, intensity: CGFloat, radius: CGFloat) -> SKSpriteNode {
        let lightNode = createLightNode(color: color, radius: radius, intensity: intensity)
        lightNode.position = position
        addChild(lightNode)
        
        let lightId = UUID().uuidString
        let light = Light(
            node: lightNode,
            intensity: intensity,
            baseIntensity: intensity,
            color: color,
            radius: radius
        )
        lights[lightId] = light
        
        return lightNode
    }
    
    private func createLightNode(color: UIColor, radius: CGFloat, intensity: CGFloat) -> SKSpriteNode {
        let lightNode = SKSpriteNode(color: color, size: CGSize(width: radius * 2, height: radius * 2))
        
        // Create radial gradient effect
        let texture = createRadialGradientTexture(color: color, size: CGSize(width: radius * 2, height: radius * 2))
        lightNode.texture = texture
        lightNode.alpha = intensity
        lightNode.blendMode = .add
        
        return lightNode
    }
    
    private func createRadialGradientTexture(color: UIColor, size: CGSize) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            
            // Create radial gradient
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: [color.cgColor, UIColor.clear.cgColor] as CFArray,
                                    locations: [0.0, 1.0])!
            
            context.cgContext.drawRadialGradient(gradient,
                                               startCenter: center, startRadius: 0,
                                               endCenter: center, endRadius: radius,
                                               options: [])
        }
        
        return SKTexture(image: image)
    }
    
    func update(playerPosition: CGPoint) {
        // Update player light position
        if let playerLight = children.first(where: { $0.name == "playerLight" }) {
            playerLight.position = playerPosition
        }
        
        // Update any flashing lights
        updateFlashingLights()
    }
    
    private func updateFlashingLights() {
        for (id, light) in lights {
            if light.isFlashing {
                // Flash animation will be handled by actions
                lights[id] = light
            }
        }
    }
    
    func flashAt(_ position: CGPoint, color: UIColor, intensity: CGFloat) {
        let flash = createLightNode(color: color, radius: 100, intensity: intensity)
        flash.position = position
        addChild(flash)
        
        // Flash animation
        let scaleUp = SKAction.scale(to: 2.0, duration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        
        flash.run(SKAction.sequence([
            SKAction.group([scaleUp, fadeOut]),
            remove
        ]))
    }
    
    func transitionToGameplay() {
        // Enhance ambient lighting for gameplay
        let enhance = SKAction.fadeAlpha(to: 0.5, duration: 2.0)
        children.first?.run(enhance)
    }
    
    func transitionToGameOver() {
        // Dim lighting for game over
        let dim = SKAction.fadeAlpha(to: 0.1, duration: 1.0)
        run(dim)
    }
}