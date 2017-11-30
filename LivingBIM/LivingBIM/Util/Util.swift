//
//  Util.swift
//  LivingBIM
//
//  Created by Morio Ramdenbourg on 10/3/17.
//  Copyright © 2017 CAEE. All rights reserved.
//

import Foundation
import CoreLocation

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

// Pretty Log to the console for a module
func log(name n: String, _ items: Any...) {
    print("[" + n + "]", terminator: " ")
    for item in items {
        print(item, terminator: " ")
    }
    print()
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
