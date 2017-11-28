//
//  BuildingPickerViewController.swift
//  LivingBIM
//
//  Created by Morio Ramdenbourg on 11/14/17.
//  Copyright © 2017 CAEE. All rights reserved.
//

import UIKit
import Alamofire
import Kanna

fileprivate let module = "BuildingPickerViewController"
fileprivate let site = "https://facilitiesservices.utexas.edu/buildings/"

class BuildingPickerViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var completion: ((String, String, String) -> Void)?
    var buildings: [(abbreviation: String, name: String)] = []
    private var spinner: SpinnerView? // Spinner
    
    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var roomNumberField: UITextField!
    @IBOutlet weak var submitAction: UIButton!
    
    @IBAction func submitPress(_ sender: Any) {
        log(name: module, "pressed submit")
        
        // Get selected row
        let row = picker.selectedRow(inComponent: 0)
        let data = buildings[row]
        
        // Get room number
        let roomNumber = roomNumberField.text ?? ""
        
        log(name: module, "adding to defaults:", data.abbreviation, data.name, roomNumber)
        
        // Add to user defaults
        UserDefaults.standard.set(data.abbreviation, forKey: Constants.UserDefaults.Building.Abbr)
        UserDefaults.standard.set(data.name, forKey: Constants.UserDefaults.Building.Name)
        UserDefaults.standard.set(roomNumber, forKey: Constants.UserDefaults.Building.RoomNumber)
        
        // Perform completion handler
        self.completion?(data.abbreviation, data.name, roomNumber)
        
        // Dismiss this view controller
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the picker frame size and initialize spinner
        let frame = picker.frame
        spinner = SpinnerView(frame: CGRect(x: frame.origin.x + picker.frame.width / 2, y: frame.origin.y + picker.frame.height / 2, width: 50, height: 50))
        
        log(name: module, "viewDidLoad")
        
        // Set delegate and datasource
        picker.delegate = self
        picker.dataSource = self

        // Add default selection
        picker.showsSelectionIndicator = true
        picker.selectRow(0, inComponent: 0, animated: true)
        
        // Empty out data
        buildings = []
        
        // Grab the data
        scrapeSite()
    }
    
    fileprivate func scrapeSite() {
        self.view.addSubview(spinner!)
        Alamofire.request(site).responseString { response in
            log(name: module, "connected to", site, ":", response.result.isSuccess)
            if let html = response.result.value {
                self.parseHTML(html: html)
            }
        }
    }
    
    fileprivate func parseHTML(html: String) {
        if let doc = Kanna.HTML(html: html, encoding: String.Encoding.utf8) {
            // Parse the document
            for select in doc.xpath("//select[@id='building']") {
                for option in select.xpath("//option") {
                    if let tokens = option.text?.components(separatedBy: " - ") {
                        if tokens.count == 2 {
                            buildings.append((abbreviation: tokens[0], name: tokens[1]))
                        }
                    }
                }
            }
            
            // Reload table
            picker.reloadComponent(0)
            
            // Remove spinner
            self.spinner?.removeFromSuperview()
        }
    }
    
    // Number of components
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // Number of rows
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return buildings.count
    }
    
    // Data for row
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return buildings[row].abbreviation + " - " + buildings[row].name
    }
    
    // Selected row
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        log(name: module, "selected row:", row)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
