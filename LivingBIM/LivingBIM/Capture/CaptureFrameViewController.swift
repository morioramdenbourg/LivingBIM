//
//  ViewController.swift
//  LivingBIM
//
//  Created by Morio Ramdenbourg on 9/13/17.
//  Copyright © 2017 CAEE. All rights reserved.
//

import UIKit
import AVFoundation

let cls = "SensorViewController"

class CaptureFrameViewController: UIViewController, STSensorControllerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private let position = AVCaptureDevicePosition.back
    private let quality = AVCaptureSessionPreset640x480
    
    private var permissionGranted = false
    private let sessionQueue = DispatchQueue(label: "session queue")
    private let captureSession = AVCaptureSession()
    private let context = CIContext()
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var depthView: UIImageView!
    @IBOutlet weak var cameraView: UIImageView!
    
    var controller : STSensorController?
    var toRGBA : STDepthToRgba?
    var captureNext = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(cls, "viewDidLoad")
        
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
//        guard let uiImage = imageFromSampleBuffer(sampleBuffer) else { return }
//        DispatchQueue.main.async { [unowned self] in
//            self.cameraView.image = uiImage;
//        }
        controller?.frameSyncNewColorBuffer(sampleBuffer)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        print(cls, "viewWillAppear")
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
        print(cls, "appDidBecomeActive")
        if STSensorController.shared().isConnected() {
            tryStartStreaming()
        }
    }
    
    func tryInitializeSensor() -> Bool {
        print(cls, "Initializing Sensor")
        let result = STSensorController.shared().initializeSensorConnection()
        if result == .alreadyInitialized || result == .success {
            return true
        }
        return false
    }
    
    @discardableResult
    func tryStartStreaming() -> Bool {
        print(cls, "tryStartStreaming")
        if tryInitializeSensor() {
            let options: [AnyHashable: Any] = [
                kSTStreamConfigKey: NSNumber(value: STStreamConfig.depth640x480.rawValue as Int),
                kSTFrameSyncConfigKey: NSNumber(value: STFrameSyncConfig.depthAndRgb.rawValue as Int),
                kSTHoleFilterEnabledKey: true
            ]
            do {
                try STSensorController.shared().startStreaming(options: options as [AnyHashable: Any])
                statusLabel.text = "Streaming"
                print(cls, "started streaming")
                let toRGBAOptions : [AnyHashable: Any] = [
                    kSTDepthToRgbaStrategyKey : NSNumber(value: STDepthToRgbaStrategy.redToBlueGradient.rawValue as Int)
                ]
                toRGBA = STDepthToRgba(options: toRGBAOptions)
                return true
            } catch let error as NSError {
                print(error)
            }
        }
        return false
    }

    func sensorDidConnect() {
        print(cls, "sensorDidConnect")
        if tryStartStreaming() {
            statusLabel.text = "Streaming"
        }
        else {
            statusLabel.text = "Connected"
        }
    }
    
    func sensorDidDisconnect() {
        print(cls, "sensorDidDisconnect")
        statusLabel.text = "Disconnected"
    }
    
    func sensorDidStopStreaming(_ reason: STSensorControllerDidStopStreamingReason) {
        print(cls, "sensorDidStopStreaming")
        statusLabel.text = "Stopped Streaming"
    }
    
    func sensorDidLeaveLowPowerMode() {
        print(cls, "sensorDidLeaveLowPowerMode")
    }
    
    func sensorBatteryNeedsCharging() {
        print(cls, "sensorBatteryNeedsCharging")
        statusLabel.text = "Low Battery"
    }
    
//    func sensorDidOutputDepthFrame(_ depthFrame: STDepthFrame!) {
//        print(cls, "sensorDidOutputDepthFrame")
//        if let renderer = toRGBA {
//            let pixels = renderer.convertDepthFrame(toRgba: depthFrame)
//            depthView.image = imageFromPixels(pixels!, width: Int(renderer.width), height: Int(renderer.height))
//        }
//    }
    
    func sensorDidOutputSynchronizedDepthFrame(_ depthFrame: STDepthFrame!, colorFrame: STColorFrame!) {
//        print(cls, "sensorDidOutputSynchronizedDepthFrame")
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
                save(depthImage: depthImage, colorImage: uiImage)
                stopStreaming()
                captureNext = false
            }
        }
    }
    
    func save(depthImage dImage: UIImage, colorImage cImage: UIImage) {
        let data = UIImagePNGRepresentation(cImage)
        print("DATA", data)
    }
    
    func stopStreaming() {
        print(cls, "Stopped streaming")
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
    
    @IBAction func captureButton(_ sender: Any) {
        print("Capturing image");
        captureNext = true
    }
}

