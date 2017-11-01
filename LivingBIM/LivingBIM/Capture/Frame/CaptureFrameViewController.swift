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

class CaptureFrameViewController: UIViewController, STSensorControllerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // Core data
    private var appDelegate: AppDelegate?
    private var managedContext: NSManagedObjectContext?
    private var entity: NSEntityDescription?
    
    // User Defaults
    private var defaults: UserDefaults?
    
    // Class name
    private let cls = String(describing: CaptureFrameViewController.self)
    
    // Camera
    private let position = AVCaptureDevicePosition.back
    private let quality = AVCaptureSessionPreset640x480
    private let sessionQueue = DispatchQueue(label: "session queue")
    private let captureSession = AVCaptureSession()
    private let context = CIContext()
    private var permissionGranted = false
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var depthView: UIImageView!
    @IBOutlet weak var cameraView: UIImageView!
    
    private var controller : STSensorController?
    private var toRGBA : STDepthToRgba?
    private var captureNext = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        log(moduleName: cls, "viewDidLoad")
        
        // Set up core data
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
        
        // Set up user defaults
        log(moduleName: cls, "setting up User Defaults")
        defaults = UserDefaults.standard
        log(moduleName: cls, "finished setting up User Defaults")
        
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
        log(moduleName: cls, "viewWillAppear")
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
        log(moduleName: cls, "appDidBecomeActive")
        if STSensorController.shared().isConnected() {
            tryStartStreaming()
        }
    }
    
    func tryInitializeSensor() -> Bool {
        log(moduleName: cls, "Initializing Sensor")
        let result = STSensorController.shared().initializeSensorConnection()
        if result == .alreadyInitialized || result == .success {
            return true
        }
        return false
    }
    
    @discardableResult
    func tryStartStreaming() -> Bool {
        log(moduleName: cls, "tryStartStreaming")
        if tryInitializeSensor() {
            let options: [AnyHashable: Any] = [
                kSTStreamConfigKey: NSNumber(value: STStreamConfig.depth640x480.rawValue as Int),
                kSTFrameSyncConfigKey: NSNumber(value: STFrameSyncConfig.depthAndRgb.rawValue as Int),
                kSTHoleFilterEnabledKey: true
            ]
            do {
                try STSensorController.shared().startStreaming(options: options as [AnyHashable: Any])
                statusLabel.text = "Streaming"
                log(moduleName: cls, "started streaming")
                let toRGBAOptions : [AnyHashable: Any] = [
                    kSTDepthToRgbaStrategyKey : NSNumber(value: STDepthToRgbaStrategy.redToBlueGradient.rawValue as Int)
                ]
                toRGBA = STDepthToRgba(options: toRGBAOptions)
                return true
            } catch let error as NSError {
                log(moduleName: cls, error)
            }
        }
        return false
    }

    func sensorDidConnect() {
        log(moduleName: cls, "sensorDidConnect")
        if tryStartStreaming() {
            statusLabel.text = "Streaming"
        }
        else {
            statusLabel.text = "Connected"
        }
    }
    
    func sensorDidDisconnect() {
        log(moduleName: cls, "sensorDidDisconnect")
        statusLabel.text = "Disconnected"
    }
    
    func sensorDidStopStreaming(_ reason: STSensorControllerDidStopStreamingReason) {
        log(moduleName: cls, "sensorDidStopStreaming")
        statusLabel.text = "Stopped Streaming"
    }
    
    func sensorDidLeaveLowPowerMode() {
        log(moduleName: cls, "sensorDidLeaveLowPowerMode")
    }
    
    func sensorBatteryNeedsCharging() {
        log(moduleName: cls, "sensorBatteryNeedsCharging")
        statusLabel.text = "Low Battery"
    }
    
//    func sensorDidOutputDepthFrame(_ depthFrame: STDepthFrame!) {
//        log(moduleName: cls, "sensorDidOutputDepthFrame")
//        if let renderer = toRGBA {
//            let pixels = renderer.convertDepthFrame(toRgba: depthFrame)
//            depthView.image = imageFromPixels(pixels!, width: Int(renderer.width), height: Int(renderer.height))
//        }
//    }
    
    func sensorDidOutputSynchronizedDepthFrame(_ depthFrame: STDepthFrame!, colorFrame: STColorFrame!) {
//        log(moduleName: cls, "sensorDidOutputSynchronizedDepthFrame")
//        if let image = imageFromSampleBuffer(colorFrame.sampleBuffer) {
//            cameraView.image = image
//        }
        
        if let renderer = toRGBA, let uiImage = imageFromSampleBuffer(colorFrame.sampleBuffer) {
            // Render depth view
            let pixels = renderer.convertDepthFrame(toRgba: depthFrame)
            let depthImage = imageFromPixels(pixels!, width: Int(renderer.width), height: Int(renderer.height))!
            
            DispatchQueue.main.async { [unowned self] in
                self.cameraView.image = uiImage;
                self.depthView.image = depthImage
            }
            
            if (captureNext) {
                stopStreaming()
                save(depthImage: depthImage, colorImage: uiImage)
                captureNext = false
            }
        }
    }
    
    func stopStreaming() {
        log(moduleName: cls, "Stopped streaming")
        STSensorController.shared().stopStreaming()
        statusLabel.text = "Stopped"
    }
    
    func imageFromSampleBuffer(_ sampleBuffer : CMSampleBuffer) -> UIImage? {
        if let cvPixels = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let coreImage = CIImage(cvPixelBuffer: cvPixels)
            let context = CIContext()
            let rect = CGRect(x: 0, y: 0, width: CGFloat(CVPixelBufferGetWidth(cvPixels)), height: CGFloat(CVPixelBufferGetHeight(cvPixels)))
            let cgImage = context.createCGImage(coreImage, from: rect)
            let image = UIImage(cgImage: cgImage!)
            return image
        }
        return nil
    }
    
    func imageFromPixels(_ pixels : UnsafeMutablePointer<UInt8>, width: Int, height: Int) -> UIImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue))
        
        // Source of data for bitmap
        let provider = CGDataProvider(data: Data(bytes: UnsafePointer<UInt8>(pixels), count: width*height*4) as CFData)
        
        let image = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8 * 4,
            bytesPerRow: width * 4,
            space: colorSpace,       //Quartz color space
            bitmapInfo: bitmapInfo,
            provider: provider!,
            decode: nil,
            shouldInterpolate: false,
            intent: CGColorRenderingIntent.defaultIntent);
        
        return UIImage(cgImage: image!)
    }
    
    private func save(depthImage dImage: UIImage, colorImage cImage: UIImage) {
        log(moduleName: cls, "Saving image")
        
        // Alert to ask save/discard capture
        let actionSheetController: UIAlertController = UIAlertController(title: "Capture", message: "Save or Discard?", preferredStyle: .alert)

        // Create and add Save action
        let saveAction: UIAlertAction = UIAlertAction(title: "Save", style: .default) { action -> Void in
            self.describeCapture(depthImage: dImage, colorImage: cImage)
        }
        actionSheetController.addAction(saveAction)
        
        // Create and add the Discard action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Discard", style: .cancel) { action -> Void in
            // Restart the camera
        }
        actionSheetController.addAction(cancelAction)
        
        // Present alert
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    private func describeCapture(depthImage dImage: UIImage, colorImage cImage: UIImage) {
        log(moduleName: cls, "displaying describe capture popup")
        
        // Create text field
        var inputTextField: UITextField?
        
        // Create the AlertController
        let actionSheetController: UIAlertController = UIAlertController(title: "Capture", message: "Describe the capture", preferredStyle: .alert)
        
        // Create and an option action
        let saveAction: UIAlertAction = UIAlertAction(title: "Save", style: .default) { action -> Void in
            // Get text
            let text: String = inputTextField?.text ?? ""
            
            // Save to core Data
            guard let entity = self.entity, let managedContext = self.managedContext else {
                return
            }
            
            let capture = NSManagedObject(entity: entity, insertInto: managedContext)
            let username = self.defaults?.string(forKey: Keys.UserDefaults.Username)
            let timestamp = Date()
            let location = self.defaults?.string(forKey: Keys.UserDefaults.Location)
            
            let rgbData = UIImagePNGRepresentation(cImage)
            let depthData = UIImagePNGRepresentation(dImage)
            
            capture.setValue(username, forKeyPath: Keys.CoreData.Capture.Username)
            capture.setValue(timestamp, forKeyPath: Keys.CoreData.Capture.Date)
            capture.setValue(text, forKeyPath: Keys.CoreData.Capture.Text)
            capture.setValue(location, forKeyPath: Keys.CoreData.Capture.Location)
            capture.setValue(rgbData, forKeyPath: Keys.CoreData.Capture.RGBFrame)
            capture.setValue(depthData, forKeyPath: Keys.CoreData.Capture.DepthFrame)
    
            do {
                try managedContext.save()
            } catch let error as NSError {
                log(moduleName: self.cls, "ERROR:", "Could not save to Core Data.")
                log(moduleName: self.cls, "ERROR:", error)
            }
    
            log(moduleName: self.cls, "Saved image")
    
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
        log(moduleName: cls, "Capturing image...");
        captureNext = true
        
        // test save
        let testrgb = UIImage(named: "testRGB")
        let testDepth = UIImage(named: "testDepth")
        
        save(depthImage: testDepth!, colorImage: testrgb!)
    }
}

