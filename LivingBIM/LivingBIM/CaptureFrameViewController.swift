//
//  ViewController.swift
//  LivingBIM
//
//  Created by Morio Ramdenbourg on 9/13/17.
//  Copyright © 2017 CAEE. All rights reserved.
//

import UIKit

let cls = "SensorViewController"

class CaptureFrameViewController: UIViewController, STSensorControllerDelegate {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var depthView: UIImageView!
    
    var toRGBA : STDepthToRgba?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(cls, "viewDidLoad")
        
        // Set delegate
        STSensorController.shared().delegate = self
                
        NotificationCenter.default.addObserver(self, selector: #selector(CaptureFrameViewController.appDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    func appDidBecomeActive() {
        print(cls, "appDidBecomeActive")
        if STSensorController.shared().isConnected() {
            tryStartStreaming()
        }
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
                kSTFrameSyncConfigKey: NSNumber(value: STFrameSyncConfig.off.rawValue as Int),
                kSTHoleFilterEnabledKey: true
            ]
            do {
                try STSensorController.shared().startStreaming(options: options as [AnyHashable: Any])
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
    }
    
    func sensorDidStopStreaming(_ reason: STSensorControllerDidStopStreamingReason) {
        print(cls, "sensorDidStopStreaming")
    }
    
    func sensorDidLeaveLowPowerMode() {
        print(cls, "sensorDidLeaveLowPowerMode")
    }
    
    func sensorBatteryNeedsCharging() {
        print(cls, "sensorBatteryNeedsCharging")
    }
    
    func sensorDidOutputDepthFrame(_ depthFrame: STDepthFrame!) {
        print(cls, "sensorDidOutputDepthFrame")
        if let renderer = toRGBA {
            statusLabel.text = "Showing Depth \(depthFrame.width)x\(depthFrame.height)"
            let pixels = renderer.convertDepthFrame(toRgba: depthFrame)
            depthView.image = imageFromPixels(pixels!, width: Int(renderer.width), height: Int(renderer.height))
        }
    }
    
    func imageFromPixels(_ pixels : UnsafeMutablePointer<UInt8>, width: Int, height: Int) -> UIImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue))
        
        //Source of data for bitmap
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

