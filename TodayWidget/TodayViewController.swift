//
//  TodayViewController.swift
//  TodayWidget
//
//  Created by Shannin Ciprich on 4/12/15.
//  Copyright (c) 2015 Shannin. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    let WIFI_ATTEMPT_DELAY = 2.0;
    let WIFI_ATTEMPT_TRIES = 10;
    
    @IBOutlet var imHomeButton: UIButton?
    
    
    func userDefaultsChanged(notification: NSNotification) {
        
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "userDefaultsChanged:", name: NSUserDefaultsDidChangeNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.preferredContentSize = CGSizeMake(320, 100);
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        completionHandler(NCUpdateResult.NewData)
    }
    
    
    // MARK:- Door Controls
    
    func openDoor() {
        let urlPath = getUserDefaultWithKey("DoorOpenURL") as? String
        
        if urlPath != nil {
            var url: NSURL = NSURL(string: urlPath!)!
            var request1: NSURLRequest = NSURLRequest(URL: url)
            let queue:NSOperationQueue = NSOperationQueue()
            NSURLConnection.sendAsynchronousRequest(request1, queue: queue, completionHandler:{ (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
                var err: NSError
                var responseString = NSString(data: data, encoding: NSUTF8StringEncoding)
                
                println("Open Door: \(responseString!)")
            })
        }
    }
    
    
    // MARK:- Hue Controls
    
    func setLightScene(scene: String) {
        println("Set lights to scene: \(scene)")
        HueAPIWrapper.sharedInstance.setAllLightsToScene(scene, completion: { (on, error) -> Void in
            if !on {
                // Connection might be weak, wait until closer to room to try again
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(5.0 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
                    HueAPIWrapper.sharedInstance.setAllLightsToScene(scene, completion: { (on, error) -> Void in
                        if !on {
                            println("Unable to turn on lights")
                        }
                    })
                }
            }
        })
    }
    
    /*
        Hue works best when connected to wifi, so if the phone isn't connected to wifi:
            check every y seconds until it is connected up to x attempts
    */
    
    func attemptLightsOnWithScene(sceneId: String, reachability: Reachability, attempt: Int) {
        var status = reachability.currentReachabilityStatus()
        if status.value == ReachableViaWiFi.value {
            setLightScene(sceneId)
            reachability.stopNotifier()
        } else if (attempt < WIFI_ATTEMPT_TRIES) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(WIFI_ATTEMPT_DELAY * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
                self.attemptLightsOnWithScene(sceneId, reachability: reachability, attempt: attempt + 1)
            }
        }
    }
    
    func turnOnLightsNowHome() {
        var scenesArray = getUserDefaultWithKey("ImHomeLightScene") as? [String]
        if scenesArray != nil && scenesArray!.count >= 1 {
            let sceneId: String = scenesArray![0]
            var reachability = Reachability.reachabilityForInternetConnection()
            reachability.startNotifier()
            attemptLightsOnWithScene(sceneId, reachability: reachability, attempt: 0)
        }
    }
    
    
    // MARK:- Input Actions
    
    @IBAction func imHomeButtonAction() {
        //openDoor()
        turnOnLightsNowHome()
    }
    
    
    // MARK:- Layout methods
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        var margins = defaultMarginInsets
        margins.left = 0
        margins.right = 0
        margins.bottom = 0;
        return margins
    }
    
    
    // MARK:- Support Methods
    
    func getUserDefaultWithKey(key: String) -> AnyObject? {
        var defaults = NSUserDefaults(suiteName: "group.camperoo.test")
        return defaults?.objectForKey(key)
    }
}
