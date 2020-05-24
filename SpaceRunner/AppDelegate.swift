//
//  AppDelegate.swift
//  SpaceRunner
//
//  Created by Todd Dube on 3/19/16.
//  Copyright © 2020 Todd Dube. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
        // Post message to Pause the game
        NotificationCenter.default.post(name: Notification.Name(rawValue: "PauseGame"), object: nil)
        
        // pause the music 
        GameAudio.sharedInstance.pauseBackgroundMusic()
        
        // Pause the view
        let view = self.window?.rootViewController?.view as! SKView
        view.isPaused = true
        
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        // resume the view
        let view = self.window?.rootViewController?.view as! SKView
        view.isPaused = false
        
        // post message to resume the game
        NotificationCenter.default.post(name: Notification.Name(rawValue: "ResumeGame"), object: nil)
        
        // resume music
        GameAudio.sharedInstance.resumeBackgroundMusic()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

