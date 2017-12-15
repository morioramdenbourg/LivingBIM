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

fileprivate let module = "HomeViewController"

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // Core Data
    private var appDelegate: AppDelegate?
    private var managedContext: NSManagedObjectContext!
    private var entity: NSEntityDescription?
    
    // Other variables
    private var captures: [NSManagedObject]? // Store captures
    private var screenSize: CGRect? // Screen size
    private var spinner: SpinnerView? // Spinner
    private var count = [Int]()
    
    // Constants
    private let cellHeight: CGFloat = 200
    private let folderName: String = "scan"
    private let rootFolderName: String = "scans"

    // Outlets
    @IBOutlet weak var buttonOutlet: UIButton!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var buildingLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
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
        
        log(name: module, "viewDidLoad")
        
        // Remove the lines on an empty table
        self.tableView.tableFooterView = UIView(frame: .zero)
        
        // Set table view delegates
        tableView.delegate = self
        tableView.dataSource = self
        
        // Core Data
        log(name: module, "setting up Core Data")
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        guard let appDelegate = self.appDelegate else {
            return
        }
        
        managedContext = appDelegate.persistentContainer.viewContext
        guard let managedContext = self.managedContext else {
            return
        }
        
        entity = NSEntityDescription.entity(forEntityName: Constants.CoreData.Keys.Capture, in: managedContext)
        log(name: module, "finished setting up Core Data")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        log(name: module, "viewWillAppear")
        
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
            self.buildingLabel.text = lbl
        }
        else {
            askBuildingInfo(viewController: self) { (abbr, name, room) in
                let lbl = name + " (" + abbr + ") " + " - " + room
                self.buildingLabel.text = lbl
            }
        }
        
        // Display location
        locationLabel.text = appDelegate?.getCoordinate()?.pretty()
        
        // Load the table
        guard let managedContext = self.managedContext else {
            return
        }
        
        // Fetching from core data
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Constants.CoreData.Keys.Capture)
        fetchRequest.returnsObjectsAsFaults = false // TODO: remove for debug
        do {
            captures = try managedContext.fetch(fetchRequest)
            reloadCheck()
        } catch let error as NSError {
            log(name: module, "ERROR:", "Could not fetch from Core Data")
            log(name: module, error)
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
        let cell: HomeTableViewCell = self.tableView.dequeueReusableCell(withIdentifier: Constants.CellIdentifier) as! HomeTableViewCell
        
        guard let capture = captures?[indexPath.row] else {
            return cell
        }
        
        // Grab data
        let username = capture.value(forKeyPath: Constants.CoreData.Capture.Username) as? String
        let timeCaptured = capture.value(forKeyPath: Constants.CoreData.Capture.CaptureTime) as? Date
        
        // Put data and first frame on the cell
        cell.usernameLabel.text = username
        cell.dateLabel.text = timeCaptured?.toString(dateFormat: "yyy-MM-dd HH:mm:ss")
        
        // Hack - set to nil for async operations and add tag
        cell.imgView.image = nil
        cell.tag = indexPath.row
    
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        log(name: module, "tapped cell at:", indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            // Delete from database
            if let capture = captures?.remove(at: indexPath.row) {
                // Display the spinner
                self.view.addSubview(spinner!)
                managedContext?.delete(capture)
                do {
                    try managedContext?.save()
                } catch let error as NSError {
                    print("failed to delete row")
                    print(error)
                }
                tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
                spinner?.removeFromSuperview()
                if (self.captures?.count == 0) {
                    buttonOutlet.isEnabled = false
                }
                else {
                    buttonOutlet.isEnabled = true
                }
            }
        }
    }
    
    // Upload to Box
    @IBAction func uploadButton(_ sender: Any) {
        log(name: module, "uploading to box")
        
        // Disable the button
        buttonOutlet.isEnabled = false
        
        // Display the spinner
        self.view.addSubview(spinner!)
        
        guard let contentClient = BOXContentClient.default() else {
            log(name: module, "error while uploading")
            return
        }
                
        // Authenticate box
        contentClient.authenticate(completionBlock: { (user: BOXUser?, error: Error?) -> Void in
            if (error == nil) {
                log(name: module, "login successful")
                log(name: module, "logged in as:", (user?.login!)! as String)
                
                // Add all to the "rootFolderName" folder, create if it doesn't exist
                let folderItemsRequest: BOXFolderItemsRequest = contentClient.folderItemsRequest(withID: BOXAPIFolderIDRoot)
                folderItemsRequest.perform(completion: { (items: Array?, error: Error?) in
                    var modelID: String? = nil
                    
                    // Find the folder
                    if (items != nil && error == nil) {
                        if let items = items as? [BOXFolder] {
                            for item in items {
                                if (item.name == self.rootFolderName) {
                                    modelID = item.modelID
                                }
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
            else {
                // Remove spinner
                self.spinner?.removeFromSuperview()
                
                // Enable back the button
                self.buttonOutlet.isEnabled = true
            }
        })
    }
    
    private func performUpload(_ contentClient: BOXContentClient, modelID id: String) {
        // Get the captures
        guard var captures = self.captures else {
            log(name: module, "captures empty")
            return;
        }
        
        // Completion handler for file upload
        let uploadCheck = { (file: BOXFile?, error: Error?) in
            if (error == nil && file != nil) {
                 log(name: module, "completed upload to", (file?.name)!)
            }
            else {
                log(name: module, "error while uploading")
                log(name: module, error as Any)
            }
        }
        
        print("CAPTURES:", captures)
        
        count = [Int]()
        
        // Iterate through the captures
        for (captureIndex, capture) in captures.enumerated() {
            
            // Grab from core data
            let username = capture.value(forKey: Constants.CoreData.Capture.Username) as? String ?? "<invalid_name>"
            let description = capture.value(forKey: Constants.CoreData.Capture.Description) as? String ?? ""
            let captureTime = capture.value(forKey: Constants.CoreData.Capture.CaptureTime) as? Date ?? Date()
            let meshZip = capture.value(forKey: Constants.CoreData.Capture.Mesh) as? Data
            let fs = capture.value(forKey: Constants.CoreData.Keys.CaptureToFrame) as? NSOrderedSet
            
            // Create the folder to hold the data
            let format = "yyy-MM-dd_HH:mm:ss"
            let dateString = captureTime.toString(dateFormat: format)
            let folderName = self.folderName + "_" + dateString;
            let folderRequest: BOXFolderCreateRequest = contentClient.folderCreateRequest(withName: folderName, parentFolderID: id)
            
            folderRequest.perform(completion: { (folder: BOXFolder?, error: Error?) in
                if (error == nil) {
                    
                    let folder = folder!
                    log(name: module, "created folder:", folder.name)
                    
                    // Upload zip file for reconstruction
                    if let meshZip = meshZip {
                        contentClient.fileUploadRequestToFolder(withID: folder.modelID, from: meshZip, fileName: "mesh.zip").perform(progress: nil, completion: uploadCheck)
                    }
                    
                    // Upload metadata as a json file
                    var metadata = JSON()
                    metadata["username"].string = username
                    metadata["description"].string = description
                    metadata["captureTime"].string = dateString
                                        
                    do {
                        let raw = try metadata.rawData()
                        contentClient.fileUploadRequestToFolder(withID: folder.modelID, from: raw, fileName: ".metadata.json").perform(progress: nil, completion: uploadCheck)
                    }
                    catch _ {
                        log(name: module, "unable to upload metadata file to:", folder.name)
                    }
                    
                    // Create frames folder
                    // No 3D reconstruction
                    let framesFolderName = "Frames"
                    let framesFolderRequest: BOXFolderCreateRequest = contentClient.folderCreateRequest(withName: framesFolderName, parentFolderID: folder.modelID)
                    
                    framesFolderRequest.perform(completion: { (framesFolder: BOXFolder?, framesError: Error?) in
                        if (framesError == nil) {
                            let framesFolder = framesFolder!
                            
                            // Create folder for each individual frame and its metadata
                            self.count.append(0)
                            let framesArr = fs?.array as! [NSManagedObject]
                            
                            let sizeCheck = { (file: BOXFile?, error: Error?) in
                                self.count[captureIndex] += 1
                                print("COUNT:", self.count[captureIndex], "FRAMES:", framesArr.count, "CAPTURE#:", captureIndex)
                                let realCount = framesArr.count * 3
                                self.statusLabel.text = String(format: "%.2f", (Double(self.count[captureIndex]) / Double(realCount)) * 100.0) + "% for capture: " + String(captureIndex)
                                if self.count[captureIndex] == realCount {
                                    self.statusLabel.text = "Done with capture: " + String(captureIndex)
                                    self.managedContext.delete(capture)
                                    do {
                                        try self.managedContext?.save()
                                    } catch let error as NSError {
                                        print("failed to delete row")
                                        print(error)
                                    }
                                    if let i = captures.index(of: capture) {
                                        captures.remove(at: i)
                                    }
                                    print(captures)
                                    self.reloadCheck()
                                    if (captures.count == 0) {
                                        self.spinner?.removeFromSuperview()
                                        self.statusLabel.text = "Done"
                                    }
                                }
                            }
                            
                            for (index, frame) in framesArr.enumerated() {
                                let frameFolderName = "Frame" + String(index)
                                let frameFolderRequest: BOXFolderCreateRequest = contentClient.folderCreateRequest(withName: frameFolderName, parentFolderID: framesFolder.modelID)
                                
                                frameFolderRequest.perform(completion: { (frameFolder: BOXFolder?, frameError: Error?) in
                                    if (frameError == nil) {
                                        let frameFolder = frameFolder!

                                        // Upload metadata as a json file
                                        var frameMetadata = JSON()
                                        
                                        // Add projection matrix
                                        if let projection = frame.value(forKey: Constants.CoreData.Capture.Frame.CameraGLProjection) as? Data {
                                            let unarchiveObject = NSKeyedUnarchiver.unarchiveObject(with: projection)
                                            if let projArray = unarchiveObject as? [Float] {
                                                frameMetadata["cameraGLProjection"].arrayObject = projArray
                                            }
                                        }
                                        
                                        // Add view point
                                        if let viewPoint = frame.value(forKey: Constants.CoreData.Capture.Frame.CameraViewPoint) as? Data {
                                            let unarchiveObject = NSKeyedUnarchiver.unarchiveObject(with: viewPoint)
                                            if let viewPointArray = unarchiveObject as? [Float] {
                                                frameMetadata["cameraViewPoint"].arrayObject = viewPointArray
                                            }
                                        }
                                        
                                        // Add building
                                        if let buildingAbbr = frame.value(forKey: Constants.CoreData.Capture.Frame.Building.Abbr) as? String, let buildingName = frame.value(forKey: Constants.CoreData.Capture.Frame.Building.Name) as? String, let roomNumber = frame.value(forKey: Constants.CoreData.Capture.Frame.Building.RoomNumber) as? String {
                                            var building = JSON()
                                            building["abbreviation"].string = buildingAbbr
                                            building["name"].string = buildingName
                                            building["roomNumber"].string = roomNumber
                                            frameMetadata["building"] = building
                                        }
                                        
                                        // Time
                                        if let time = frame.value(forKeyPath: Constants.CoreData.Capture.Frame.Time) as? Date {
                                            frameMetadata["time"].string = time.toString(dateFormat: format)
                                        }
                                        
                                        // Heading
                                        if let heading = frame.value(forKeyPath: Constants.CoreData.Capture.Frame.Heading) as? Double {
                                            frameMetadata["heading"].double = heading
                                        }
                                        
                                        // Coordinate
                                        if let latitude = frame.value(forKeyPath: Constants.CoreData.Capture.Frame.Coordinate.Latitude) as? Double,
                                            let longitude = frame.value(forKeyPath: Constants.CoreData.Capture.Frame.Coordinate.Longitude) as? Double {
                                            var coordinate = JSON()
                                            coordinate["latitude"].double = latitude
                                            coordinate["longitude"].double = longitude
                                            frameMetadata["coordinate"] = coordinate
                                        }
                                        
                                        // Acceleration
                                        if let accelerationX = frame.value(forKeyPath: Constants.CoreData.Capture.Frame.Acceleration.X) as? Double,
                                            let accelerationY = frame.value(forKeyPath: Constants.CoreData.Capture.Frame.Acceleration.Y) as? Double,
                                            let accelerationZ = frame.value(forKeyPath: Constants.CoreData.Capture.Frame.Acceleration.Z) as? Double {
                                            var acceleration = JSON()
                                            acceleration["X"].double = accelerationX
                                            acceleration["Y"].double = accelerationY
                                            acceleration["Z"].double = accelerationZ
                                            frameMetadata["acceleration"] = acceleration
                                        }
                                        
                                        // Gyroscope
                                        if let gyroscopeX = frame.value(forKeyPath: Constants.CoreData.Capture.Frame.Gyroscope.X) as? Double,
                                            let gyroscopeY = frame.value(forKeyPath: Constants.CoreData.Capture.Frame.Gyroscope.Y) as? Double,
                                            let gyroscopeZ = frame.value(forKeyPath: Constants.CoreData.Capture.Frame.Gyroscope.Z) as? Double {
                                            var gyroscope = JSON()
                                            gyroscope["X"].double = gyroscopeX
                                            gyroscope["Y"].double = gyroscopeY
                                            gyroscope["Z"].double = gyroscopeZ
                                            frameMetadata["gyroscope"] = gyroscope
                                        }

                                        // Magnetometer
                                        if let magnetometerX = frame.value(forKeyPath: Constants.CoreData.Capture.Frame.Magnetometer.X) as? Double,
                                            let magnetometerY = frame.value(forKeyPath: Constants.CoreData.Capture.Frame.Magnetometer.Y) as? Double,
                                            let magnetometerZ = frame.value(forKeyPath: Constants.CoreData.Capture.Frame.Magnetometer.Z) as? Double {
                                            var magnetometer = JSON()
                                            magnetometer["X"].double = magnetometerX
                                            magnetometer["Y"].double = magnetometerY
                                            magnetometer["Z"].double = magnetometerZ
                                            frameMetadata["magnetometer"] = magnetometer
                                        }
                                        
                                        // Add depth as an array
                                        if let depth = frame.value(forKeyPath: Constants.CoreData.Capture.Frame.Depth) as? Data {
                                            var depthJSON = JSON()
                                            var d: [Float] = depth.toArray(type: Float.self)
                                            d = d.map {$0.isNaN ? 0 : $0}
                                            depthJSON["depth"].arrayObject = d
                                            do {
                                                let rawDepth = try depthJSON.rawData()
                                                contentClient.fileUploadRequestToFolder(withID: frameFolder.modelID, from: rawDepth, fileName: "depth.json").perform(progress: nil, completion: sizeCheck)
                                            }
                                            catch let error as NSError {
                                                log(name: module, "unable to upload metadata file to:", folder.name)
                                                log(name: module, error)
                                            }
                                        }
                                        
                                        // Add the rgb photo
                                        if let rgb = frame.value(forKeyPath: Constants.CoreData.Capture.Frame.Color) as? Data {
                                            print("rgb data", rgb)
                                            contentClient.fileUploadRequestToFolder(withID: frameFolder.modelID, from: rgb, fileName: "color.png").perform(progress: nil, completion: sizeCheck)
                                        }
                                        
                                        // Upload json file
                                        do {
                                            let raw = try frameMetadata.rawData()
                                            contentClient.fileUploadRequestToFolder(withID: frameFolder.modelID, from: raw, fileName: ".metadata.json").perform(progress: nil, completion: sizeCheck)
                                        }
                                        catch let error as NSError {
                                            log(name: module, "unable to upload metadata file to:", folder.name)
                                            log(name: module, error)
                                        }
                                        
//                                        // Delete the frame
                                        print("deleting frame:", frameFolderName)
                                        self.managedContext.delete(frame)
                                        do {
                                            try self.managedContext?.save()
                                        } catch let error as NSError {
                                            print("failed to delete row")
                                            print(error)
                                        }
                                    }
                                })
                            }
                        }
                    })
                }
                else {
                    log(name: module, "error creating folder:", folderName)
                    log(name: module, error!)
                }
            })
        }
    }
    
    @IBAction func modelButton(_ sender: Any) {
        log(name: module, "going to model view")
        var w: ModelWrapper? = ModelWrapper()
        var vc = w?.getVC()
        self.present(vc as! UIViewController, animated: true, completion: {
            vc = nil
            w = nil
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "collectionSegue" {
            if let destination = segue.destination as? CaptureCollectionViewController, let index = tableView.indexPathForSelectedRow?.row {
                destination.capture = captures?[index]
            }
        }
    }
}

extension Data {
    
    init<T>(fromArray values: [T]) {
        var values = values
        self.init(buffer: UnsafeBufferPointer(start: &values, count: values.count))
    }
    
    func toArray<T>(type: T.Type) -> [T] {
        return self.withUnsafeBytes {
            [T](UnsafeBufferPointer(start: $0, count: self.count/MemoryLayout<T>.stride))
        }
    }
}
