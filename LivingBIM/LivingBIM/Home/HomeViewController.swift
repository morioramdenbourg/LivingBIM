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
import BoxContentSDK

let cls = "HomeViewController"

class HomeViewController: UIViewController, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource {
    
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
    
    // Constants
    private var cellHeight: CGFloat = 200
    private var folderName: String = "capture"

    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    private var captures: [NSManagedObject]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(cls, "viewDidLoad")
        
        // Set table view delegates
        tableView.delegate = self
        tableView.dataSource = self
        
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
            captures = try managedContext.fetch(fetchRequest)
            tableView.reloadData()
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return captures?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: HomeTableViewCell = self.tableView.dequeueReusableCell(withIdentifier: Keys.Cell) as! HomeTableViewCell
        
        guard let capture = captures?[indexPath.row] else {
            return cell
        }
        
        // Grab data
        let username = capture.value(forKeyPath: Keys.CoreData.Capture.Username) as? String
        let location = capture.value(forKeyPath: Keys.CoreData.Capture.Location) as? String
        let date = capture.value(forKeyPath: Keys.CoreData.Capture.Date) as? Date
        
        // Put on cell
        cell.usernameLabel.text = username
        cell.locationLabel.text = location
        cell.dateLabel.text = date?.toString(dateFormat: "yyy-MM-dd HH:mm:ss")
        
        // Hack - set to nil for async operations and add tag
        cell.imgView.image = nil
        cell.tag = indexPath.row
        
        DispatchQueue.main.async { _ in
            if cell.tag == indexPath.row {
                if let data = capture.value(forKeyPath: Keys.CoreData.Capture.RGBFrame) as? Data {
                    cell.imgView.image = UIImage(data: data)
                }
            }
        }
    
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(cls, "tapped cell at:", indexPath.row)
    }
    
    // Upload to Box
    @IBAction func uploadButton(_ sender: Any) {
        print(cls, "uploading to box")
        
        guard let contentClient = BOXContentClient.default() else {
            print(cls, "error while uploading")
            return
        }
        
        // Authenticate box
        contentClient.authenticate(completionBlock: { (user: BOXUser?, error: Error?) -> Void in
            if (error == nil) {
                print(self.cls, "login successful")
                print(self.cls, "logged in as:", (user?.login!)! as String)
                
                guard let captures = self.captures else {
                    print(self.cls, "captures empty")
                    return;
                }
                
                // Iterate through the captures
                for capture in captures {
                    
                    // Grab from Core Data
                    guard let date = capture.value(forKeyPath: Keys.CoreData.Capture.Date) as? Date else {
                        print(self.cls, "no date for the capture ... skipping")
                        continue;
                    }

                    let username = capture.value(forKeyPath: Keys.CoreData.Capture.Username) as? String ?? "<invalid_name>"
                    let location = capture.value(forKeyPath: Keys.CoreData.Capture.Location) as? String ?? "<invalid_location>"
                    let text = capture.value(forKeyPath: Keys.CoreData.Capture.Text) as? String ?? ""
                    let rgbData = capture.value(forKeyPath: Keys.CoreData.Capture.RGBFrame) as? Data ?? Data()
                    let depthData = capture.value(forKeyPath: Keys.CoreData.Capture.DepthFrame) as? Data ?? Data()
                    
                    // Create the folder to hold the data
                    let format = "yyy-MM-dd_HH-mm-ss"
                    let dateString = date.toString(dateFormat: format)
                    let folderName = self.folderName + "-" + "frame" + "--" + dateString;
                    let folderRequest: BOXFolderCreateRequest = contentClient.folderCreateRequest(withName: folderName, parentFolderID: BOXAPIFolderIDRoot)
                    
                    print(self.cls, "uploading:", folderName)
                    folderRequest.perform(completion: { (folder: BOXFolder?, error: Error?) in
                        if (error == nil) {
                            let folder = folder!
                            print(self.cls, "created folder:", folder.name)
                            
                            // Create metadata file
                            var capture = ""
                            capture += "Capture Details:\n"
                            capture += "--------------------------------\n"
                            capture += "Username: " + username + "\n"
                            capture += "Date: " + dateString + "\n"
                            capture += "Location: " + location + "\n"
                            capture += "Description: " + text
                            
                            print(self.cls, "uploading data to folder:", folder.name)
                            // Completion handler for file upload
                            let uploadCheck = { (file: BOXFile?, error: Error?) in
                                if (error == nil && file != nil) {
                                    print(self.cls, "completed upload to", (folder.name)!)
                                }
                                else {
                                    print(self.cls, "error while uploading to", (folder.name)!)
                                    print(self.cls, error!)
                                }
                            }
                            
                            // Add the rgb photo
                            contentClient.fileUploadRequestToFolder(withID: folder.modelID, from: rgbData, fileName: "color-image.png").perform(progress: nil, completion: uploadCheck)
                            
                            // Add depth photo
                            contentClient.fileUploadRequestToFolder(withID: folder.modelID, from: depthData, fileName: "depth-image.png").perform(progress: nil, completion: uploadCheck)
                            
                            // Add capture data file
                            if let captureData = capture.data(using: .utf8) {
                                contentClient.fileUploadRequestToFolder(withID: folder.modelID, from: captureData, fileName: "capture.txt").perform(progress: nil, completion: uploadCheck)
                            }
                        }
                        else {
                            print(self.cls, "error creating folder:", folderName)
                            print(self.cls, error!)
                        }
                    })
                }
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
