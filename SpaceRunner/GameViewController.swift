//
//  GameViewController.swift
//  SpaceRunner
//
//  Created by Todd Dube : 2025
//  Purpose: Main view controller that initializes and presents the SpriteKit game scenes.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let skView = self.view as? SKView {
            if kDebug {
                skView.showsFPS = true
                skView.showsPhysics = true
                skView.showsNodeCount = true
            }
            
            skView.ignoresSiblingOrder = true
            
            let menuScene = MenuScene(size: kViewSize)
            let menuTransition = SKTransition.fade(with: SKColor.black, duration: 0.75)
            skView.presentScene(menuScene, transition: menuTransition)
        }
    }
    
    override var shouldAutorotate : Bool {
        return true
    }

    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
        // return UIInterfaceOrientationMask.landscape
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden : Bool {
        return true
    }
}
