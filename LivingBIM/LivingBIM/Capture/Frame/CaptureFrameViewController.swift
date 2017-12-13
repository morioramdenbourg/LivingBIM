//
//  ViewController.swift
//  LivingBIM
//
//  Created by Morio Ramdenbourg on 9/13/17.
//  Copyright © 2017 CAEE. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData
import CoreLocation

fileprivate let module = "CaptureFrameViewController"

class CaptureFrameViewController: UIViewController, STSensorControllerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // Core data
    private var managedContext: NSManagedObjectContext!
    private var entity: NSEntityDescription!
    private var frameEntity: NSEntityDescription!

    // Camera
    private let position = AVCaptureDevicePosition.back
    private let quality = AVCaptureSessionPreset640x480
    private let sessionQueue = DispatchQueue(label: "session queue")
    private let captureSession = AVCaptureSession()
    private let context = CIContext()
    private var permissionGranted = false
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var cameraView: UIImageView!
    
    private var controller : STSensorController?
    private var captureNext = false
    private var captureLocation: CLLocationCoordinate2D?
    private var toRGBA : STDepthToRgba?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        log(name: module, "viewDidLoad")
        
        // Set up core data
        log(name: module, "setting up Core Data")
        let appDelegate = AppDelegate.delegate
        managedContext = appDelegate.persistentContainer.viewContext
        entity = NSEntityDescription.entity(forEntityName: Constants.CoreData.Keys.Capture, in: managedContext)
        frameEntity = NSEntityDescription.entity(forEntityName: Constants.CoreData.Keys.Frame, in: managedContext)
        
        // Disable navigation bar
        self.navigationController?.navigationBar.isHidden = true
        
        // Set controller
        controller = STSensorController.shared()
    
        // Set delegate
        controller?.delegate = self
        
        // App become active
        NotificationCenter.default.addObserver(self, selector: #selector(CaptureFrameViewController.appDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        // Real feed camera
        checkPermission()
        sessionQueue.async { [unowned self] in
            self.configureSession()
            self.captureSession.startRunning()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Disable navigation bar
        self.navigationController?.navigationBar.isHidden = true
    }
    
    // MARK: AVSession configuration
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            requestPermission()
        default:
            permissionGranted = false
        }
    }
    
    private func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }
    
    private func configureSession() {
        guard permissionGranted else { return }
        captureSession.sessionPreset = quality
        guard let captureDevice = selectCaptureDevice() else { return }
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        guard captureSession.canAddInput(captureDeviceInput) else { return }
        captureSession.addInput(captureDeviceInput)
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer"))
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        guard captureSession.canAddOutput(videoOutput) else { return }
        captureSession.addOutput(videoOutput)
        guard let connection = videoOutput.connection(withMediaType: AVFoundation.AVMediaTypeVideo) else { return }
        guard connection.isVideoOrientationSupported else { return }
        guard connection.isVideoMirroringSupported else { return }
        connection.videoOrientation = .landscapeRight
        connection.isVideoMirrored = position == .front
        
    }
    
    private func selectCaptureDevice() -> AVCaptureDevice? {
        return AVCaptureDevice.devices().filter {
            ($0 as AnyObject).hasMediaType(AVMediaTypeVideo) &&
                ($0 as AnyObject).position == position
            }.first as? AVCaptureDevice
    }
    
    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        controller?.frameSyncNewColorBuffer(sampleBuffer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        log(name: module, "viewWillAppear")
        if tryInitializeSensor() && STSensorController.shared().isConnected() {
            tryStartStreaming()
        }
        else {
            statusLabel.text = "Disconnected"
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func appDidBecomeActive() {
        log(name: module, "appDidBecomeActive")
        if STSensorController.shared().isConnected() {
            tryStartStreaming()
        }
    }
    
    func tryInitializeSensor() -> Bool {
        log(name: module, "Initializing Sensor")
        let result = STSensorController.shared().initializeSensorConnection()
        if result == .alreadyInitialized || result == .success {
            return true
        }
        return false
    }
    
    @discardableResult
    func tryStartStreaming() -> Bool {
        log(name: module, "tryStartStreaming")
        if tryInitializeSensor() {
            let options: [AnyHashable: Any] = [
                kSTStreamConfigKey: NSNumber(value: STStreamConfig.depth320x240.rawValue as Int),
                kSTFrameSyncConfigKey: NSNumber(value: STFrameSyncConfig.depthAndRgb.rawValue as Int),
                kSTHoleFilterEnabledKey: true
            ]
            do {
                try STSensorController.shared().startStreaming(options: options as [AnyHashable: Any])
                statusLabel.text = "Streaming"
                log(name: module, "started streaming")
                let toRGBAOptions : [AnyHashable: Any] = [
                    kSTDepthToRgbaStrategyKey : NSNumber(value: STDepthToRgbaStrategy.redToBlueGradient.rawValue as Int)
                ]
                toRGBA = STDepthToRgba(options: toRGBAOptions)
                return true
            } catch let error as NSError {
                log(name: module, error)
            }
        }
        return false
    }

    func sensorDidConnect() {
        log(name: module, "sensorDidConnect")
        if tryStartStreaming() {
            statusLabel.text = "Streaming"
        }
        else {
            statusLabel.text = "Connected"
        }
    }
    
    func sensorDidDisconnect() {
        log(name: module, "sensorDidDisconnect")
        statusLabel.text = "Disconnected"
    }
    
    func sensorDidStopStreaming(_ reason: STSensorControllerDidStopStreamingReason) {
        log(name: module, "sensorDidStopStreaming")
        statusLabel.text = "Stopped Streaming"
    }
    
    func sensorDidLeaveLowPowerMode() {
        log(name: module, "sensorDidLeaveLowPowerMode")
    }
    
    func sensorBatteryNeedsCharging() {
        log(name: module, "sensorBatteryNeedsCharging")
        statusLabel.text = "Low Battery"
    }
    
    func sensorDidOutputSynchronizedDepthFrame(_ depth: STDepthFrame!, colorFrame color: STColorFrame!) {
        // Half the resolution to allow for easy storage
        let downsizeDepth = depth! // Removed downsample for now
        let downsizeColor = color! // Removed downsample for now
        
        // Display the color frame onto the screen
        DispatchQueue.main.async { [unowned self] in
            if let uiImage = UIImage.imageFromSampleBuffer(downsizeColor.sampleBuffer) {
                self.cameraView.image = uiImage;
            }
        }
            
        // Save the capture
        if (captureNext) {
            
//            if let renderer = toRGBA {
//                let pixels = renderer.convertDepthFrame(toRgba: depth)
//
////                print(pixels)
//                for i in 0..<(depth.height * depth.width) {
//                    print(pixels![Int(i)])
//                }
//            }
            
            stopStreaming()
            captureNext = false
            save(depthFrame: downsizeDepth, colorFrame: downsizeColor)
        }
    }
    
    func stopStreaming() {
        log(name: module, "Stopped streaming")
        STSensorController.shared().stopStreaming()
        statusLabel.text = "Stopped"
    }
    
    private func save(depthFrame depth: STDepthFrame, colorFrame color: STColorFrame) {
        
        log(name: module, "Saving image")
        
        // Ask to save/discard
        let actionController: UIAlertController = UIAlertController(title: "Capture", message: "Save or Discard?", preferredStyle: .alert)

        // Save
        let saveAction: UIAlertAction = UIAlertAction(title: "Save", style: .default) { action -> Void in
            self.describeCapture(depthFrame: depth, colorFrame: color)
        }
        actionController.addAction(saveAction)
        
        // Discard
        let cancelAction: UIAlertAction = UIAlertAction(title: "Discard", style: .cancel) { action -> Void in
            if STSensorController.shared().isConnected() {
                self.tryStartStreaming()
            }
        }
        actionController.addAction(cancelAction)
        
        // Present
        self.present(actionController, animated: true, completion: nil)
    }
    
    private func describeCapture(depthFrame depth: STDepthFrame, colorFrame color: STColorFrame) {
        log(name: module, "displaying describe capture popup")
        
        // Create text field
        var inputTextField: UITextField?
        
        // Create the AlertController
        let actionSheetController: UIAlertController = UIAlertController(title: "Capture", message: "Describe the capture", preferredStyle: .alert)
        
        // Create and an option action
        let saveAction: UIAlertAction = UIAlertAction(title: "Save", style: .default) { action -> Void in
            let description = inputTextField?.text
            let time = Date()
            
            // Create capture
            let capture = NSManagedObject(entity: self.entity, insertInto: self.managedContext)
            ModelWrapper.addCaptureData(managedObject: capture, captureTime: time, zipData: nil, description: description)
            
            // Add frame information
            let frame = NSManagedObject(entity: self.frameEntity, insertInto: self.managedContext)
            ModelWrapper.addFrameData(managedObject: frame, captureTime: time, depthFrame: depth, colorFrame: color, cameraGLProjection: nil, cameraViewPoint: nil)

            // Add frame to capture
            let set = NSMutableOrderedSet()
            set.add(frame)
            capture.setValue(set.copy() as? NSOrderedSet, forKey: Constants.CoreData.Keys.CaptureToFrame)
    
            // Save to core data
            do {
                try self.managedContext.save()
            } catch let error as NSError {
                log(name: module, "ERROR:", "Could not save to Core Data.")
                log(name: module, "ERROR:", error)
            }
    
            log(name: module, "Saved image")
    
            self.navigationController?.popViewController(animated: true)
        }
        actionSheetController.addAction(saveAction)
        
        // Add a text field
        actionSheetController.addTextField { textField -> Void in
            inputTextField = textField
            inputTextField?.placeholder = "Description"
        }
        
        // Present alert
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    @IBAction func captureButton(_ sender: Any) {
        log(name: module, "Capturing image...");
        captureNext = true
    }
}

