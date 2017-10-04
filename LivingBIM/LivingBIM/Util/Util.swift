//
//  Util.swift
//  LivingBIM
//
//  Created by Morio Ramdenbourg on 10/3/17.
//  Copyright © 2017 CAEE. All rights reserved.
//

import Foundation
import CoreLocation

// Format location string
func formatLocation(_ location: CLLocationCoordinate2D) -> String {
    return String(format: "%.2f", location.latitude) + ", " + String(format: "%.2f", location.longitude)
}

// Convert date to string
extension Date {
    func toString(dateFormat format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}
