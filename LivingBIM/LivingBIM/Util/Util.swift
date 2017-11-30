//
//  Util.swift
//  LivingBIM
//
//  Created by Morio Ramdenbourg on 10/3/17.
//  Copyright © 2017 CAEE. All rights reserved.
//

import Foundation
import CoreLocation
import CoreData

extension Date {
    // Convert date to string
    func toString(dateFormat format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}

extension CLLocationCoordinate2D {
    // Pretty print coordinate
    func pretty() -> String {
        return String(format: "%.4f", self.latitude) + ", " + String(format: "%.4f", self.longitude)
    }
}

extension CLLocationDegrees {
    func stringify() -> String {
        return String(format: "%.4f", self)
    }
    func doubleify() -> Double {
        return Double(self)
    }
}

// Pretty Log to the console for a module
func log(name n: String, _ items: Any...) {
    print("[" + n + "]", terminator: " ")
    for item in items {
        print(item, terminator: " ")
    }
    print()
}

extension ModelWrapper {
    static func addSensorData(managedObject: NSManagedObject) {
        let delegate = AppDelegate.delegate
        
        // Grab sensor data and add to core data
        let heading = delegate.getHeading() // Heading
        managedObject.setValue(Double(heading!), forKey: Constants.CoreData.Capture.Frame.Heading) // Heading
        
        let coordinate = delegate.getCoordinate() // Coordinate
        managedObject.setValue(coordinate?.latitude.doubleify(), forKey: Constants.CoreData.Capture.Frame.Coordinate.Latitude) // Coordinate latitude
        managedObject.setValue(coordinate?.longitude.doubleify(), forKey: Constants.CoreData.Capture.Frame.Coordinate.Longitude) // Coordinate longitude
        
        let acceleration = delegate.getAcceleration() // Acceleration
        managedObject.setValue(acceleration?.x, forKey: Constants.CoreData.Capture.Frame.Acceleration.X)
        managedObject.setValue(acceleration?.y, forKey: Constants.CoreData.Capture.Frame.Acceleration.Y)
        managedObject.setValue(acceleration?.z, forKey: Constants.CoreData.Capture.Frame.Acceleration.Z)
        
        let gyroscope = delegate.getGyroscope() // Gyroscope
        managedObject.setValue(gyroscope?.x, forKey: Constants.CoreData.Capture.Frame.Gyroscope.X)
        managedObject.setValue(gyroscope?.y, forKey: Constants.CoreData.Capture.Frame.Gyroscope.Y)
        managedObject.setValue(gyroscope?.z, forKey: Constants.CoreData.Capture.Frame.Gyroscope.Z)
        
        let magnetometer = delegate.getMagnetometer() // Magnetometer
        managedObject.setValue(magnetometer?.x, forKey: Constants.CoreData.Capture.Frame.Magnetometer.X)
        managedObject.setValue(magnetometer?.y, forKey: Constants.CoreData.Capture.Frame.Magnetometer.Y)
        managedObject.setValue(magnetometer?.z, forKey: Constants.CoreData.Capture.Frame.Magnetometer.Z)
    }
}

extension UIImage {
    static func imageFromPixels(_ pixels : UnsafeMutablePointer<UInt8>, width: Int, height: Int) -> UIImage? {
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
}
