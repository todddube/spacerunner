//
//  AccessibilityManager.swift
//  SpaceRunner
//
//  Created by Todd Dube : 2025
//  Purpose: Centralized accessibility management for VoiceOver, haptic feedback, and motion preferences in iOS 18.
//

import UIKit
import SwiftUI
import OSLog

@MainActor
@Observable
final class AccessibilityManager {
    static let shared = AccessibilityManager()
    
    // MARK: - Accessibility Properties
    private(set) var isVoiceOverEnabled: Bool = false
    private(set) var isReduceMotionEnabled: Bool = false
    private(set) var isDynamicTypeEnabled: Bool = false
    private(set) var preferredContentSizeCategory: UIContentSizeCategory = .medium
    
    // MARK: - Haptic Feedback Generators
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    private let logger = Logger(subsystem: "com.todddube.spacerunner", category: "AccessibilityManager")
    
    // MARK: - Initialization
    private init() {
        setupAccessibilityObservers()
        updateAccessibilitySettings()
        prepareHapticGenerators()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupAccessibilityObservers() {
        // VoiceOver
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(voiceOverStatusChanged),
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )
        
        // Reduce Motion
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reduceMotionStatusChanged),
            name: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil
        )
        
        // Dynamic Type
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contentSizeCategoryChanged),
            name: UIContentSizeCategory.didChangeNotification,
            object: nil
        )
    }
    
    private func updateAccessibilitySettings() {
        isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
        isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        preferredContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
        isDynamicTypeEnabled = preferredContentSizeCategory.isAccessibilityCategory
        
        logger.info("Accessibility settings updated: VoiceOver=\(self.isVoiceOverEnabled), ReduceMotion=\(self.isReduceMotionEnabled), DynamicType=\(self.isDynamicTypeEnabled)")
    }
    
    private func prepareHapticGenerators() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        selectionFeedback.prepare()
    }
    
    // MARK: - Notification Handlers
    @objc private func voiceOverStatusChanged() {
        isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
        logger.info("VoiceOver status changed: \(self.isVoiceOverEnabled)")
    }
    
    @objc private func reduceMotionStatusChanged() {
        isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        logger.info("Reduce Motion status changed: \(self.isReduceMotionEnabled)")
    }
    
    @objc private func contentSizeCategoryChanged() {
        preferredContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
        isDynamicTypeEnabled = preferredContentSizeCategory.isAccessibilityCategory
        logger.info("Content size category changed: \(self.preferredContentSizeCategory.rawValue)")
    }
    
    // MARK: - Haptic Feedback Methods
    func playHapticFeedback(_ type: HapticFeedbackType) {
        // Respect user preferences for haptic feedback
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        
        switch type {
        case .light:
            lightImpact.impactOccurred()
        case .medium:
            mediumImpact.impactOccurred()
        case .heavy:
            heavyImpact.impactOccurred()
        case .selection:
            selectionFeedback.selectionChanged()
        case .success:
            notificationFeedback.notificationOccurred(.success)
        case .warning:
            notificationFeedback.notificationOccurred(.warning)
        case .error:
            notificationFeedback.notificationOccurred(.error)
        }
        
        // Prepare for next use
        prepareHapticGenerators()
    }
    
    // MARK: - Animation Duration
    func animationDuration(default defaultDuration: TimeInterval) -> TimeInterval {
        return isReduceMotionEnabled ? defaultDuration * 0.2 : defaultDuration
    }
    
    // MARK: - VoiceOver Announcements
    func announceGameEvent(_ message: String, priority: UIAccessibility.AnnouncementPriority = .medium) {
        guard isVoiceOverEnabled else { return }
        
        UIAccessibility.post(notification: .announcement, argument: message)
        logger.info("VoiceOver announcement: \(message)")
    }
    
    func announceScreenChange(to element: Any?) {
        guard isVoiceOverEnabled else { return }
        
        UIAccessibility.post(notification: .screenChanged, argument: element)
        logger.info("VoiceOver screen change announced")
    }
    
    func announceLayoutChange(to element: Any?) {
        guard isVoiceOverEnabled else { return }
        
        UIAccessibility.post(notification: .layoutChanged, argument: element)
        logger.info("VoiceOver layout change announced")
    }
    
    // MARK: - Font Scaling
    func scaledFont(_ font: Font, category: DynamicTypeSize = .large) -> Font {
        // In a real implementation, you would scale based on content size category
        // For now, return the original font
        return font
    }
    
    // MARK: - Accessibility Labels for Game Elements
    func gameElementLabel(for element: GameElement) -> String {
        switch element {
        case .player:
            return "Player ship"
        case .meteor:
            return "Meteor obstacle"
        case .star:
            return "Collectible star"
        case .pauseButton:
            return "Pause game button"
        case .scoreDisplay:
            return "Current score display"
        case .livesDisplay:
            return "Remaining lives display"
        case .background:
            return "Space background"
        }
    }
    
    func gameElementHint(for element: GameElement) -> String {
        switch element {
        case .player:
            return "Tap anywhere to move your ship to that location"
        case .meteor:
            return "Avoid this obstacle to prevent losing a life"
        case .star:
            return "Collect this star to increase your score"
        case .pauseButton:
            return "Double tap to pause the game"
        case .scoreDisplay:
            return "Your current score in the game"
        case .livesDisplay:
            return "Number of lives remaining"
        case .background:
            return "Decorative space environment"
        }
    }
}

// MARK: - Haptic Feedback Types
enum HapticFeedbackType {
    case light
    case medium
    case heavy
    case selection
    case success
    case warning
    case error
}

// MARK: - Game Elements for Accessibility
enum GameElement {
    case player
    case meteor
    case star
    case pauseButton
    case scoreDisplay
    case livesDisplay
    case background
}

// MARK: - UIContentSizeCategory Extension
extension UIContentSizeCategory {
    var isAccessibilityCategory: Bool {
        switch self {
        case .accessibilityMedium, .accessibilityLarge, .accessibilityExtraLarge,
             .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge:
            return true
        default:
            return false
        }
    }
}