//
//  AppDelegate.swift
//  Finder
//
//  Created by djay mac on 27/01/15.
//  Copyright (c) 2015 DJay. All rights reserved.
//

import UIKit
import AudioToolbox.AudioServices
import IQKeyboardManagerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        IQKeyboardManager.shared.enable = true

        UIApplication.shared.applicationIconBadgeNumber = 0
                
                
        let parseConfiguration = ParseClientConfiguration(block: { (ParseMutableClientConfiguration) -> Void in
            
            ParseMutableClientConfiguration.applicationId = appId;
            ParseMutableClientConfiguration.clientKey =  appSecret;
            
            ParseMutableClientConfiguration.server = "https://parseapi.back4app.com/"
            
        })
        
        Parse.initialize(with: parseConfiguration)
        PFFacebookUtils.initializeFacebook()
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .carPlay ]) {
                (granted, error) in
                print("Permission granted: \(granted)")
                guard granted else { return }
                self.getNotificationSettings()
            }
        } else {
            // REGISTER FOR PUSH NOTIFICATIONS
            let notifTypes:UIUserNotificationType  = [.alert, .badge, .sound]
            let settings = UIUserNotificationSettings(types: notifTypes, categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
            application.applicationIconBadgeNumber = 0
            
        }
            
        return true
        
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        createInstallationOnParse(deviceTokenData: deviceToken)
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func createInstallationOnParse(deviceTokenData:Data){
        if let installation = PFInstallation.current() {
            installation.setDeviceTokenFrom(deviceTokenData)
            installation.saveInBackground {
                (success: Bool, error: Error?) in
                if (success) {
                    print("You have successfully saved your push installation to Back4App!")
                } else {
                    if let myError = error{
                        print("Error saving parse installation \(myError.localizedDescription)")
                    }else{
                        print("Uknown error")
                    }
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        AudioServicesPlayAlertSound(1110)
        
        
        if  (userInfo["type"] as? String) != nil {
            // Printout of (userInfo["asp"])["type"]
            
            //NSNotificationCenter.defaultCenter().postNotificationName("ShowAlert", object: userInfo)
            
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "displayMessage"), object: nil, userInfo: userInfo)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadMessages"), object: nil)
    }


    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
      //  return FBAppCall.handleOpenURL(url as URL, sourceApplication: sourceApplication, withSession: PFFacebookUtils.session())
        return FBAppCall.handleOpen(url, sourceApplication: "")
    }

    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
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
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        FBAppCall.handleDidBecomeActive()
    }


    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    

}

