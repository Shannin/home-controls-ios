//
//  ScenesListTableViewController.swift
//  Home Controls
//
//  Created by Shannin Ciprich on 4/13/15.
//  Copyright (c) 2015 Shannin. All rights reserved.
//

import UIKit

class ScenesListTableViewController: UITableViewController {
    var optionKey: String?
    var maxScenes: Int = 1
    var optionValues: [String] = []
    var scenes = [NSObject: AnyObject]()
    
    func loadConnectedBridgeValues() {
        let cache = PHBridgeResourcesReader.readBridgeResourcesCache()
        
        // Check if we have connected to a bridge before
        if cache?.bridgeConfiguration?.ipaddress != nil {
            // Check if we are connected to the bridge right now
            let appDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
            if appDelegate.phHueSdk.localConnected() {
                if cache.scenes != nil {
                    self.scenes = cache!.scenes
                    self.tableView.reloadData()
                }
            } else {
                
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.optionKey != nil {
            self.optionValues = UserDefaultsWrapper.sharedInstance.getScenesForKey(self.optionKey!)
        }
        
        loadConnectedBridgeValues()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        if self.optionKey != nil {
            UserDefaultsWrapper.sharedInstance.setScenesForKey(self.optionKey!, scenes: optionValues)
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.scenes.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        
        var scene = self.scenes[self.scenes.keys.array[indexPath.row]] as! PHScene
        cell.textLabel?.text = scene.name
        
        if contains(self.optionValues, scene.identifier) {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let sceneId = self.scenes.keys.array[indexPath.row] as! String
        if contains(self.optionValues, sceneId) {
            // Remove from values array
            self.optionValues.removeAtIndex(find(self.optionValues, sceneId)!)
        } else {
            // Insert into values array
            if self.optionValues.count == maxScenes {
                self.optionValues.removeAtIndex(0)
            }
            
            self.optionValues.append(sceneId)
        }
        
        self.tableView.reloadData()
    }

}
