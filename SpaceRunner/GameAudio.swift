//
//  GameAudio.swift
//  SpaceRunner
//
//  Created by Todd Dube on 3/31/16.
//  Copyright © 2020 Todd Dube. All rights reserved.
//

import Foundation
import AVFoundation
import SpriteKit

class Music {
    class var Game:String       { return "GameMusic.mp3"}
}

private class SoundEffects {
    // Shields
    class var ShieldUp:String   { return "ShieldUp.caf"}
    class var ShieldDown:String { return "ShieldDown.caf"}
    
    // Interface
    class var ButtonTap:String  { return "ButtonTap.caf"}
    
    // Explosion
    class var Explosion:String  { return "Explosion.caf"}
    
    // Scoring
    class var Pickup:String     { return "Pickup.caf"}
}

let GameAudioSharedInstace = GameAudio()

class GameAudio {
    class var sharedInstance:GameAudio {
        return GameAudioSharedInstace
    }
    
    // MARK: - Private class variables
    fileprivate var musicPlayer = AVAudioPlayer()
    
    // MARK: - Public class constants
    internal let soundShieldUp = SKAction.playSoundFileNamed( SoundEffects.ShieldUp, waitForCompletion: false)
    internal let soundShieldDown = SKAction.playSoundFileNamed( SoundEffects.ShieldDown, waitForCompletion: false)
    internal let soundButtonTap = SKAction.playSoundFileNamed( SoundEffects.ButtonTap, waitForCompletion: false)
    internal let soundExplosion = SKAction.playSoundFileNamed( SoundEffects.Explosion, waitForCompletion: false)
    internal let soundPickup = SKAction.playSoundFileNamed( SoundEffects.Pickup, waitForCompletion: false)
    
    // MARK: - Public class variables
    internal var initialized = false
    
    // MARK: - Music Player
    func playBackgroundMusic(fileName: String) {
        let music = URL(fileURLWithPath: Bundle.main.path(forResource: fileName, ofType: nil)!)
        
        do {
            self.musicPlayer = try AVAudioPlayer(contentsOf: music)
        } catch let error as NSError {
            if kDebug {
                print(error)
            }
        }
        
        self.musicPlayer.numberOfLoops = -1
        self.musicPlayer.volume = 0.15
        self.musicPlayer.prepareToPlay()
        self.musicPlayer.play()
        
        self.initialized = true
    }
    
    func stopBackGroundMusic() {
        if self.musicPlayer.play() {
            self.musicPlayer.stop()
        }
    }
    
    func pauseBackgroundMusic() {
        if self.musicPlayer.isPlaying {
            self.musicPlayer.pause()
        }
    }
    
    func resumeBackgroundMusic() {
        if self.initialized {
            self.musicPlayer.play()
        }
    }
}
