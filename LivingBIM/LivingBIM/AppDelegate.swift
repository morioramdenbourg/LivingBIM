//
//  AppDelegate.swift
//  LivingBIM
//
//  Created by Morio Ramdenbourg on 9/13/17.
//  Copyright © 2017 CAEE. All rights reserved.
//

import UIKit
import CoreData
import BoxContentSDK
import CoreLocation

fileprivate let cls = "AppDelegate"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var locationManager: CLLocationManager? // Location
    var motionManager: CMMotionManager! // Motion
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        BOXContentClient.setClientID("k6mthafuwzjc5q1xa7izq03qguccu9hn", clientSecret: "Capk6Zfo8z1gbKP6RFxMbyncuGI6r3C1")
        
        // Start location manager
        setLocationManager()
        
        // Start motion manager
        setMotionManager()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "LivingBIM")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func setMotionManager() {
        log(moduleName: cls, "setting up motion manager")
        motionManager = CMMotionManager()
        
        // Magnetometer
        motionManager.startMagnetometerUpdates()
        
        //
    }
    
    func setLocationManager() {
        log(moduleName: cls, "setting up location")
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.requestAlwaysAuthorization()
        locationManager?.startUpdatingLocation()
        locationManager?.startUpdatingHeading()
        let orientation = UIApplication.shared.statusBarOrientation
        var text = ""
        switch orientation {
        case .portrait:
            text = "Portrait"
        case .portraitUpsideDown:
            text="PortraitUpsideDown"
        case .landscapeLeft:
            text="LandscapeLeft"
            locationManager?.headingOrientation = CLDeviceOrientation.landscapeLeft
        case .landscapeRight:
            text="LandscapeRight"
            locationManager?.headingOrientation = CLDeviceOrientation.landscapeRight
        default:
            text="Another"
        }
        log(moduleName: cls, "chose orientation:", text)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let trueAngle = newHeading.trueHeading
        let magAngle = newHeading.magneticHeading
        log(moduleName: cls, "TRUE HEADING:", trueAngle)
        log(moduleName: cls, "MAG HEADING:", magAngle)
    }
    
    // Current location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        let formattedLoc = formatLocation(locValue)
        UserDefaults.standard.set(locValue.latitude, forKey: Keys.UserDefaults.Latitude)
        UserDefaults.standard.set(locValue.longitude, forKey: Keys.UserDefaults.Longitude)
        UserDefaults.standard.set(formattedLoc, forKey: Keys.UserDefaults.Location)
        log(moduleName: cls, "LOC:", formattedLoc)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        log(moduleName: cls, "error:", error)
    }
    
    func getLocation() -> String? {
        return UserDefaults.standard.string(forKey: Keys.UserDefaults.Location)
    }
    
    func getLatitude() -> CLLocationDegrees? {
        return UserDefaults.standard.object(forKey: Keys.UserDefaults.Latitude) as? CLLocationDegrees
    }
    
    func getLongitude() -> CLLocationDegrees? {
        return UserDefaults.standard.object(forKey: Keys.UserDefaults.Longitude) as? CLLocationDegrees
    }
}

