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
    
    // Constants for Settings
    struct Settings {
        static let Cell = "settingsCell"
        static let NumSections = 3
        static let MaxRows = 1000
        
        struct Box {
            static let NumRows = 1
            static let Title = "Box"
        }
        
        struct Location {
            static let NumRows = 2
            static let Title = "Location"
        }
        
        struct Profile {
            static let NumRows = 1
            static let Title = "Profile"
        }
    }
    
    // Constants for UserDefaults
    struct UserDefaults {
        static let Username = "username"
        static let Location = "location"
        static let Longitude = "longitude"
        static let Latitude = "latitude"
        static let BuildingAbbr = "buildingAbbr"
        static let BuildingName = "buildingName"
        static let RoomNumber = "roomNumber"
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
