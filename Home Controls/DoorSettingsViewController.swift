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
        
        self.openDoorUrlInput?.text = UserDefaultsWrapper.sharedInstance.openDoorURL
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
        UserDefaultsWrapper.sharedInstance.openDoorURL = openDoorURL
        
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }

}

