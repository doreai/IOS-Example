//
//  AppDelegate.swift
//  DoreCartoonDemo
//
//  Copyright © 2020 dore. All rights reserved.
//

import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let audioSession = AVAudioSession.sharedInstance()
           do {
               try audioSession.setCategory(.playback, mode: .moviePlayback)
           }
           catch {
               print("Setting category to AVAudioSessionCategoryPlayback failed.")
           }
           return true
        
    }
    
    
    
    
}

