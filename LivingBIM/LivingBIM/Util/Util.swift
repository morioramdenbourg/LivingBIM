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
