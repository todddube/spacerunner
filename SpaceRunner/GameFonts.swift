//
//  GameFonts.swift
//  SpaceRunner
//
//  Created by Todd Dube : 2025
//  Purpose: Font loading and text label creation system with different styling options.
//

import Foundation
import SpriteKit

let GameFontsSharedInstance = GameFonts()

class GameFonts {
    class var sharedInstance:GameFonts {
        return GameFontsSharedInstance
    }
    
    // MARK: - Public enum
    internal enum LabelType:Int {
        case statusBar
        case bonus
        case message
        case menu
    }
    
    // MARK: - Private class constants
    fileprivate let fontName = "editundo"
    fileprivate let scoreSizePad:CGFloat = 24.0
    fileprivate let scoreSizePhone:CGFloat = 16.0
    fileprivate let bonusSizePad:CGFloat = 72.0
    fileprivate let bonusSizePhone:CGFloat = 36.0
    fileprivate let messageSizePad:CGFloat = 48.0
    fileprivate let messageSizePhone:CGFloat = 24.0
    
    // MARK: - Private class variables
    fileprivate var label = SKLabelNode()
    
    // MARK: - Init
    init() {
        self.setupLabel()
    }
    
    // MARK:: - Setup
    fileprivate func setupLabel() {
        // Try to load custom font, fallback to system font if it fails
        if let _ = UIFont(name: self.fontName, size: 12) {
            self.label = SKLabelNode(fontNamed: self.fontName)
        } else {
            print("Warning: Custom font '\(self.fontName)' not found, using system font")
            self.label = SKLabelNode(fontNamed: "Helvetica-Bold")
        }
    
        self.label.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
    }
    
    // MARK: - Label Creation
    func createLabel(string:String, labelType:LabelType) -> SKLabelNode {
        let copiedLabel = self.label.copy() as! SKLabelNode
        
        switch labelType {
            case LabelType.statusBar:
                copiedLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
                copiedLabel.fontColor = Colors.colorFromRGB(rgbvalue: Colors.FontScore)
                copiedLabel.fontSize = kDeviceTablet ? self.scoreSizePad : self.scoreSizePhone
                copiedLabel.text = string
            
            case LabelType.bonus:
                copiedLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
                copiedLabel.fontColor = Colors.colorFromRGB(rgbvalue: Colors.FontBonus)
                copiedLabel.fontSize = kDeviceTablet ? self.bonusSizePad : self.bonusSizePhone
                copiedLabel.text = string
            
            case LabelType.message:
                copiedLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
                copiedLabel.fontColor = Colors.colorFromRGB(rgbvalue: Colors.FontBonus)
                copiedLabel.fontSize = kDeviceTablet ? self.messageSizePad : self.messageSizePhone
                copiedLabel.text = string
            
            case LabelType.menu:
                copiedLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
                copiedLabel.fontColor = Colors.colorFromRGB(rgbvalue: Colors.FontMenu)
                copiedLabel.fontSize = kDeviceTablet ? self.messageSizePad : self.messageSizePhone
                copiedLabel.text = string
        }
        
        return copiedLabel
    }
    
    // MARK: - Actions
    func animateFloatingLabel(node: SKLabelNode) -> SKAction {
        let action = SKAction.run({
            node.run(SKAction.fadeIn(withDuration: 0.1), completion: {
                node.run(SKAction.scale(to: 1.25, duration: 0.07), completion: {
                    node.run(SKAction.moveTo(y: node.position.y + node.frame.size.height * 2, duration: 0.1), completion: {
                        node.run(SKAction.fadeOut(withDuration: 0.1), completion: {
                            node.removeFromParent()
                        })
                    })
                })
            })
        })
        return action
    }
}
