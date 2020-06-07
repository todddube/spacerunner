//
//  GameViewController.swift
//  SpaceRunner
//
//  Created by Todd Dube on 3/19/16.
//  Copyright (c) 2020 Todd Dube. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

   override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    
        if let skView = self.view as? SKView {
            if(skView.scene == nil) {
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
