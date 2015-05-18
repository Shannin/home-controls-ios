//
//  AppDelegate.swift
//  Home Controls
//
//  Created by Shannin Ciprich on 4/12/15.
//  Copyright (c) 2015 Shannin. All rights reserved.
//

import UIKit
import NotificationCenter
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    let locationManager = CLLocationManager()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Setup location manager
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        return true
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    // MARK:- CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        UserDefaultsWrapper.sharedInstance.todayWidgetCurrentView = .ImHome
        NCWidgetController.widgetController().setHasContent(true, forWidgetWithBundleIdentifier: NSBundle.mainBundle().bundleIdentifier! + ".TodayWidget")
    }
    
    func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
        NCWidgetController.widgetController().setHasContent(false, forWidgetWithBundleIdentifier: NSBundle.mainBundle().bundleIdentifier! + ".TodayWidget")
    }
}