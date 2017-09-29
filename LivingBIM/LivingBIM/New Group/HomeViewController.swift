//
//  HomeViewController.swift
//  LivingBIM
//
//  Created by Morio Ramdenbourg on 9/18/17.
//  Copyright © 2017 CAEE. All rights reserved.
//

import UIKit
import CoreLocation

class HomeViewController: UIViewController, CLLocationManagerDelegate {
    
    private var locationManager: CLLocationManager?
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get current location
        getLocation()
        
        // Get the username and set the label to that username
        getUsername()
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
        // Create text field
        var inputTextField: UITextField?
        
        // Create the AlertController
        let actionSheetController: UIAlertController = UIAlertController(title: "Name Required", message: "What is your name?", preferredStyle: .alert)
        
        // Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in }
        actionSheetController.addAction(cancelAction)
        
        // Create and an option action
        let saveAction: UIAlertAction = UIAlertAction(title: "Save", style: .default) { action -> Void in
            // Save the name to the user defaults
            
            
            // Set the label
            self.usernameLabel.text = inputTextField?.text
            
        }
        actionSheetController.addAction(saveAction)
        
        // Add a text field
        actionSheetController.addTextField { textField -> Void in
            inputTextField = textField
            inputTextField?.placeholder = "Name"
            saveAction.isEnabled = false
        }
        
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
