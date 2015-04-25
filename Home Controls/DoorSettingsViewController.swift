//
//  DoorSettingsViewController.swift
//  Home Controls
//
//  Created by Shannin Ciprich on 4/12/15.
//  Copyright (c) 2015 Shannin. All rights reserved.
//

import UIKit

class DoorSettingsViewController: UIViewController {
    
    @IBOutlet var openDoorUrlInput: UITextField?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.openDoorUrlInput?.text = getUserDefaultValueForKey("DoorOpenURL") as? String
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.openDoorUrlInput?.becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.openDoorUrlInput?.resignFirstResponder()
    }
    
    @IBAction func updateButtonAction() {
        var openDoorURL = self.openDoorUrlInput?.text
        setUserDefaultValue(openDoorURL!, key: "DoorOpenURL");
        
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK:- UserDefaults
    
    func setUserDefaultValue(value: AnyObject, key: String) {
        var sharedDefaults = NSUserDefaults(suiteName: "group.camperoo.test")
        sharedDefaults?.setObject(value, forKey: key)
        sharedDefaults?.synchronize()
    }
    
    func getUserDefaultValueForKey(key: String) -> AnyObject? {
        var sharedDefaults = NSUserDefaults(suiteName: "group.camperoo.test")
        return sharedDefaults?.objectForKey(key)
    }

}

