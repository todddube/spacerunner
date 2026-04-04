//
//  Colors.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Central palette for all game colours. Use the named constants rather than
//  raw hex values to keep the look consistent and allow theme updates in one place.
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
    // RGB Colors
    class var Background:Int    {return 0x000000}
    class var Magic:Int         {return 0x04f2de}
    class var ScreenFlash:Int   {return 0xffffcc}
    class var FontBonus:Int     {return 0xb3ff01}
    class var FontScore:Int     {return 0xe6e7e8}
    class var FontMenu:Int      {return 0xffffff}
    class var Border:Int        {return 0x49b9ea}
    class var EngineGreen:Int   {return 0x55f87e}
    class var EngineYellow:Int  {return 0xEEF954}
    class var EngineRed:Int     {return 0xf44336}
    
    class func colorFromRGB(rgbvalue rgbValue:Int) -> SKColor {
        return SKColor(red: CGFloat((rgbValue & 0xFF0000)>>16)/255.0,
            green: CGFloat((rgbValue & 0x00FF00)>>8)/255.0,
            blue: CGFloat(rgbValue & 0x0000FF)/255.0,
            alpha: 1.0)
    }
       
}
