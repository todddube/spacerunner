//
//  Colors.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Central vibrant arcade palette. Use named constants instead of raw hex so the
//  look stays consistent and theme changes require only this file.
//
//  PALETTE  (#0A0A1A dark bg, neon accents, additive-blend friendly)
//  AccentCyan     #00E5FF  — primary neon: shield, engine glow, tier-1 indicator
//  AccentMagenta  #FF00E5  — secondary neon: meteors, game-over title
//  AccentYellow   #FFE500  — tertiary neon: stars, score pop, survival bonus
//  DangerRed      #FF4040  — boss wave alerts, last-life flash
//  Engine colors alias the arcade palette (EngineGreen→cyan, EngineRed→magenta)
//
//  CONTENTS
//  - Colors class               — hex colour constants (Background, Border, Font variants…)
//  - colorFromRGB(rgbvalue:)    — converts a packed 0xRRGGBB integer to SKColor
//  - All colours defined as UInt properties so they can be tuned without touching
//      individual scene or node files
//

import Foundation
import SpriteKit

class Colors {
    // Core palette — vibrant arcade aesthetic
    class var Background: Int    { return 0x0A0A1A } // near-black deep blue
    class var Magic: Int         { return 0x00E5FF } // primary cyan
    class var ScreenFlash: Int   { return 0xFFFFFF }
    class var FontBonus: Int     { return 0xFFE500 } // yellow-gold
    class var FontScore: Int     { return 0xFFFFFF }
    class var FontMenu: Int      { return 0xFFFFFF }
    class var Border: Int        { return 0x00E5FF } // cyan
    class var EngineGreen: Int   { return 0x00E5FF } // cyan engine at normal speed
    class var EngineYellow: Int  { return 0xFFE500 } // yellow-gold mid engine
    class var EngineRed: Int     { return 0xFF00E5 } // magenta boost / dash trail

    // Arcade accent colors
    class var AccentCyan: Int    { return 0x00E5FF }
    class var AccentMagenta: Int { return 0xFF00E5 }
    class var AccentYellow: Int  { return 0xFFE500 }
    class var AccentGreen: Int   { return 0x40FF80 }
    class var DangerRed: Int     { return 0xFF4040 }

    // Neon meteor glow colors
    class var MeteorRocky: Int   { return 0xFF8C00 } // orange — standard rock
    class var MeteorCrystal: Int { return 0x00E5FF } // cyan  — crystal type
    class var MeteorEnergy: Int  { return 0xFF00E5 } // magenta — energy orb

    class func colorFromRGB(rgbvalue rgbValue: Int) -> SKColor {
        return SKColor(
            red:   CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8)  / 255.0,
            blue:  CGFloat( rgbValue & 0x0000FF)         / 255.0,
            alpha: 1.0
        )
    }

    class func colorFromRGB(rgbvalue rgbValue: Int, alpha: CGFloat) -> SKColor {
        return SKColor(
            red:   CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8)  / 255.0,
            blue:  CGFloat( rgbValue & 0x0000FF)         / 255.0,
            alpha: alpha
        )
    }
}
