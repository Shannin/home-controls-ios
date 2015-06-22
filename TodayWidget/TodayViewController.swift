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
    @IBOutlet var viewsContainer: UIScrollView?
    @IBOutlet var imHomeContainer: UIView?
    @IBOutlet var imHomeButton: UIButton?
    
    @IBOutlet var hueControlsContainer: UIView?
    
    func userDefaultsChanged(notification: NSNotification) {
        
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "userDefaultsChanged:", name: NSUserDefaultsDidChangeNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        var currentView: TodayWidgetAvailableViews = UserDefaultsWrapper.sharedInstance.todayWidgetCurrentView
        var currentView: TodayWidgetAvailableViews = .ImHome
        setCurrentViewToView(currentView)
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        completionHandler(NCUpdateResult.NewData)
    }
    
    func setCurrentViewToView(view: TodayWidgetAvailableViews) {
        var w = self.viewsContainer!.frame.width
        
        if view == .ImHome {
            self.preferredContentSize = CGSizeMake(w, 90)
            self.viewsContainer?.scrollRectToVisible(CGRectMake(0, 0, w, 90), animated: true)
        } else if view == .HueControls {
            self.preferredContentSize = CGSizeMake(w, 140)
            self.viewsContainer?.scrollRectToVisible(CGRectMake(0, 90, w, 90), animated: true)
            self.layoutCurrentLightOptions()
        }
        
        
        UserDefaultsWrapper.sharedInstance.todayWidgetCurrentView = view
    }
    
    
    // MARK:- Door Controls
    
    func openDoor() {
        var urlPath = UserDefaultsWrapper.sharedInstance.openDoorURL
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
    
    func turnOnLightsNowHome() {
        var imHomeScene = UserDefaultsWrapper.sharedInstance.imHomeLightScene
        if imHomeScene != nil {
            setLightScene(imHomeScene!)
        }
    }
    
    
    // MARK:- Input Actions
    
    @IBAction func imHomeButtonAction() {
        openDoor()
        turnOnLightsNowHome()
        setCurrentViewToView(.HueControls)
    }
    
    func turnLightsOnWithSceneIndex(id: UIButton?) {
        if id == nil {
            return
        }
        
        var allScenes = UserDefaultsWrapper.sharedInstance.getBasicScenes()
        
        var idx = id!.tag
        if idx < allScenes.count {
            var scene = allScenes[idx]
            HueAPIWrapper.sharedInstance.setAllLightsToScene(scene, completion: { (on, error) -> Void in
                
            })
        }
    }
    
    
    // MARK:- Layout methods
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        var margins = defaultMarginInsets
        margins.left = 0
        margins.right = 0
        margins.bottom = 0;
        return margins
    }
    
    func layoutCurrentLightOptions() {
        if self.hueControlsContainer == nil {
            return
        }
        
        for v in self.hueControlsContainer!.subviews as! [UIView] {
            v.removeFromSuperview()
        }
        
        var scenesArray = UserDefaultsWrapper.sharedInstance.getBasicScenes()
        for (idx, scene) in enumerate(scenesArray) {
            var btn: UIButton = UIButton.buttonWithType(.Custom) as! UIButton
            btn.setTitle(scene, forState: .Normal)
            btn.backgroundColor = UIColor.redColor()
            
            var f: CGRect = CGRect()
            f.size.height = self.hueControlsContainer!.frame.size.height
            f.size.width = self.hueControlsContainer!.frame.size.width / CGFloat(scenesArray.count)
            f.origin.x = CGFloat(idx) * f.size.width
            f.origin.y = 0
            btn.frame = f
            
            btn.tag = idx
            btn.addTarget(self, action: "turnLightsOnWithSceneIndex:", forControlEvents: .TouchUpInside)
            
            self.hueControlsContainer!.addSubview(btn)
        }
    }
    
}
