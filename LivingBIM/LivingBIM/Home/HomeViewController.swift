//
//  HomeViewController.swift
//  LivingBIM
//
//  Created by Morio Ramdenbourg on 9/18/17.
//  Copyright © 2017 CAEE. All rights reserved.
//

import UIKit
import CoreData
import BoxContentSDK
import SwiftyJSON

fileprivate let cls = "HomeViewController"

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // Core Data
    private var appDelegate: AppDelegate?
    private var managedContext: NSManagedObjectContext?
    private var entity: NSEntityDescription?
    
    // Other variables
    private var captures: [NSManagedObject]? // Store captures
    private var screenSize: CGRect? // Screen size
    private var spinner: SpinnerView? // Spinner
    
    // Constants
    private let cellHeight: CGFloat = 200
    private let folderName: String = "scan"
    private let rootFolderName: String = "scans"
    private let cls = String(describing: HomeViewController.self) // Class name

    // Outlets
    @IBOutlet weak var buttonOutlet: UIButton!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var buildingLabel: UILabel!
    
    @IBAction func setLocationAction(_ sender: Any) {
        askBuildingInfo(viewController: self) { (abbr, name, room) in
            let lbl = name + " (" + abbr + ") " + " - " + room
            self.buildingLabel.text = lbl
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the screen size and initialize spinner
        screenSize = UIScreen.main.bounds
        spinner = SpinnerView(frame: CGRect(x: (screenSize?.width)! / 2, y: (screenSize?.height)! / 2, width: 100, height: 100))
        
        log(moduleName: cls, "viewDidLoad")
        
        // Remove the lines on an empty table
        self.tableView.tableFooterView = UIView(frame: .zero)
        
        // Set table view delegates
        tableView.delegate = self
        tableView.dataSource = self
        
        // Core Data
        log(moduleName: cls, "setting up Core Data")
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        guard let appDelegate = self.appDelegate else {
            return
        }
        
        managedContext = appDelegate.persistentContainer.viewContext
        guard let managedContext = self.managedContext else {
            return
        }
        
        entity = NSEntityDescription.entity(forEntityName: Keys.CoreData.Capture.Key, in: managedContext)
        log(moduleName: cls, "finished setting up Core Data")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        log(moduleName: cls, "viewWillAppear")
        
        // Show navigation bar
        self.navigationController?.navigationBar.isHidden = false
                
        // Get the username and set the label to that username
        if let username = getUsername() {
            self.usernameLabel.text = username
        }
        else {
            askUsername(viewController: self) { (text: String) in
                self.usernameLabel.text = text
            }
        }
        
        // Ask for building information if not already there
        if let abbr = getBuildingAbbr(), let name = getBuildingName(), let room = getRoomNumber() {
            let lbl = name + " (" + abbr + ") " + " - " + room
            buildingLabel.text = lbl
        }
        else {
            askBuildingInfo(viewController: self) { (abbr, name, room) in
                let lbl = name + " (" + abbr + ") " + " - " + room
                self.buildingLabel.text = lbl
            }
        }
        
        // Display location
        locationLabel.text = appDelegate?.getLocation()
        
        // Load the table
        guard let managedContext = self.managedContext else {
            return
        }
        
        // Fetching from core data
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Keys.CoreData.Capture.Key)
        fetchRequest.returnsObjectsAsFaults = false // TODO: remove for debug
        do {
            captures = try managedContext.fetch(fetchRequest)
            reloadCheck()
        } catch let error as NSError {
            log(moduleName: cls, "ERROR:", "Could not fetch from Core Data")
            log(moduleName: cls, error)
        }
    }
    
    // Check if the button should be enabled or not when reloading
    private func reloadCheck() {
        if (self.captures?.count == 0) {
            buttonOutlet.isEnabled = false
        }
        else {
            buttonOutlet.isEnabled = true
        }
        tableView.reloadData()
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
        log(moduleName: cls, "tapped cell at:", indexPath.row)
    }
    
    // Upload to Box
    @IBAction func uploadButton(_ sender: Any) {
        log(moduleName: cls, "uploading to box")
        
        // Disable the button
        buttonOutlet.isEnabled = false
        
        // Display the spinner
        self.view.addSubview(spinner!)
        
        guard let contentClient = BOXContentClient.default() else {
            log(moduleName: cls, "error while uploading")
            return
        }
                
        // Authenticate box
        contentClient.authenticate(completionBlock: { (user: BOXUser?, error: Error?) -> Void in
            if (error == nil) {
                log(moduleName: self.cls, "login successful")
                log(moduleName: self.cls, "logged in as:", (user?.login!)! as String)
                
                // Add all to the "rootFolderName" folder, create if it doesn't exist
                let folderItemsRequest: BOXFolderItemsRequest = contentClient.folderItemsRequest(withID: BOXAPIFolderIDRoot)
                folderItemsRequest.perform(completion: { (items: Array?, error: Error?) in
                    var modelID: String? = nil
                    
                    // Find the folder
                    if (items != nil && error == nil) {
                        let items = items as! [BOXFolder]
                        for item in items {
                            if (item.name == self.rootFolderName) {
                                modelID = item.modelID
                            }
                        }
                    }

                    // If the file is not there, then create it
                    if (modelID == nil) {
                        let folderCreateRequest: BOXFolderCreateRequest = contentClient.folderCreateRequest(withName: self.rootFolderName, parentFolderID: BOXAPIFolderIDRoot)
                        folderCreateRequest.perform(completion: { (folder: BOXFolder?, error: Error?) in
                            if (folder != nil && error == nil) {
                                let folder = folder!
                                modelID = folder.modelID
                                self.performUpload(contentClient, modelID: modelID!)
                            }
                        })
                    }
                    // File was there - perform the upload
                    else {
                        self.performUpload(contentClient, modelID: modelID!)
                    }
                })
                
                return
            }
        })
    }
    
    private func performUpload(_ contentClient: BOXContentClient, modelID id: String) {
        // Get the captures
        guard let captures = self.captures else {
            log(moduleName: self.cls, "captures empty")
            return;
        }
        
        // Completion handler for file upload
        let uploadCheck = { (file: BOXFile?, error: Error?) in
            if (error == nil && file != nil) {
                // log(moduleName: self.cls, "completed upload to", (folder.name)!)
            }
            else {
                log(moduleName: self.cls, "error while uploading", (file?.name)!)
                log(moduleName: self.cls, error!)
            }
        }
        
        // Iterate through the captures
        for (index, capture) in captures.enumerated() {
            
            // Grab from Core Data
            guard let date = capture.value(forKeyPath: Keys.CoreData.Capture.Date) as? Date else {
                log(moduleName: self.cls, "no date for the capture ... skipping")
                continue;
            }
            
            // Grab all the fields
            let username = capture.value(forKeyPath: Keys.CoreData.Capture.Username) as? String ?? "<invalid_name>"
            let location = capture.value(forKeyPath: Keys.CoreData.Capture.Location) as? String ?? "<invalid_location>"
            let text = capture.value(forKeyPath: Keys.CoreData.Capture.Text) as? String ?? ""
            let rgbData = capture.value(forKeyPath: Keys.CoreData.Capture.RGBFrame) as? Data ?? Data()
            let depthData = capture.value(forKeyPath: Keys.CoreData.Capture.DepthFrame) as? Data ?? Data()
            
            // Create the folder to hold the data
            let format = "yyy-MM-dd_HH:mm:ss"
            let dateString = date.toString(dateFormat: format)
            let folderName = self.folderName + "_" + dateString;
            let folderRequest: BOXFolderCreateRequest = contentClient.folderCreateRequest(withName: folderName, parentFolderID: id)
            
            folderRequest.perform(completion: { (folder: BOXFolder?, error: Error?) in
                if (error == nil) {
                    let folder = folder!
                    log(moduleName: self.cls, "created folder:", folder.name)
                    
                    // Upload metadata as a json file
                    var metadata = JSON()
                    metadata["username"].string = username
                    metadata["location"].string = location // TODO :add more information for location (long/lat)
                    metadata["description"].string = text
                    metadata["timeCaptured"].string = dateString
                                        
                    do {
                        let raw = try metadata.rawData()
                        print("RAW:", raw)
                        contentClient.fileUploadRequestToFolder(withID: folder.modelID, from: raw, fileName: ".metadata.json").perform(progress: nil, completion: uploadCheck)
                    }
                    catch _ {
                        log(moduleName: self.cls, "unable to upload metadata file to:", folder.name)
                    }
                    
                    // Create frames folder
                    // No 3D reconstruction
                    let framesFolderName = "Frames"
                    let framesFolderRequest: BOXFolderCreateRequest = contentClient.folderCreateRequest(withName: framesFolderName, parentFolderID: folder.modelID)
                    
                    framesFolderRequest.perform(completion: { (framesFolder: BOXFolder?, framesError: Error?) in
                        if (framesError == nil) {
                            let framesFolder = framesFolder!
                            
                            // Create folder for each individual frame and its metadata
                            // TODO: Iterate through all the frames
                            let frameFolderName = "Frame" + "1"
                            let frameFolderRequest: BOXFolderCreateRequest = contentClient.folderCreateRequest(withName: frameFolderName, parentFolderID: framesFolder.modelID)
                            
                            frameFolderRequest.perform(completion: { (frameFolder: BOXFolder?, frameError: Error?) in
                                if (frameError == nil) {
                                    let frameFolder = frameFolder!
                                    
                                    log(moduleName: self.cls, "uploading data to folder:", folder.name)
                                    
                                    // Add the rgb photo
                                    contentClient.fileUploadRequestToFolder(withID: frameFolder.modelID, from: rgbData, fileName: "color-image.png").perform(progress: nil, completion: uploadCheck)
                                    
                                    // Add depth photo
                                    contentClient.fileUploadRequestToFolder(withID: frameFolder.modelID, from: depthData, fileName: "depth-image.png").perform(progress: nil, completion: uploadCheck)
                                    
                                    // TODO:: upload frame metadata
                                }
                            })
                        }
                    })
                }
                else {
                    log(moduleName: self.cls, "error creating folder:", folderName)
                    log(moduleName: self.cls, error!)
                }
                
                // If last element has been uploaded, then remove all
                if (index == captures.count - 1) {
                    log(moduleName: self.cls, "Deleting the captures")
                    
                    // Get managed object
                    guard let managedContext = self.managedContext else {
                        return
                    }
                    
                    // Perform delete
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Keys.CoreData.Capture.Key)
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    do {
                        try managedContext.execute(deleteRequest)
                        
                        // Delete the in-memory array and reload table
                        self.captures?.removeAll()
                        self.reloadCheck()
                    } catch let error as NSError {
                        // Handle error
                        log(moduleName: self.cls, "Error while deleting objects")
                        log(moduleName: self.cls, error)
                    }
                    
                    // Remove spinner
                    self.spinner?.removeFromSuperview()
                }
                } as! BOXFolderBlock as! BOXFolderBlock)
        }
    }
    
    @IBAction func modelButton(_ sender: Any) {
        log(moduleName: cls, "going to model view")
        let w: SwiftWrapper = SwiftWrapper()
        let vc = w.getVC()
        self.present(vc as! UIViewController, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
