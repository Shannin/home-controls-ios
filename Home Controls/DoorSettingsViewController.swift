//
//  DoorSettingsViewController.swift
//  Home Controls
//
//  Created by Shannin Ciprich on 4/12/15.
//  Copyright (c) 2015 Shannin. All rights reserved.
//

import UIKit
import CoreLocation

class DoorSettingsViewController: UIViewController, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    
    @IBOutlet var openDoorUrlInput: UITextField?
    @IBOutlet var addressInput: UITextField?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.openDoorUrlInput?.text = UserDefaultsWrapper.sharedInstance.openDoorURL
        self.addressInput?.text = UserDefaultsWrapper.sharedInstance.homeAddress
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.openDoorUrlInput?.becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.openDoorUrlInput?.resignFirstResponder()
        self.addressInput?.resignFirstResponder()
    }
    
    func setGeofenceForCoords(coords: CLLocationCoordinate2D) -> Bool {
        if !CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion) {
            UIAlertView(title: "Not Available", message: "Unfortunately, geofencing is not available.", delegate: nil, cancelButtonTitle: "OK").show()
            return false
        }
        
        if CLLocationManager.authorizationStatus() != .AuthorizedAlways {
            UIAlertView(title: "Location Services Not Enabled", message: "Your address is saved but will only be activated once you grant Geotify permission to access the device location.", delegate: nil, cancelButtonTitle: "OK").show()
        }
        
        let region = CLCircularRegion(center: coords, radius: 100, identifier: "home-location")
        locationManager.startMonitoringForRegion(region)
        
        return true
    }
    
    func updateHomeGeofenceRegion(address: String?, completion: () -> Void) {
        // Remove locations
        for region in locationManager.monitoredRegions {
            if let circularRegion = region as? CLCircularRegion {
                locationManager.stopMonitoringForRegion(circularRegion)
            }
        }
        
        UserDefaultsWrapper.sharedInstance.homeAddress = address
        
        if address != nil && !address!.isEmpty {
            CLGeocoder().geocodeAddressString(address) { (placemarks, error) -> Void in
                if error != nil || placemarks.count == 0  {
                    UIAlertView(title: "Address Not Found", message: "Couldn't find address, please try again.", delegate: nil, cancelButtonTitle: "OK").show()
                    return
                }
                
                var coords: CLLocationCoordinate2D? = (placemarks[0] as? CLPlacemark)?.location.coordinate
                if coords != nil {
                    if self.setGeofenceForCoords(coords!) {
                        completion()
                    }
                }
            }
        } else {
            completion()
        }
    }
    
    
    @IBAction func updateButtonAction() {
        var openDoorURL = self.openDoorUrlInput?.text
        UserDefaultsWrapper.sharedInstance.openDoorURL = openDoorURL
        
        var address: String? = self.addressInput != nil ? self.addressInput?.text : nil
        updateHomeGeofenceRegion(address, completion: { () -> Void in
            self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        })
    }

}

