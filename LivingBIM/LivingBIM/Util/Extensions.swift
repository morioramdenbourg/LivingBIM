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
import SwiftyJSON

// Date Extension
extension Date {
    // Convert date to string
    func toString(dateFormat format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}

// Coordinate Extension
extension CLLocationCoordinate2D {
    // Pretty string for coordinate
    func pretty() -> String {
        return String(format: "%.4f", self.latitude) + ", " + String(format: "%.4f", self.longitude)
    }
}

// Degrees Extension
extension CLLocationDegrees {
    // Pretty string for degrees
    func stringify() -> String {
        return String(format: "%.4f", self)
    }
    // Convert to a double
    func doubleify() -> Double {
        return Double(self)
    }
}

// ModelWrapper Extensions
extension ModelWrapper {
    // Add an entire capture's data to core data
    static func addCaptureData(managedObject: NSManagedObject?, captureTime time: Date?, zipData zip: Data?, description des: String?) {
        let defaults = UserDefaults.standard
        guard let managedObject = managedObject else { return }
        
        // Username
        if let username = defaults.value(forKey: Constants.UserDefaults.Username) {
            managedObject.setValue(username, forKey: Constants.CoreData.Capture.Username)
        }
        
        // Time
        if let time = time {
            managedObject.setValue(time, forKey: Constants.CoreData.Capture.CaptureTime)
        }
        
        // Mesh
        if let zip = zip {
            managedObject.setValue(zip, forKey: Constants.CoreData.Capture.Mesh)
        }
        
        // Description
        if let des = des {
            managedObject.setValue(des, forKey: Constants.CoreData.Capture.Description)
        }
    }
    
    // Grab sensor data and add to core data
    static func addFrameData(managedObject: NSManagedObject?, captureTime time: Date?, depthFrame depth: STDepthFrame?, colorFrame color: STColorFrame?, cameraGLProjection projection: UnsafeMutablePointer<Float>?, cameraViewPoint viewPoint: UnsafeMutablePointer<Float>?) {
        // Cannot run without delegate and managed object
        let delegate = AppDelegate.delegate
        guard let managedObject = managedObject else { return }
        
        // Heading
        if let heading = delegate.getHeading() {
            managedObject.setValue(heading.doubleify(), forKey: Constants.CoreData.Capture.Frame.Heading)
        }
        
        // Coordinate
        if let coordinate = delegate.getCoordinate() {
            managedObject.setValue(coordinate.latitude.doubleify(), forKey: Constants.CoreData.Capture.Frame.Coordinate.Latitude)
            managedObject.setValue(coordinate.longitude.doubleify(), forKey: Constants.CoreData.Capture.Frame.Coordinate.Longitude)
        }
        
        // Acceleration
        if let acceleration = delegate.getAcceleration() {
            managedObject.setValue(acceleration.x, forKey: Constants.CoreData.Capture.Frame.Acceleration.X)
            managedObject.setValue(acceleration.y, forKey: Constants.CoreData.Capture.Frame.Acceleration.Y)
            managedObject.setValue(acceleration.z, forKey: Constants.CoreData.Capture.Frame.Acceleration.Z)
        }
        
        // Gyroscope
        if let gyroscope = delegate.getGyroscope() {
            managedObject.setValue(gyroscope.x, forKey: Constants.CoreData.Capture.Frame.Gyroscope.X)
            managedObject.setValue(gyroscope.y, forKey: Constants.CoreData.Capture.Frame.Gyroscope.Y)
            managedObject.setValue(gyroscope.z, forKey: Constants.CoreData.Capture.Frame.Gyroscope.Z)
        }
        
        // Magnetometer
        if let magnetometer = delegate.getMagnetometer() {
            managedObject.setValue(magnetometer.x, forKey: Constants.CoreData.Capture.Frame.Magnetometer.X)
            managedObject.setValue(magnetometer.y, forKey: Constants.CoreData.Capture.Frame.Magnetometer.Y)
            managedObject.setValue(magnetometer.z, forKey: Constants.CoreData.Capture.Frame.Magnetometer.Z)
        }
        
        // Building
        if let buildingAbbr = getBuildingAbbr(), let buildingName = getBuildingName(), let roomNumber = getRoomNumber() {
            managedObject.setValue(buildingAbbr, forKey: Constants.CoreData.Capture.Frame.Building.Abbr)
            managedObject.setValue(buildingName, forKey: Constants.CoreData.Capture.Frame.Building.Name)
            managedObject.setValue(roomNumber, forKey: Constants.CoreData.Capture.Frame.Building.RoomNumber)
        }
        
        // Camera Projection
        if let projection = projection {
            let projArray = convertCameraToArray(projection)
            let projData = NSKeyedArchiver.archivedData(withRootObject: projArray as Any)
            managedObject.setValue(projData, forKey: Constants.CoreData.Capture.Frame.CameraGLProjection)
        }
        
        // View Point
        if let viewPoint = viewPoint {
            let viewArray = convertCameraToArray(viewPoint)
            let viewData = NSKeyedArchiver.archivedData(withRootObject: viewArray as Any)
            managedObject.setValue(viewData, forKey: Constants.CoreData.Capture.Frame.CameraViewPoint)
        }
        
        // Color
        if let color = color {
//            let rgbData = UIImage.dataFromSampleBuffer(color.sampleBuffer)
//            let rgbFrame = UIImage.imageFromSampleBuffer(color.sampleBuffer)
//            let rgbData = rgbFrame?.fromPNGToData()
            
//            AVCaptureStillImageOu
            let buff = CMSampleBufferGetImageBuffer(color.sampleBuffer)
            let ciImage = CIImage(cvPixelBuffer: buff!)
            let context = CIContext()
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let rgbData = context.pngRepresentation(of: ciImage, format: kCIFormatRGBA8, colorSpace: colorSpace, options:[:])
//            let rgbData = context.jpegRepresentation(of: ciImage, colorSpace: colorSpace, options:[:])
            managedObject.setValue(rgbData, forKey: Constants.CoreData.Capture.Frame.Color)
//            let image = UIImage(data: imageData) //  Here you have UIImage
        }
        
//        // Depth
//        let background = {
//            if let depth = depth {
//                let depthData = NSKeyedArchiver.archivedData(withRootObject: depth.converToDepthsArray() as Any)
//                managedObject.setValue(depthData, forKey: Constants.CoreData.Capture.Frame.Depth)
//            }
//        }
//
//        autoreleasepool {
//            DispatchQueue.background(delay: 0.0, background: background)
//        }
        
        if let depth = depth {
            let length = Int(depth.height * depth.width)
            let depthData = Data(bytes: depth.depthInMillimeters, count: 4*length)
            managedObject.setValue(depthData, forKey: Constants.CoreData.Capture.Frame.Depth)
            managedObject.setValue(length, forKey: "lengthDepth")
        }
        
        // Time
        if let time = time {
            managedObject.setValue(time, forKey: Constants.CoreData.Capture.Frame.Time)
        }
    }
}

extension DispatchQueue {
    static func background(delay: Double, background: (()->Void)?) {
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + delay) {
            background?()
        }
    }
}

//// Convert an UnsafeMutablePointer given by the structure io into an array for core data to store
func convertCameraToArray(_ array: UnsafeMutablePointer<Float>) -> [Float] {
    var points = [Float]()
    let length = 16
    for index in 0..<length {
        points.append(array[index])
    }
    return points
}

// UIImage Extensions
extension UIImage {
    
    // Convert a CMSampleBuffer to a UI Image
    static func imageFromSampleBuffer(_ sampleBuffer : CMSampleBuffer) -> UIImage? {
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
    
    // Convert sample buffer to data
    static func dataFromSampleBuffer(_ sampleBuffer : CMSampleBuffer) -> Data? {
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        CVPixelBufferLockBaseAddress(imageBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer!)
        let height = CVPixelBufferGetHeight(imageBuffer!)
        let src_buff = CVPixelBufferGetBaseAddress(imageBuffer!)
        let data = NSData(bytes: src_buff, length: bytesPerRow * height)
        CVPixelBufferUnlockBaseAddress(imageBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        return data as Data?
    }
    
    // Convert a PNG image to binary data
    func fromPNGToData() -> Data? {
        return UIImagePNGRepresentation(self)
    }
}

// STDepthFrame Extensions
extension STDepthFrame {
    
    // Convert a MutablePointer<Float> array into a swift array
    func converToDepthsArray() -> [Float]? {
        guard let depthsPointer = self.depthInMillimeters else {
            return nil
        }
        var depths = [Float]()
        let length = self.height * self.width
        depths.reserveCapacity(Int(length))
        for index in 0..<length {
            depths.append(depthsPointer[Int(index)])
        }
        return depths
    }
    
    func convert() -> [Float]? {
        guard let depthsPointer = self.depthInMillimeters else {
            return nil
        }
        let buffer = UnsafeBufferPointer(start: depthsPointer, count: Int(self.height * self.width))
        return Array(buffer)
    }
}
