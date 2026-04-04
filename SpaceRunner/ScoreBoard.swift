//
//  ScoreBoard.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Two-column results panel shown on the Game Over screen. The left column
//  displays the current-run values; the right column shows all-time bests
//  retrieved from GameSettings. Slides in from off-screen left with a
//  spring-bounce animation.
//
//  RESPONSIBILITIES
//  - setupScoreBackground()  — build a rounded dark panel (88 % screen width)
//  - setupScores(…)          — populate Score / Stars / Streak rows with
//      current and best values using GameFonts labels
//  - setupAnimation()        — configure the eased slide-in + scale-bounce sequence
//  - animateIn()             — execute the entrance animation immediately after init
//  - All sizing is relative to kViewSize so the layout works on any iOS device
//

import Foundation
import SpriteKit

class ScoreBoard: SKNode {
    
    // MARK: - Private convience constants
    fileprivate let fonts = GameFonts.shared
    fileprivate let fontType = GameFonts.LabelType.statusBar
    
    // MARK: - Private class variables
    fileprivate var background = SKShapeNode()
    fileprivate var animation = SKAction()
    
    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init() {
        super.init()
    }
    
    convenience init(score: Int, bestScore: Int, streak: Int, bestStreak: Int, stars: Int, bestStars: Int) {
        self.init()
        
        self.setupScoreBackground()
        self.setupScores(score, bestScore: bestScore, streak: streak, bestStreak: bestStreak, stars: stars, bestStars: bestStars)
        self.setupAnimation()
        self.animateIn()
    }
    
    // MARK: - Setup
    fileprivate func setupScoreBackground() {
        let boardWidth = kViewSize.width * 0.88
        let boardHeight = kViewSize.height * 0.22  // Slightly taller for comfortable row spacing
        // Anchor at bottom-left; SKShapeNode positions relative to its own origin
        let backgroundRect = CGRect(x: 0, y: 0, width: boardWidth, height: boardHeight)
        
        self.background = SKShapeNode(rect: backgroundRect, cornerRadius: 8.0)
        self.background.strokeColor = Colors.colorFromRGB(rgbvalue: Colors.Border)
        self.background.lineWidth = 1.5
        self.background.fillColor = SKColor(white: 0.08, alpha: 0.82)
        
        // Start off-screen to the left; animate in via setupAnimation
        self.background.position = CGPoint(x: -kViewSize.width * 2, y: kViewSize.height * 0.36)
        
        self.addChild(self.background)
    }
    
    fileprivate func setupScores(_ score: Int, bestScore: Int, streak: Int, bestStreak: Int, stars: Int, bestStars: Int) {
        let frameWidth = self.background.frame.width
        let frameHeight = self.background.frame.height
        
        // Vertical positions — three evenly spaced rows with padding
        let topPad: CGFloat = frameHeight * 0.15
        let rowSpacing: CGFloat = (frameHeight - topPad * 2) / 2
        let row1Y = frameHeight - topPad              // Score
        let row2Y = row1Y - rowSpacing                // Stars
        let row3Y = row2Y - rowSpacing                // Streak
        
        // Column positions — left label | left value | right label | right value
        let col1X = frameWidth * 0.05
        let col2X = frameWidth * 0.30
        let col3X = frameWidth * 0.55
        let col4X = frameWidth * 0.80
        
        let rows: [(label: String, value: Int, bestLabel: String, bestValue: Int, y: CGFloat)] = [
            ("Score",  score,  "Best:", bestScore,  row1Y),
            ("Stars",  stars,  "Best:", bestStars,  row2Y),
            ("Streak", streak, "Best:", bestStreak, row3Y)
        ]
        
        for row in rows {
            let lbl   = fonts.createLabel(string: row.label + ":", labelType: fontType)
            let val   = fonts.createLabel(string: String(row.value), labelType: fontType)
            let bLbl  = fonts.createLabel(string: row.bestLabel, labelType: fontType)
            let bVal  = fonts.createLabel(string: String(row.bestValue), labelType: fontType)
            
            // Left-align labels, left-align values
            lbl.horizontalAlignmentMode  = .left
            val.horizontalAlignmentMode  = .left
            bLbl.horizontalAlignmentMode = .left
            bVal.horizontalAlignmentMode = .left
            
            lbl.position  = CGPoint(x: col1X, y: row.y)
            val.position  = CGPoint(x: col2X, y: row.y)
            bLbl.position = CGPoint(x: col3X, y: row.y)
            bVal.position = CGPoint(x: col4X, y: row.y)
            
            // Dim the "Best" column slightly
            bLbl.fontColor = SKColor(white: 0.75, alpha: 1.0)
            bVal.fontColor = SKColor(white: 0.85, alpha: 1.0)
            
            self.background.addChild(lbl)
            self.background.addChild(val)
            self.background.addChild(bLbl)
            self.background.addChild(bVal)
        }
    }
    
    fileprivate func setupAnimation() {
        // Slide in from left, then a short bounce
        let targetX = kViewSize.width * 0.06
        let targetY = kViewSize.height * 0.36
        let moveIn   = SKAction.move(to: CGPoint(x: targetX, y: targetY), duration: 0.45)
        moveIn.timingMode = .easeOut
        let scaleUp  = SKAction.scale(to: 1.05, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        
        self.animation = SKAction.sequence([moveIn, scaleUp, scaleDown])
    }
    
    // MARK: - Animation
    fileprivate func animateIn() {
        self.background.run(self.animation)
    }
}
