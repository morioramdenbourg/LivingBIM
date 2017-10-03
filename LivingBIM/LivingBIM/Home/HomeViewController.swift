//
//  HomeViewController.swift
//  LivingBIM
//
//  Created by Morio Ramdenbourg on 9/18/17.
//  Copyright © 2017 CAEE. All rights reserved.
//

import UIKit
import CoreLocation

const cls = "HomeViewController"

class HomeViewController: UIViewController, CLLocationManagerDelegate {
    
    private var locationManager: CLLocationManager?
    private var defaults: UserDefaults?
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Instance of user defaults
        defaults = UserDefaults.standard
        
        // Get current location
        getLocation()
        
        // Get the username and set the label to that username
        if let username = defaults?.string(forKey: Keys.UserDefaults.Username) {
            self.usernameLabel.text = username
        }
        else {
            getUsername()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Show navigation bar
        self.navigationController?.navigationBar.isHidden = false
    }
    
    private func getLocation() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self;
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.requestAlwaysAuthorization()
        locationManager?.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        self.locationLabel.text = String(format: "%.2f", locValue.latitude) + ", " + String(format: "%.2f", locValue.longitude)
    }
    
    private func getUsername() {
        print(cls, "getting username")
        
        // Create text field
        var inputTextField: UITextField?
        
        // Create the AlertController
        let actionSheetController: UIAlertController = UIAlertController(title: "Username Required", message: "What is your username?", preferredStyle: .alert)
        
        // Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in }
        actionSheetController.addAction(cancelAction)
        
        // Create and an option action
        let saveAction: UIAlertAction = UIAlertAction(title: "Save", style: .default) { action -> Void in
            // Get text
            let text: String = inputTextField?.text ?? ""
            
            // Save the name to the user defaults
            self.defaults?.set(text, forKey: Keys.UserDefaults.Username)
            
            // Set the label
            self.usernameLabel.text = inputTextField?.text
            
        }
        actionSheetController.addAction(saveAction)
        
        // Add a text field
        actionSheetController.addTextField { textField -> Void in
            inputTextField = textField
            inputTextField?.placeholder = "Username"
            saveAction.isEnabled = false
        }
        
        // If the text field is empty, then disable the Save button
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UITextFieldTextDidChange, object: inputTextField, queue: OperationQueue.main) { (notification) in
            saveAction.isEnabled = inputTextField?.text?.count ?? 0 > 0
        }
    
        // Present alert
        self.present(actionSheetController, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
