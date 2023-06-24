//
//  Constants.swift
//  SpaceRunner
//
//  Created by Todd Dube on 3/20/16.
//  Copyright © 2020 Todd Dube. All rights reserved.
//

import Foundation
import SpriteKit

// MARK: - Debug
// Enabled circles around objects on screen 
let kDebug = false


// MARK: - Screen Dimension convience
let kViewSize = UIScreen.main.bounds.size
let kScreenCenter = CGPoint(x: kViewSize.width / 2, y: kViewSize.height / 2)

// MARK: - Device size convience
let kDeviceTablet = (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad)

// MARK: - Sprite Names
class SpriteName {
    // Button Sprite Names
    class var ButtonPlay:String     {return "PlayButton"}
    class var ButtonStart:String    {return "StartButton"}
    class var ButtonRetry:String    {return "RetryButton"}
    class var ButtonPause:String    {return "PauseButton"}
    class var ButtonResume:String   {return "ResumeButton"}
    
    // Interface title Names
    class var TitleGame:String      {return "GameTitle"}
    class var TitleGameShip:String  {return "GameTitleShip"}
    class var TitleGameOver:String  {return "GameOverTitle"}
    class var HandTap:String        {return "HandTap"}
    
    // Meteors
    class var MeteorHuge:String     {return "MeteorHuge"}
    class var MeteorLarge:String    {return "MeteorLarge"}
    class var MeteorMedium:String   {return "MeteorMedium"}
    class var MeteorSmall:String    {return "MeteorSmall"}
    
    // Player
    class var Player:String         {return "Player"}
    class var TouchCircle:String    {return "TouchCircle"}

    // Particles
    class var Magic:String          {return "Magic"}
    class var Explosion:String      {return "ExplosionParticle.sks"}
    class var Explode: String       {return "explode.sks"}
    class var ExplodeStar:String    {return "StarParticle.sks"}
    
    // Status Bar
    class var PlayerLives:String    {return "PlayerLives"}
    
    // Stars
    class var Star:String           {return "Star"}
    class var StarIcon:String       {return "StarIcon"}

}

// MARK: - Category Bitmasks
class Contact {
    class var Scene:UInt32          {return 1 << 0}
    class var Meteor:UInt32         {return 1 << 1}
    class var Star:UInt32           {return 1 << 2}
    class var Player:UInt32         {return 1 << 3}
}

// MARK: - zPosition Drawing
class GameLayer {
    class var Background:CGFloat    {return 0}
    class var Meteor:CGFloat        {return 1}
    class var Star:CGFloat          {return 2}
    class var Player:CGFloat        {return 3}
    class var Interface:CGFloat     {return 4}
}
