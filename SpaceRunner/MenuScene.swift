//
//  MenuScene.swift
//  SpaceRunner
//
//  Created by Todd Dube : 2025
//  Purpose: Main menu scene with title, play button, and author information.
//

import Foundation
import SpriteKit

class MenuScene:SKScene {
    // MARK: - Private class variables
    private var sceneLabel = SKLabelNode()
    
    // MARK: - Private convience constants
    fileprivate let fonts = GameFonts.shared
    fileprivate let fontType = GameFonts.LabelType.statusBar

    
    
    // MARK: - Private class constants
    fileprivate let background = Background()
    fileprivate let playButton = PlayButton()
    fileprivate let gameTitle = GameTitle()
    fileprivate let gameTitleShip = GameTitleShip()
    
    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(size:CGSize) {
        super.init(size: size)
    }
    
    override func didMove(to view: SKView) {
        GameAudio.shared.playBackgroundMusic()
        self.setupMenuScene()
    }
    
    // MARK: - Setup
    fileprivate func setupMenuScene() {
        // Set the background color to black
        self.backgroundColor = Colors.colorFromRGB(rgbvalue: Colors.Background)
        self.addChild(self.background)
        self.addChild(self.playButton)
        self.addChild(self.gameTitle)
        self.addChild(self.gameTitleShip)
        
        // Add Author / Copyright Information / Version and Build
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        let versionLabel = fonts.createLabel(string: "v\(appVersion).\(buildNumber)", labelType: GameFonts.LabelType.menu)
        let authorLabel = fonts.createLabel(string: "By Todd Dube", labelType: GameFonts.LabelType.menu)
        
        // Postion the lables
        authorLabel.position = CGPoint(x: kViewSize.width * 0.50, y: kViewSize.height * 0.65)
        versionLabel.position = CGPoint(x: kViewSize.width * 0.50 , y: kViewSize.height * 0.62)
        
        self.addChild(authorLabel)
        self.addChild(versionLabel)
        
        // Rotate the gameTitleShip forever (slower rotation to better show break-apart effect)
        self.gameTitleShip.run(SKAction.repeatForever(SKAction.rotate(byAngle: 15.0, duration: 6.0)), withKey: "mainRotation")
        

    }
    
    // MARK: - Update
    override func update(_ currentTime: TimeInterval) {
    }
    
    // MARK: - Touch Event
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch:UITouch = touches.first! as UITouch
        let touchLocation = touch.location(in: self)
        
        if self.playButton.contains(touchLocation) {

            self.playButton.tapped()
        
            self.loadGameScene()
        }
    }
    
    // MARK: - Load Scene
    fileprivate func loadGameScene() {
        let gameScene = GameScene(size: kViewSize)
        let transition = SKTransition.fade(with: SKColor.black, duration: 1.0)
        
        self.view?.presentScene(gameScene, transition: transition)
    }
}
