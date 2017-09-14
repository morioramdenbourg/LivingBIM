//
//  ViewController.swift
//  LivingBIM
//
//  Created by Morio Ramdenbourg on 9/13/17.
//  Copyright © 2017 CAEE. All rights reserved.
//

import UIKit

class ViewController: UIViewController, STSensorControllerDelegate {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var depthView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // For logging
        let error: NSErrorPointer = nil
        STWirelessLog.broadcastLogsToWirelessConsole(atAddress: "192.168.1.2", usingPort: 4999, error: error)
        
        // Set delegate
        STSensorController.shared().delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.appDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    func appDidBecomeActive() {
        print("Became active")
        if STSensorController.shared().isConnected() {
            tryStartStreaming()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if tryInitializeSensor() && STSensorController.shared().isConnected() {
            tryStartStreaming()
        }
        else {
            print(STSensorController.shared().isConnected())
            statusLabel.text = "Disconnected"
        }
    }
    
    func tryInitializeSensor() -> Bool {
        print("Initializing Sensor")
        let result = STSensorController.shared().initializeSensorConnection()
        print(result.rawValue)
        if result == .alreadyInitialized || result == .success {
            return true
        }
        return false
    }
    
    @discardableResult
    func tryStartStreaming() -> Bool {
        if tryInitializeSensor() {
            let options: [AnyHashable: Any] = [
                kSTStreamConfigKey: NSNumber(value: STStreamConfig.depth640x480.rawValue as Int),
                kSTFrameSyncConfigKey: NSNumber(value: STFrameSyncConfig.off.rawValue as Int),
                kSTHoleFilterEnabledKey: true
            ]
            do {
                try STSensorController.shared().startStreaming(options: options as [AnyHashable: Any])
                return true
            }
            catch let error as NSError {
                print(error)
            }
        }
        return false
    }

    func sensorDidConnect() {
        if tryStartStreaming() {
            statusLabel.text = "Streaming"
        }
        else {
            statusLabel.text = "Connected"
        }
    }
    
    func sensorDidDisconnect() {
    }
    
    func sensorDidStopStreaming(_ reason: STSensorControllerDidStopStreamingReason) {
    }
    
    func sensorDidLeaveLowPowerMode() {
    }
    
    func sensorBatteryNeedsCharging() {
    }
    
    func sensorDidOutputDepthFrame(_ depthFrame: STDepthFrame!) {
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

