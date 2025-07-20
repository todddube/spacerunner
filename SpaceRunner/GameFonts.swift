//
//  GameFonts.swift
//  SpaceRunner
//
//  Created by Todd Dube : 2025
//  Purpose: Modern font loading and text label creation system with iOS 18+ features including Dynamic Type support.
//

import Foundation
import SpriteKit
import UIKit
import Observation
import OSLog
import CoreText
import CoreGraphics

@available(iOS 18.0, *)
@MainActor
@Observable
final class GameFonts {
    static let shared = GameFonts()
    
    // MARK: - Public Types
    enum LabelType: CaseIterable {
        case statusBar
        case bonus
        case message
        case menu
    }
    
    // MARK: - Observable Properties
    private(set) var isCustomFontAvailable: Bool = false
    private(set) var contentSizeCategory: UIContentSizeCategory = .medium
    
    // MARK: - Private Properties
    private let fontName = "editundo"
    private let fallbackFontName = "Helvetica-Bold"
    
    // Base font sizes (will be scaled based on Dynamic Type)
    private let baseFontSizes: [LabelType: (phone: CGFloat, pad: CGFloat)] = [
        .statusBar: (phone: 16.0, pad: 24.0),
        .bonus: (phone: 36.0, pad: 72.0),
        .message: (phone: 24.0, pad: 48.0),
        .menu: (phone: 24.0, pad: 48.0)
    ]
    
    private let logger = Logger(subsystem: "com.todddube.spacerunner", category: "GameFonts")
    
    // MARK: - Initialization
    private init() {
        setupFont()
        observeContentSizeChanges()
    }
    
    // MARK: - Setup
    private func setupFont() {
        // Try to load the custom font (should work automatically with Info.plist registration)
        isCustomFontAvailable = UIFont(name: fontName, size: 12) != nil
        
        if !isCustomFontAvailable {
            logger.warning("Custom font '\(self.fontName)' not found, attempting manual registration")
            
            // Try to find and register the font manually from the main bundle
            if let fontURL = Bundle.main.url(forResource: fontName, withExtension: "ttf") {
                logger.info("Found font file at: \(fontURL)")
                registerFont(from: fontURL)
            } else {
                logger.error("Font file '\(self.fontName).ttf' not found in main bundle")
                logger.info("Available bundle resources: \(Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil)?.map { $0.lastPathComponent } ?? [])")
            }
        } else {
            logger.info("Custom font '\(self.fontName)' loaded successfully from Info.plist")
        }
    }
    
    private func registerFont(from url: URL) {
        // Use modern iOS 18 font registration API
        var error: Unmanaged<CFError>?
        if CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
            logger.info("Successfully registered font using modern API")
            isCustomFontAvailable = UIFont(name: fontName, size: 12) != nil
            if !isCustomFontAvailable {
                logger.error("Font registered but still not available via UIFont")
            }
        } else {
            if let error = error?.takeRetainedValue() {
                logger.error("Failed to register font: \(CFErrorCopyDescription(error))")
            } else {
                logger.error("Failed to register font with unknown error")
            }
            
            // Fallback to legacy method for compatibility
            fallbackRegisterFont(from: url)
        }
    }
    
    private func fallbackRegisterFont(from url: URL) {
        guard let fontData = NSData(contentsOf: url),
              let provider = CGDataProvider(data: fontData),
              let font = CGFont(provider) else {
            logger.error("Failed to create font data from: \(url)")
            return
        }
        
        var error: Unmanaged<CFError>?
        if CTFontManagerRegisterGraphicsFont(font, &error) {
            logger.info("Successfully registered font using legacy API")
            isCustomFontAvailable = UIFont(name: fontName, size: 12) != nil
        } else {
            if let error = error?.takeRetainedValue() {
                logger.error("Legacy font registration failed: \(CFErrorCopyDescription(error))")
            } else {
                logger.error("Legacy font registration failed with unknown error")
            }
        }
    }
    
    private func observeContentSizeChanges() {
        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateContentSizeCategory()
            }
        }
        updateContentSizeCategory()
    }
    
    private func updateContentSizeCategory() {
        contentSizeCategory = UIApplication.shared.preferredContentSizeCategory
    }
    
    // MARK: - Public Label Creation
    func createLabel(string: String, labelType: LabelType) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: effectiveFontName)
        
        // Configure common properties
        label.text = string
        label.verticalAlignmentMode = .center
        label.fontSize = scaledFontSize(for: labelType)
        
        // Configure type-specific properties
        switch labelType {
    
        case .statusBar:
            label.horizontalAlignmentMode = .left
            label.fontColor = Colors.colorFromRGB(rgbvalue: Colors.FontScore)
            
        case .bonus:
            label.horizontalAlignmentMode = .center
            label.fontColor = Colors.colorFromRGB(rgbvalue: Colors.FontBonus)
            
        case .message:
            label.horizontalAlignmentMode = .center
            label.fontColor = Colors.colorFromRGB(rgbvalue: Colors.FontBonus)
            
        case .menu:
            label.horizontalAlignmentMode = .center
            label.fontColor = Colors.colorFromRGB(rgbvalue: Colors.FontMenu)
        }
        
        return label
    }
    
    // MARK: - Font Utilities
    private var effectiveFontName: String {
        isCustomFontAvailable ? fontName : fallbackFontName
    }
    
    private func scaledFontSize(for labelType: LabelType) -> CGFloat {
        guard let sizeInfo = baseFontSizes[labelType] else {
            logger.error("No font size configuration for label type: \(String(describing: labelType))")
            return 16.0
        }
        
        let baseSize = kDeviceTablet ? sizeInfo.pad : sizeInfo.phone
        return scaledFontSize(baseSize: baseSize)
    }
    
    private func scaledFontSize(baseSize: CGFloat) -> CGFloat {
        let scaleFactor = contentSizeCategory.scaleFactor
        return baseSize * scaleFactor
    }
    
    // MARK: - Animations
    func animateFloatingLabel(node: SKLabelNode) -> SKAction {
        let fadeIn = SKAction.fadeIn(withDuration: 0.1)
        let scaleUp = SKAction.scale(to: 1.25, duration: 0.07)
        let moveUp = SKAction.moveTo(y: node.position.y + node.frame.size.height * 2, duration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.1)
        let remove = SKAction.removeFromParent()
        
        let sequence = SKAction.sequence([fadeIn, scaleUp, moveUp, fadeOut, remove])
        return sequence
    }
    
    // MARK: - Accessibility Support
    func updateFontSizesForAccessibility() {
        updateContentSizeCategory()
        logger.info("Font sizes updated for accessibility. Content size category: \(self.contentSizeCategory.rawValue)")
    }
    
    // MARK: - Cleanup
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UIContentSizeCategory Extension
extension UIContentSizeCategory {
    var scaleFactor: CGFloat {
        switch self {
        case .extraSmall: return 0.8
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.1
        case .extraLarge: return 1.2
        case .extraExtraLarge: return 1.3
        case .extraExtraExtraLarge: return 1.4
        case .accessibilityMedium: return 1.5
        case .accessibilityLarge: return 1.7
        case .accessibilityExtraLarge: return 1.9
        case .accessibilityExtraExtraLarge: return 2.1
        case .accessibilityExtraExtraExtraLarge: return 2.3
        default: return 1.0
        }
    }
}
