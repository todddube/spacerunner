//
//  MenuScene.swift
//  SpaceRunner
//
//  Created by Todd Dube on 3/20/16.
//  Copyright © 2016 Todd Dube. All rights reserved.
//

import Foundation
import SpriteKit

class MenuScene:SKScene {
    // MARK: - Private class variables
    // private var sceneLabel = SKLabelNode()
    
    // MARK: - Private convience constants
    fileprivate let fonts = GameFonts.sharedInstance
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
        GameAudioSharedInstace.playBackgroundMusic(fileName: Music.Game)
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
        
        // Add Author / Copyright Information
        let appVersion = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        let authorLabel = fonts.createLabel(string: "By Todd Dube", labelType: fontType)
        let versionLabel = fonts.createLabel(string: "v0.5." + appVersion, labelType: fontType)
        
        versionLabel.position = CGPoint(x: kViewSize.width * 0.38 , y: kViewSize.height * 0.64)
        authorLabel.position = CGPoint(x: kViewSize.width * 0.35, y: kViewSize.height * 0.60)
        
        self.addChild(authorLabel)
        self.addChild(versionLabel) 
        
        // Rotate the gameTitleShip forever
        self.gameTitleShip.run(SKAction.repeatForever(SKAction.rotate(byAngle: 5.0, duration: 2.5)))
        

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
