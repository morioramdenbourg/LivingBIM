//
//  Keys.swift
//  LivingBIM
//
//  Created by Morio Ramdenbourg on 10/2/17.
//  Copyright © 2017 CAEE. All rights reserved.
//
struct Keys {
    
    // Cell reuse identifier
    static let Cell = "captureCell"
    
    // Constants for UserDefaults
    struct UserDefaults {
        static let Username = "username"
        static let Location = "location"
    }
    
    // Constants for CoreData
    struct CoreData {
        
        // Keys for capture entity
        struct Capture {
            static let Key = "Capture"
            static let Username = "username"
            static let Date = "date"
            static let Location = "location"
            static let Text = "text"
            static let RGBFrame = "rgbFrame"
            static let DepthFrame = "depthFrame"
        }
    }
}
