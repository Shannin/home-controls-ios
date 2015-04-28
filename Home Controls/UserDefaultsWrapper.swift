//
//  UserDefaultsWrapper.swift
//  Home Controls
//
//  Created by Shannin Ciprich on 4/27/15.
//  Copyright (c) 2015 Shannin. All rights reserved.
//

import Foundation

private let _sharedUserDefaultsWrapper = UserDefaultsWrapper()

class UserDefaultsWrapper {
    var openDoorURL: String? {
        set {
            if newValue != nil && !newValue!.isEmpty {
                setUserDefault("DoorOpenURL", value: newValue!)
            } else {
                removeUserDefaultForKey("DoorOpenURL")
            }
        }
        get {
            return getUserDefaultForKey("DoorOpenURL") as? String
        }
    }
    
    var hueIpAddress: String? {
        set {
            if newValue != nil && !newValue!.isEmpty {
                setUserDefault("hueIpAddress", value: newValue!)
            } else {
                removeUserDefaultForKey("hueIpAddress")
            }
        }
        get {
            return getUserDefaultForKey("hueIpAddress") as? String
        }
    }
    
    var imHomeLightScene: String? {
        set {
            if newValue != nil && !newValue!.isEmpty {
                setUserDefault("ImHomeLightScene", value: [newValue!])
            } else {
                removeUserDefaultForKey("ImHomeLightScene")
            }
        }
        get {
            var val = getUserDefaultForKey("ImHomeLightScene") as? [String]
            
            if val != nil {
                return val![0]
            }
            
            return nil
        }
    }
    
    
    func setScenesForKey(key: String, scenes: [String]) {
        setUserDefault(key, value: scenes)
    }
    
    func getScenesForKey(key: String) -> [String] {
        var scenes = getUserDefaultForKey(key) as? [String]
        
        if scenes != nil {
            return scenes!
        }
        
        return []
    }
    
    func getBasicScenes() -> [String] {
        return getScenesForKey("HueControlsScenes")
    }

    
    func getUserDefaultForKey(key: String) -> AnyObject? {
        var sharedDefaults = NSUserDefaults(suiteName: "group.camperoo.test")
        return sharedDefaults?.objectForKey(key)
    }
    
    func setUserDefault(key: String, value: AnyObject) {
        var sharedDefaults = NSUserDefaults(suiteName: "group.camperoo.test")
        sharedDefaults?.setObject(value, forKey: key)
        sharedDefaults?.synchronize()
    }
    
    func removeUserDefaultForKey(key: String) {
        var sharedDefaults = NSUserDefaults(suiteName: "group.camperoo.test")
        sharedDefaults?.removeObjectForKey(key)
        sharedDefaults?.synchronize()
    }
    
    class var sharedInstance: UserDefaultsWrapper {
        return _sharedUserDefaultsWrapper
    }
}
