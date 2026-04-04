//
//  PauseButton.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Toggle button embedded in the StatusBar that switches the game between the
//  running and paused states with matching texture feedback.
//
//  RESPONSIBILITIES
//  - Render PauseButton / ResumeButton textures and swap on each tap
//  - Track internal paused state (gamePaused flag)
//  - Play button-tap sound effect via GameAudio on interaction
//  - Expose tapped() and getPauseState() for GameScene state management
//  - Support both standalone positioning and StatusBar-managed placement
//

import Foundation
import SpriteKit

class PauseButton:SKSpriteNode {
    
    // MARK: - Private class constants
    fileprivate let pauseTexture = GameTextures.sharedInstance.textureWithName(name: SpriteName.ButtonPause)
    fileprivate let resumeTexture = GameTextures.sharedInstance.textureWithName(name: SpriteName.ButtonResume)
    
    // MARK: - Private class variables
    fileprivate var gamePaused = false
    
    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    convenience init() {
        let texture = GameTextures.sharedInstance.textureWithName(name: SpriteName.ButtonPause)
        self.init(texture: texture, color: SKColor.white, size: texture.size())
        // Don't auto-setup positioning - let parent handle positioning
    }
    
    convenience init(standalone: Bool) {
        let texture = GameTextures.sharedInstance.textureWithName(name: SpriteName.ButtonPause)
        self.init(texture: texture, color: SKColor.white, size: texture.size())
        if standalone {
            self.setupPauseButton()
        }
    }
    
    // MARK: - Setup
    fileprivate func setupPauseButton() {
        // put anchorPoint in the top right corner of the sprite
        self.anchorPoint = CGPoint(x: 1.0, y: 1.0)
        
        // position at top right corner of the screen
        // MARK: - Play Pause Button
        // moved status bar to bottom of the screen
        // self.position = CGPoint(x: kViewSize.width, y:(kViewSize.height * 0.94))
        self.position = CGPoint(x: kViewSize.width * 0.65, y:(kViewSize.height * 0.053))
        
        // TODO: need to update / scale the pause button
        self.setScale(0.65)
    }
    
    // MARK: - Actions
    func tapped() {
        GameAudio.shared.playSoundEffect(.buttonTap)
        
        // Flip the value of gamePaused
        self.gamePaused = !self.gamePaused
        
        // which texture should we use?
        self.texture = self.gamePaused ? self.resumeTexture : self.pauseTexture
    }
    
    func getPauseState() -> Bool {
        return self.gamePaused
    }
}
