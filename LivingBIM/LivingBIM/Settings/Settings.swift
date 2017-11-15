//
//  Settings.swift
//  LivingBIM
//
//  Created by Morio Ramdenbourg on 11/8/17.
//  Copyright © 2017 CAEE. All rights reserved.
//

import Foundation
import BoxContentSDK

fileprivate let settingsModule = "Settings"

func getBoxCredentials() -> BOXUserMini? {
    guard let contentClient = BOXContentClient.default() else {
        log(moduleName: settingsModule, "error creating Box Client")
        return nil
    }
    return contentClient.user
}

func loginBox(completion: @escaping (BOXUser?, Error?) -> Void) {
    guard let contentClient = BOXContentClient.default() else {
        log(moduleName: settingsModule, "error creating Box Client")
        return
    }
    
    // Authenticate box, then call the completion handler
    contentClient.authenticate(completionBlock: { (user: BOXUser?, error: Error?) -> Void in
        log(moduleName: settingsModule, "successfully logged into box")
        completion(user, error)
    })
}

func logoutBox(completion: () -> Void) {
    guard let contentClient = BOXContentClient.default() else {
        log(moduleName: settingsModule, "error creating Box Client")
        return
    }
    
    // Log out of box
    contentClient.logOut()
    
    log(moduleName: settingsModule, "successfully logged out of box")
    
    // Completion after Box logout
    completion()
}

func getUsername() -> String? {
    return UserDefaults.standard.string(forKey: Keys.UserDefaults.Username)
}

func askUsername(viewController vc: UIViewController, completion: @escaping (String) -> Void) {
    log(moduleName: settingsModule, "getting username")
    
    // Create text field
    var inputTextField: UITextField?
    
    // Create the AlertController
    let actionSheetController: UIAlertController = UIAlertController(title: "Username Required", message: "Enter Username", preferredStyle: .alert)
    
    // Create and an option action
    let saveAction: UIAlertAction = UIAlertAction(title: "Save", style: .default) { action -> Void in
        // Get text
        let text: String = inputTextField?.text ?? ""
        
        // Perform completion on the text
        completion(text)
        
        // Save the new username to user defaults
        UserDefaults.standard.set(text, forKey: Keys.UserDefaults.Username)
    }
    actionSheetController.addAction(saveAction)
    
    // Create and add the Cancel action
    let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in }
    actionSheetController.addAction(cancelAction)
    
    // Add a text field
    actionSheetController.addTextField { textField -> Void in
        inputTextField = textField
        inputTextField?.placeholder = "Username"
        saveAction.isEnabled = false
    }
    
    // If the text field is empty, then disable the Save button
    NotificationCenter.default.addObserver(forName: NSNotification.Name.UITextFieldTextDidChange, object: inputTextField, queue: OperationQueue.main) { (notification) in
        saveAction.isEnabled = inputTextField?.text?.count ?? 0 > 0
    }
    
    // Present alert
    vc.present(actionSheetController, animated: true, completion: nil)
}

func getBuildingAbbr() -> String? {
    return UserDefaults.standard.string(forKey: Keys.UserDefaults.BuildingAbbr)
}

func getBuildingName() -> String? {
    return UserDefaults.standard.string(forKey: Keys.UserDefaults.BuildingName)
}

func getRoomNumber() -> String? {
    return UserDefaults.standard.string(forKey: Keys.UserDefaults.RoomNumber)
}

func askBuildingInfo(viewController vc: UIViewController, completion: @escaping (String, String, String) -> Void) {
    log(moduleName: settingsModule, "asking for building information")
    
    // Create picker
    let sb = UIStoryboard(name: "Main", bundle: nil)
    let picker = sb.instantiateViewController(withIdentifier: "buildingPicker") as! BuildingPickerViewController
    picker.completion = completion
    
    // Present picker
    vc.present(picker, animated: true, completion: nil)
}
