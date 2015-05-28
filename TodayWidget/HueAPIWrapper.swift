//
//  HueAPIWrapper.swift
//  Home Controls
//
//  Created by Shannin Ciprich on 4/14/15.
//  Copyright (c) 2015 Shannin. All rights reserved.
//

import Foundation

enum HueAPIError {
    case noHubSelected
    case somethingWentWrong
}

private let _sharedHueAPI = HueAPIWrapper()

class HueAPIWrapper {
    var basePath: String?  // http://\(ip)/api/\(developerName)
    
    func updateVariables() {
        var homeControlsAPIURL = UserDefaultsWrapper.sharedInstance.homeControlsAPIUrl
        if homeControlsAPIURL != nil {
            self.basePath = "\(homeControlsAPIURL!)/lights"
        }
    }
    
    
    init() {
        updateVariables();
    }
    
    func allScenes(completion: (scenes: [[String: AnyObject]]?, error: HueAPIError?) -> Void) {
        if self.basePath == nil {
            completion(scenes: nil, error: .noHubSelected)
            return
        }
        
        let urlPath = "\(basePath!)/scenes"
        
        var err: NSError?
        var url: NSURL = NSURL(string: urlPath)!
        var request: NSMutableURLRequest = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"
        
        let queue:NSOperationQueue = NSOperationQueue()
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler:{ (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            var err: NSError?
            var jsonData: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err)
            
            dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                if err != nil {
                    completion(scenes: nil, error: .somethingWentWrong)
                } else {
                    completion(scenes: jsonData as? [[String: AnyObject]], error: nil)
                }
            })
        })
    }
    
    func setAllLightsToScene(sceneId: String, completion: (on: Bool, error: HueAPIError?) -> Void) {
        if self.basePath == nil {
            completion(on: false, error: .noHubSelected)
            return
        }
        
        let urlPath = "\(basePath!)/all/\(sceneId)"
        
        var err: NSError?
        var url: NSURL = NSURL(string: urlPath)!
        var request: NSMutableURLRequest = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"
        
        let queue:NSOperationQueue = NSOperationQueue()
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler:{ (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            var err: NSError?
            var jsonData: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err)
            println("Turn on lights: \(jsonData), \(err)")
            
            dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                if err != nil {
                    completion(on: false, error: .somethingWentWrong)
                } else {
                    completion(on: true, error: nil)
                }
            })
        })
    }
    
    class var sharedInstance: HueAPIWrapper {
        return _sharedHueAPI
    }
}
