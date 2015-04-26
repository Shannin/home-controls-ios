//
//  HueOptionsTableViewController.swift
//  Home Controls
//
//  Created by Shannin Ciprich on 4/24/15.
//  Copyright (c) 2015 Shannin. All rights reserved.
//

import UIKit

class HueOptionsTableViewController: UITableViewController {
    
    var availableOptions: [[String: AnyObject]] = [["key": "ImHomeLightScene", "string": "I'm Home Scene", "max_scenes": 1], ["key": "HueControlsScenes", "string": "Hue Controls", "max_scenes": 4]]

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return availableOptions.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        
        var option: [String: AnyObject] = availableOptions[indexPath.row]
        
        cell.textLabel?.text = option["string"] as? String

        return cell
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "ShowHueSceneSelector" {
            var sceneListTableView = segue.destinationViewController as! ScenesListTableViewController
            
            var optionDetails = availableOptions[self.tableView.indexPathForSelectedRow()!.row]
            sceneListTableView.optionKey = optionDetails["key"] as? String
            sceneListTableView.maxScenes = optionDetails["max_scenes"] as! Int
        }
    }
}
