//
//  GameAudio+SpatialEffects.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Extension on GameAudio that adds positional audio helpers. Sound effects can
//  be triggered with a world-space CGPoint so volume attenuates with distance
//  from the screen centre, enhancing the sense of spatial depth.
//
//  RESPONSIBILITIES
//  - setupSpatialAudio() async         — async hook for any future spatial-audio
//      graph configuration (reverb send, 3-D panning node, etc.)
//  - playSoundEffect(_:at:)            — calculate distance-based volume factor
//      (0.1 – 1.0) and route to the standard playSoundEffect(_:) call
//  - playLoopingSpatialEffect(_:at:)   — convenience wrapper for looping positional
//      sounds (to be expanded when per-effect volume control is added)
//  NOTE: Volume factor is currently computed but not yet applied per-effect;
//      a future update will pass it to a dedicated player node volume property.
//

import CoreGraphics

extension GameAudio {
    
    func setupSpatialAudio() async {
        // Setup spatial audio - can be expanded later
        print("Setting up spatial audio")
    }
    
    func playSoundEffect(_ effect: SoundEffect, at position: CGPoint) {
        // Calculate spatial parameters based on position
        let screenCenter = CGPoint(x: kViewSize.width / 2, y: kViewSize.height / 2)
        let distance = position.distanceTo(screenCenter)
        let maxDistance: CGFloat = kViewSize.width
        
        // Calculate volume based on distance (closer = louder)
        // Note: Volume modulation could be added in future with per-effect volume control
        _ = max(0.1, 1.0 - (distance / maxDistance))
        
        // Play sound with standard volume (spatial volume control to be implemented)
        playSoundEffect(effect)
    }
    
    func playLoopingSpatialEffect(_ effect: SoundEffect, at position: CGPoint) {
        // Start a looping spatial sound effect
        playSoundEffect(effect, at: position)
    }
}