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
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate, BridgeSelectionViewControllerDelegate {

    var window: UIWindow?
    
    let phHueSdk: PHHueSDK = PHHueSDK()
    let locationManager = CLLocationManager()
    var noConnectionAlert: UIAlertController?
    var noBridgeFoundAlert: UIAlertController?
    var authenticationFailedAlert: UIAlertController?
    var loadingView: LoadingViewController?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        phHueSdk.startUpSDK()
        phHueSdk.enableLogging(true)
        
        let notificationManager = PHNotificationManager.defaultManager()
        notificationManager.registerObject(self, withSelector: "localConnection" , forNotification: LOCAL_CONNECTION_NOTIFICATION) // Bridge heartbeat occurred and the bridge resources cache data has been updated
        notificationManager.registerObject(self, withSelector: "noLocalConnection", forNotification: NO_LOCAL_CONNECTION_NOTIFICATION) // No connection with the bridge
        notificationManager.registerObject(self, withSelector: "notAuthenticated", forNotification: NO_LOCAL_AUTHENTICATION_NOTIFICATION) // No authentication against the bridge
        enableLocalHeartbeat()
        
        // Setup location manager
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        return true
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        // Stop heartbeat
        disableLocalHeartbeat()
        
        // Remove any open popups
        noConnectionAlert?.dismissViewControllerAnimated(false, completion: nil)
        noConnectionAlert = nil
        noBridgeFoundAlert?.dismissViewControllerAnimated(false, completion: nil)
        noBridgeFoundAlert = nil
        authenticationFailedAlert?.dismissViewControllerAnimated(false, completion: nil)
        authenticationFailedAlert = nil
    }
    
    // MARK:- CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        println("entered")
        NCWidgetController.widgetController().setHasContent(true, forWidgetWithBundleIdentifier: NSBundle.mainBundle().bundleIdentifier! + ".TodayWidget")
    }
    
    func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
        println("exitied")
        NCWidgetController.widgetController().setHasContent(false, forWidgetWithBundleIdentifier: NSBundle.mainBundle().bundleIdentifier! + ".TodayWidget")
    }

    // MARK: - HueSDK
    
    func localConnection() {
        checkConnectionState()
    }
    
    func noLocalConnection() {
        checkConnectionState()
    }
    
    func notAuthenticated() {
        if self.window!.rootViewController!.presentedViewController != nil {
            self.window!.rootViewController!.dismissViewControllerAnimated(true, completion: nil)
        }
        
        noConnectionAlert?.dismissViewControllerAnimated(false, completion: nil)
        noConnectionAlert = nil
        
        // Start local authenticion process
        let delay = 0.5 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            self.doAuthentication()
        }
    }
    
    func checkConnectionState() {
        if !phHueSdk.localConnected() {
            if self.window!.rootViewController!.presentedViewController != nil {
                self.window!.rootViewController!.dismissViewControllerAnimated(true, completion: nil)
            }
            
            if noConnectionAlert == nil {
                removeLoadingView()
                showNoConnectionDialog()
            }
        } else {
            // One of the connections is made, remove popups and loading views
            noConnectionAlert?.dismissViewControllerAnimated(false, completion: nil)
            noConnectionAlert = nil
            removeLoadingView()
        }
    }
    
    /// Shows the first no connection alert with more connection options
    func showNoConnectionDialog() {
        noConnectionAlert = UIAlertController(
            title: NSLocalizedString("No Connection", comment: "No connection alert title"),
            message: NSLocalizedString("Connection to bridge is lost", comment: "No Connection alert message"),
            preferredStyle: .Alert
        )
        
        let reconnectAction = UIAlertAction(
            title: NSLocalizedString("Reconnect", comment: "No connection alert reconnect button"),
            style: .Default
            ) { (_) in
                // Retry, just wait for the heartbeat to finish
                self.showLoadingViewWithText(NSLocalizedString("Connecting...", comment: "Connecting text"))
        }
        noConnectionAlert!.addAction(reconnectAction)
        
        let newBridgeAction = UIAlertAction(
            title: NSLocalizedString("Find new bridge", comment: "No connection find new bridge button"),
            style: .Default
            ) { (_) in
                self.searchForBridgeLocal()
        }
        noConnectionAlert!.addAction(newBridgeAction)
        
        let cancelAction = UIAlertAction(
            title: NSLocalizedString("Cancel", comment: "No bridge found alert cancel button"),
            style: .Cancel
            ) { (_) in
                self.disableLocalHeartbeat()
        }
        noConnectionAlert!.addAction(cancelAction)
        window!.rootViewController!.presentViewController(noConnectionAlert!, animated: true, completion: nil)
    }
    
    // MARK: - Heartbeat control
    
    /// Starts the local heartbeat with a 10 second interval
    func enableLocalHeartbeat() {
        // The heartbeat processing collects data from the bridge so now try to see if we have a bridge already connected
        let cache = PHBridgeResourcesReader.readBridgeResourcesCache()
        if cache?.bridgeConfiguration?.ipaddress != nil {
            var sharedDefaults = NSUserDefaults(suiteName: "group.camperoo.test")
            sharedDefaults?.setObject(cache?.bridgeConfiguration?.ipaddress, forKey: "hueIpAddress")
            sharedDefaults?.setObject(cache?.bridgeConfiguration?.mac, forKey: "hueMacAddress")
            sharedDefaults?.synchronize()
            
            showLoadingViewWithText(NSLocalizedString("Connecting", comment: "Connecting text"))
            phHueSdk.enableLocalConnection()
        } else {
            searchForBridgeLocal()
        }
    }
    
    /// Stops the local heartbeat
    func disableLocalHeartbeat() {
        phHueSdk.disableLocalConnection()
    }
    
    // MARK: - Bridge searching
    
    /// Search for bridges using UPnP and portal discovery, shows results to user or gives error when none found.
    func searchForBridgeLocal() {
        // Stop heartbeats
        disableLocalHeartbeat()
        
        // Show search screen
        showLoadingViewWithText(NSLocalizedString("Searching", comment: "Searching for bridges text"))
        
        // A bridge search is started using UPnP to find local bridges
        
        // Start search
        let bridgeSearch = PHBridgeSearching(upnpSearch: true, andPortalSearch: true, andIpAdressSearch: true)
        bridgeSearch.startSearchWithCompletionHandler { (bridgesFound: [NSObject: AnyObject]!) -> () in
            // Done with search, remove loading view
            self.removeLoadingView()
            
            // The search is complete, check whether we found a bridge
            if bridgesFound.count > 0 {
                // Results were found, show options to user (from a user point of view, you should select automatically when there is only one bridge found)
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let bridgeViewController = storyboard.instantiateViewControllerWithIdentifier("BridgeSelection") as! BridgeSelectionViewController
                bridgeViewController.bridgesFound = (bridgesFound as! [String: String])
                bridgeViewController.delegate = self
                let navController = UINavigationController(rootViewController: bridgeViewController)
                // Make it a form on iPad
                navController.modalPresentationStyle = UIModalPresentationStyle.FormSheet
                self.window!.rootViewController!.presentViewController(navController, animated: true, completion: nil)
            } else {
                // No bridge was found was found. Tell the user and offer to retry..
                
                self.noBridgeFoundAlert = UIAlertController(
                    title: NSLocalizedString("No bridges", comment: "No bridge found alert title"),
                    message: NSLocalizedString("Could not find bridge", comment: "No bridge found alert message"),
                    preferredStyle: .Alert
                )
                
                let retryAction = UIAlertAction(
                    title: NSLocalizedString("Rertry", comment: "No bridge found alert retry button"),
                    style: .Default
                    ) { (_) in
                        self.searchForBridgeLocal()
                }
                self.noBridgeFoundAlert!.addAction(retryAction)
                let cancelAction = UIAlertAction(
                    title: NSLocalizedString("Cancel", comment: "No bridge found alert cancel button"),
                    style: .Cancel
                    ) { (_) in
                        self.disableLocalHeartbeat()
                }
                self.noBridgeFoundAlert!.addAction(cancelAction)
                self.window!.rootViewController!.presentViewController(self.noBridgeFoundAlert!, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - Bridge authentication
    
    /// Start the local authentication process
    func doAuthentication() {
        disableLocalHeartbeat()
        
        // To be certain that we own this bridge we must manually push link it. Here we display the view to do this.
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let pushLinkViewController = storyboard.instantiateViewControllerWithIdentifier("BridgePushLink") as! BridgePushLinkViewController
        // Make it a form on iPad
        pushLinkViewController.modalPresentationStyle = UIModalPresentationStyle.FormSheet
        pushLinkViewController.phHueSdk = phHueSdk
        pushLinkViewController.delegate = self
        self.window!.rootViewController?.presentViewController(
            pushLinkViewController,
            animated: true,
            completion: {(bool) in
                pushLinkViewController.startPushLinking()
        })
    }
    
    // MARK: - Loading view
    
    /// Shows an overlay over the whole screen with a black box with spinner and loading text in the middle
    /// :param: text The text to display under the spinner
    func showLoadingViewWithText(text:String) {
        // First remove
        removeLoadingView()
        
        // Then add new
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        loadingView = storyboard.instantiateViewControllerWithIdentifier("Loading") as? LoadingViewController
        loadingView!.view.frame = self.window!.rootViewController!.view.bounds
        self.window!.rootViewController?.view.addSubview(loadingView!.view)
        loadingView!.loadingLabel?.text = text
    }
    
    /// Removes the full screen loading overlay.
    func removeLoadingView() {
        loadingView?.view.removeFromSuperview()
        loadingView = nil
    }
}

// MARK: - BridgeSelectionViewControllerDelegate
extension AppDelegate: BridgeSelectionViewControllerDelegate {
    
    /// Delegate method for BridgeSelectionViewController which is invoked when a bridge is selected
    func bridgeSelectedWithIpAddress(ipAddress:String, andMacAddress macAddress:String) {
        // Removing the selection view controller takes us to the 'normal' UI view
        window!.rootViewController! .dismissViewControllerAnimated(true, completion: nil)
        
        // Show a connecting view while we try to connect to the bridge
        showLoadingViewWithText(NSLocalizedString("Connecting", comment: "Connecting text"))
        
        // Set the username, ipaddress and mac address, as the bridge properties that the SDK framework will use
        phHueSdk.setBridgeToUseWithIpAddress(ipAddress, macAddress: macAddress)
        
        var sharedDefaults = NSUserDefaults(suiteName: "group.camperoo.test")
        sharedDefaults?.setObject(ipAddress, forKey: "hueIpAddress")
        sharedDefaults?.setObject(macAddress, forKey: "hueMacAddress")
        sharedDefaults?.synchronize()
        
        // Setting the hearbeat running will cause the SDK to regularly update the cache with the status of the bridge resources
        let delay = 1 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            self.enableLocalHeartbeat()
        }
    }
}

// MARK: - BridgePushLinkViewControllerDelegate
extension AppDelegate: BridgePushLinkViewControllerDelegate {
    
    /// Delegate method for PHBridgePushLinkViewController which is invoked if the pushlinking was successfull
    func pushlinkSuccess() {
        // Push linking succeeded we are authenticated against the chosen bridge.
        
        // Remove pushlink view controller
        self.window!.rootViewController!.dismissViewControllerAnimated(true, completion: nil)
        
        // Start local heartbeat
        let delay = 1 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            self.enableLocalHeartbeat()
        }
    }
    
    /// Delegate method for PHBridgePushLinkViewController which is invoked if the pushlinking was not successfull
    func pushlinkFailed(error: PHError) {
        // Remove pushlink view controller
        self.window!.rootViewController!.dismissViewControllerAnimated(true, completion: nil)
        
        // Check which error occured
        if error.code == Int(PUSHLINK_NO_CONNECTION.value) {
            noLocalConnection()
            
            // Start local heartbeat (to see when connection comes back)
            let delay = 1 * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            dispatch_after(time, dispatch_get_main_queue()) {
                self.enableLocalHeartbeat()
            }
        } else {
            // Bridge button not pressed in time
            authenticationFailedAlert = UIAlertController(
                title: NSLocalizedString("Authentication failed", comment: "Authentication failed alert title"),
                message: NSLocalizedString("Make sure you press the button within 30 seconds", comment: "Authentication failed alert message"),
                preferredStyle: .Alert
            )
            
            let retryAction = UIAlertAction(
                title: NSLocalizedString("Retry", comment: "Authentication failed alert retry button"),
                style: .Default
                ) { (_) in
                    // Retry authentication
                    self.doAuthentication()
            }
            authenticationFailedAlert!.addAction(retryAction)
            
            let cancelAction = UIAlertAction(
                title: NSLocalizedString("Cancel", comment: "Authentication failed cancel button"),
                style: .Cancel
                ) { (_) in
                    // Remove connecting loading message
                    self.removeLoadingView()
                    // Cancel authentication and disable local heartbeat unit started manually again
                    self.disableLocalHeartbeat()
            }
            authenticationFailedAlert!.addAction(cancelAction)
            
            window!.rootViewController!.presentViewController(authenticationFailedAlert!, animated: true, completion: nil)
        }
    }
}
