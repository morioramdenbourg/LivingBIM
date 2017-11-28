//
//  SettingsTableViewCell.swift
//  LivingBIM
//
//  Created by Morio Ramdenbourg on 11/8/17.
//  Copyright © 2017 CAEE. All rights reserved.
//

import UIKit
import BoxContentSDK

fileprivate let module = "SettingsTableViewCell"

class SettingsTableViewCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var detailsButton: UIButton!
    
    // Constants
    let loggedOutMsg = "Log in"
    let noUsernameMsg = "(No username)"
    
    // VC
    var vc: SettingsTableViewController?
    
    // Define the action that the button will have
    @IBAction func detailsAction(_ sender: Any) {
        // Get row and section
        let row = self.tag % Constants.Settings.MaxRows
        let section = self.tag / Constants.Settings.MaxRows
                
        switch section {
        case 0: // Box Section
            
            switch row {
            case 0:
                // If the user is already logged in, allow them to log out
                if getBoxCredentials() != nil {
                    // Create the alert
                    let alert: UIAlertController = UIAlertController(title: "Log out", message: "Are you sure you would want to log out of box?", preferredStyle: .alert)
                    
                    // Yes Action
                    let yes: UIAlertAction = UIAlertAction(title: "Yes", style: .default) { action -> Void in
                        logoutBox {
                            self.setButton(self.loggedOutMsg)
                        }
                    }
                    alert.addAction(yes)
                    
                    // Create and add the no action
                    let cancel: UIAlertAction = UIAlertAction(title: "No", style: .cancel) { action -> Void in }
                    alert.addAction(cancel)
                    
                    // Present alert
                    vc?.present(alert, animated: true, completion: nil)
                }
                else { // User not logged in, give the option
                    loginBox { (credentials: BOXUser?, error: Error?) in
                        if error == nil, let credentials = credentials {
                            self.setButton(credentials.login) // Successfully logged in
                        }
                    }
                }
                
            default: break
            }
            
        case 1: // Location Section
            
            switch row {
            case 0:
                // Allow change building
                if let vc = vc {
                    askBuildingInfo(viewController: vc) { buildingAbbr, buildingName, roomNumber -> Void in
                        let btn = buildingName + " (" + buildingAbbr + ") " + " - " + roomNumber
                        self.setButton(btn)
                    }
                }
            default: break
            }
            
        case 2: // Profile section
            
            switch row {
            case 0:
                // Allow the option to change username
                if let vc = vc {
                    askUsername(viewController: vc) { username -> Void in
                        self.setButton(username) // Change text to new username
                    }
                }
            default: break
            }
            
        default: break
        }
    }
    
    func setButton(_ title: String) {
        detailsButton.setTitle(title, for: .normal)
    }
    
    func setTitle(_ title: String) {
        label.text = title
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
