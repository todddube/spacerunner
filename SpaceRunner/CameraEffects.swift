//
//  CameraEffects.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Simulates cinematic camera reactions by offsetting the scene's root node
//  in response to gameplay events. Works without a dedicated SKCameraNode so
//  it is compatible with any scene graph layout.
//
//  EFFECTS
//  - performIntroTransition()   — async fade-in zoom when the scene first loads
//  - performGameStartShake()    — brief burst of displacement on game start
//  - performImpactShake()       — sharp multi-axis shake on meteor collision
//  - performSlowMotion(…)       — ramp physicsWorld.speed down and back up
//  - update(deltaTime:)         — decay active shake displacement each frame
//  - setupForScene(_:)          — store a weak scene reference for node access
//
//  REQUIRES @MainActor — all SKAction and position mutations on the main thread
//

import SpriteKit

@MainActor
class CameraEffects: NSObject {
    
    private weak var gameScene: SKScene?
    private var basePosition: CGPoint = .zero
    private var shakeIntensity: CGFloat = 0.0
    private var shakeDuration: TimeInterval = 0.0
    private var currentShakeTime: TimeInterval = 0.0
    
    func setupForScene(_ scene: SKScene) {
        self.gameScene = scene
        self.basePosition = scene.position
    }
    
    func update(deltaTime: TimeInterval) {
        updateShake(deltaTime: deltaTime)
    }
    
    private func updateShake(deltaTime: TimeInterval) {
        guard shakeIntensity > 0, let scene = gameScene else {
            // Return to base position if no shake
            if gameScene?.position != basePosition {
                gameScene?.position = basePosition
            }
            return
        }
        
        currentShakeTime += deltaTime
        
        if currentShakeTime >= shakeDuration {
            // End shake
            shakeIntensity = 0.0
            shakeDuration = 0.0
            currentShakeTime = 0.0
            scene.position = basePosition
        } else {
            // Apply shake
            let progress = currentShakeTime / shakeDuration
            let diminishing = 1.0 - progress // Shake diminishes over time
            let currentIntensity = shakeIntensity * diminishing
            
            let shakeX = CGFloat.random(in: -currentIntensity...currentIntensity)
            let shakeY = CGFloat.random(in: -currentIntensity...currentIntensity)
            
            scene.position = CGPoint(
                x: basePosition.x + shakeX,
                y: basePosition.y + shakeY
            )
        }
    }
    
    func performIntroTransition() async {
        guard let scene = gameScene else { return }
        
        // Start zoomed out and zoom in
        scene.setScale(0.5)
        
        await withCheckedContinuation { continuation in
            let zoomIn = SKAction.scale(to: 1.0, duration: 2.0)
            zoomIn.timingMode = .easeOut
            
            scene.run(zoomIn) {
                continuation.resume()
            }
        }
    }
    
    func performGameStartShake() {
        startShake(intensity: 8.0, duration: 0.5)
    }
    
    func performImpactShake() {
        startShake(intensity: 15.0, duration: 0.3)
    }
    
    func performCollectionShake() {
        startShake(intensity: 3.0, duration: 0.1)
    }
    
    private func startShake(intensity: CGFloat, duration: TimeInterval) {
        self.shakeIntensity = intensity
        self.shakeDuration = duration
        self.currentShakeTime = 0.0
    }
    
    func performSlowMotion(duration: TimeInterval, factor: CGFloat = 0.3) {
        guard let scene = gameScene else { return }
        
        let slowDown = SKAction.speed(to: CGFloat(factor), duration: 0.1)
        let wait = SKAction.wait(forDuration: duration)
        let speedUp = SKAction.speed(to: 1.0, duration: 0.2)
        
        scene.run(SKAction.sequence([slowDown, wait, speedUp]))
    }
    
    func performZoomPulse() {
        guard let scene = gameScene else { return }
        
        let zoomIn = SKAction.scale(to: 1.05, duration: 0.1)
        let zoomOut = SKAction.scale(to: 1.0, duration: 0.1)
        
        scene.run(SKAction.sequence([zoomIn, zoomOut]))
    }
}