//
//  MotionController.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Wraps CMMotionManager to deliver calibrated, per-frame tilt values for
//  ship navigation. Supports roll (left/right) and pitch (forward/back)
//  mapped to the X and Y movement axes respectively.
//
//  USAGE
//  1. Call startMotionUpdates() when gameplay begins.
//  2. Call update() every frame (from GameScene.update(_:)) before applying to player.
//  3. Read tiltX / tiltY — both in [-1, 1] — and pass to Player.applyTilt(…).
//  4. Call stopMotionUpdates() on pause or game-over.
//  5. Call calibrate() any time to re-zero at the current device orientation.
//
//  CALIBRATION
//  A 0.5 s settling delay fires automatically on startMotionUpdates() so the
//  reference angle is captured while the player is already holding the phone.
//
//  REQUIRES iOS 18.0+ / CoreMotion framework
//

#if os(iOS)
import CoreMotion
import SpriteKit

@available(iOS 18.0, *)
@MainActor
final class MotionController {

    // MARK: - Shared Instance
    static let shared = MotionController()

    // MARK: - Private
    private let motionManager = CMMotionManager()
    private var referenceAttitude: CMAttitude?

    // MARK: - Public State
    private(set) var isActive = false

    /// Points per second applied per unit of normalised tilt (1.0 = fully tilted).
    /// Increase for more responsive controls.
    var sensitivity: CGFloat = 320.0

    /// Tilt angles below this threshold (radians) are zeroed to eliminate sensor drift.
    var deadzone: Double = 0.04

    /// Normalised [-1, 1] roll tilt — positive = phone tilted right → ship moves right.
    private(set) var tiltX: CGFloat = 0

    /// Normalised [-1, 1] pitch tilt — positive = phone tilted back → ship moves up.
    private(set) var tiltY: CGFloat = 0

    // MARK: - Init
    private init() {}

    // MARK: - Lifecycle

    /// Starts device-motion updates and schedules an auto-calibration after 0.5 s.
    func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical)
        isActive = true

        // Calibrate after a short settling delay so the reference captures the
        // natural holding angle rather than whatever angle the phone was at launch.
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 s
            self?.calibrate()
        }
    }

    /// Stops device-motion updates and resets tilt values.
    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
        isActive = false
        tiltX = 0
        tiltY = 0
        referenceAttitude = nil
    }

    /// Captures the current device orientation as the zero/neutral reference.
    /// Call this when the user is holding the phone in their natural play position.
    func calibrate() {
        referenceAttitude = motionManager.deviceMotion?.attitude.copy() as? CMAttitude
    }

    // MARK: - Per-frame Update

    /// Refreshes tiltX and tiltY from the latest device-motion sample.
    /// Must be called every frame from the scene's update() loop.
    func update() {
        guard isActive, let motion = motionManager.deviceMotion else { return }

        let attitude = motion.attitude

        // Apply calibration offset so controls are relative to the player's
        // natural holding angle, not absolute world orientation.
        if let reference = referenceAttitude {
            attitude.multiply(byInverseOf: reference)
        }

        // Roll → left / right movement
        let roll = attitude.roll
        let rawRoll = abs(roll) > deadzone ? roll : 0.0
        // Cubic ease: preserves sign, amplifies small tilts less than large ones
        let cubeRoll = rawRoll * abs(rawRoll) // sign(x) * x²
        tiltX = CGFloat(min(max(cubeRoll * 2.5, -1.0), 1.0))

        // Pitch → up / down movement; tilting the phone forward (decreasing pitch)
        // moves the ship upward, matching the intuitive "lean in" gesture.
        let pitch = attitude.pitch
        let rawPitch = abs(pitch) > deadzone ? pitch : 0.0
        let cubePitch = rawPitch * abs(rawPitch)
        tiltY = CGFloat(min(max(-cubePitch * 2.5, -1.0), 1.0))
    }
}
#endif // os(iOS)
