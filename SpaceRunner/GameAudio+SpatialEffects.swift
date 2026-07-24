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
//  - playSoundEffect(_:at:)            — calculate distance-based volume factor
//      (0.1 – 1.0) and route to the standard playSoundEffect(_:) call
//  NOTE: Volume factor is currently computed but not yet applied per-effect;
//      a future update will pass it to a dedicated player node volume property.
//

import CoreGraphics

extension GameAudio {

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
}