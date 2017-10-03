//
//  HomeViewController.swift
//  LivingBIM
//
//  Created by Morio Ramdenbourg on 9/18/17.
//  Copyright © 2017 CAEE. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

let cls = "HomeViewController"

class HomeViewController: UIViewController, CLLocationManagerDelegate {
    
    // Core Data
    private var appDelegate: AppDelegate?
    private var managedContext: NSManagedObjectContext?
    private var entity: NSEntityDescription?
    
    // User Defaults
    private var defaults: UserDefaults?
    
    // Class name
    private let cls = String(describing: HomeViewController.self)
    
    // Location
    private var locationManager: CLLocationManager?

    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(cls, "viewDidLoad")
        
        // Core Data
        print(cls, "setting up Core Data")
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        guard let appDelegate = self.appDelegate else {
            return
        }
        
        managedContext = appDelegate.persistentContainer.viewContext
        guard let managedContext = self.managedContext else {
            return
        }
        
        entity = NSEntityDescription.entity(forEntityName: Keys.CoreData.Capture.Key, in: managedContext)
        print(cls, "finished setting up Core Data")
        
        // Instance of user defaults
        defaults = UserDefaults.standard
        
        // Get current location
        if let location = defaults?.string(forKey: Keys.UserDefaults.Location) {
            self.locationLabel.text = location
        }
        else {
            getLocation()
        }
        
        // Get the username and set the label to that username
        if let username = defaults?.string(forKey: Keys.UserDefaults.Username) {
            self.usernameLabel.text = username
        }
        else {
            getUsername()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print(cls, "viewWillAppear")
        
        // Show navigation bar
        self.navigationController?.navigationBar.isHidden = false
        
        // Load the table
        guard let managedContext = self.managedContext else {
            return
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Keys.CoreData.Capture.Key)
        fetchRequest.returnsObjectsAsFaults = false // TODO: remove for debug
        do {
            let captures = try managedContext.fetch(fetchRequest)
            print(cls, "CAPTURES:", captures)
        } catch let error as NSError {
            print(cls, "ERROR:", "Could not fetch from Core Data")
            print(cls, error)
        }
        
    }
    
    private func getLocation() {
        print(cls, "getting location")
        locationManager = CLLocationManager()
        locationManager?.delegate = self;
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.requestAlwaysAuthorization()
        locationManager?.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        let formattedLoc = formatLocation(locValue)
        self.locationLabel.text = formattedLoc
        self.defaults?.set(formattedLoc, forKey: Keys.UserDefaults.Location)
        locationManager?.stopUpdatingLocation()
        print(cls, "stop getting location")
    }
    
    private func getUsername() {
        print(cls, "getting username")
        
        // Create text field
        var inputTextField: UITextField?
        
        // Create the AlertController
        let actionSheetController: UIAlertController = UIAlertController(title: "Username Required", message: "Enter Username", preferredStyle: .alert)
        
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
        
        // Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in }
        actionSheetController.addAction(cancelAction)
        
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
