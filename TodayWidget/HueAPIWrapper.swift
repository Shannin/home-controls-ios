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
        var ip = UserDefaultsWrapper.sharedInstance.hueIpAddress
        var username: String? = "homecontrols"
        
        if ip != nil {
            self.basePath = "http://\(ip!)/api/\(username!)"
        }
    }
    
    
    init() {
        updateVariables();
    }
    
    func setAllLightsToScene(sceneId: String, completion: (on: Bool, error: HueAPIError?) -> Void) {
        if self.basePath == nil {
            completion(on: false, error: .noHubSelected)
            return
        }
        
        let urlPath = "\(basePath!)/groups/0/action"
        var body = ["on": true, "scene": sceneId]
        
        var err: NSError?
        var url: NSURL = NSURL(string: urlPath)!
        var request: NSMutableURLRequest = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "PUT"
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(body, options: nil, error: &err)
        
        let queue:NSOperationQueue = NSOperationQueue()
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler:{ (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            var err: NSError?
            var response: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err)
            println("Turn on lights: \(response), \(err)")
            
            if err != nil {
                completion(on: false, error: .somethingWentWrong)
            } else {
                completion(on: true, error: nil)
            }
        })
    }
    
    class var sharedInstance: HueAPIWrapper {
        return _sharedHueAPI
    }
}
