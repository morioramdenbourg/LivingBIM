//
//  Keys.swift
//  LivingBIM
//
//  Created by Morio Ramdenbourg on 10/2/17.
//  Copyright © 2017 CAEE. All rights reserved.
//
struct Constants {
    
    // Cell reuse identifier
    static let CellIdentifier = "captureCell"
    
    // Constants for Settings
    struct Settings {
        static let Cell = "settingsCell"
        static let NumSections = 3
        static let MaxRows = 1000
        // Box section
        struct Box {
            static let NumRows = 1
            static let Title = "Box"
        }
        // Location section
        struct Location {
            static let NumRows = 2
            static let Title = "Location"
        }
        // Profile section
        struct Profile {
            static let NumRows = 1
            static let Title = "Profile"
        }
    }
    
    // Constants for UserDefaults
    struct UserDefaults {
        static let Username = "usernameUD"
        struct Building {
            static let Abbr = "buildingAbbrUD"
            static let Name = "buildingNameUD"
            static let RoomNumber = "roomNumberUD"
        }
    }
    
    // Constants for CoreData
    struct CoreData {
        
        struct Keys {
            static let Capture = "Capture"
            static let Frame = "Frame"
            static let CaptureToFrame = "frames"
            static let FrameToCapture = "capture"
        }
        
        // Keys for capture entity
        struct Capture {
            // Frame-wide
            static let Username = "username"
            static let CaptureTime = "captureTime"
            static let Description = "captureDescription"
            static let Mesh = "mesh"
            
            // Frame-specific
            struct Frame {
                static let Time = "time"
                static let Color = "color"
                static let Depth = "depth"
            }
        }
    }
}
