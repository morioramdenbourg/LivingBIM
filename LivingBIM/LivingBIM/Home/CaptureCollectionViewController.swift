//
//  CaptureCollectionViewController.swift
//  LivingBIM
//
//  Created by Morio Ramdenbourg on 11/29/17.
//  Copyright © 2017 CAEE. All rights reserved.
//

import UIKit
import CoreData

private let reuseIdentifier = "scanCollection"

class CaptureCollectionViewController: UICollectionViewController {
    
    var capture: NSManagedObject?
    var frames: NSOrderedSet?
    var colorDisplay: Bool!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
//        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        if let capture = capture {
            frames = capture.value(forKeyPath: Constants.CoreData.Keys.CaptureToFrame) as? NSOrderedSet
        }
        
        // Initialize bar button
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Depth", style: .plain, target: self, action: #selector(tapped))
        colorDisplay = true
    }
    
    func tapped() {
        let title = colorDisplay ? "Depth" : "Color"
        navigationItem.rightBarButtonItem?.title = title
        colorDisplay = !colorDisplay
        self.collectionView?.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return frames?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: CaptureCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CaptureCollectionViewCell
    
        // Configure the cell
        let frame = frames?.object(at: indexPath.row) as? NSManagedObject
        
        // Decide which type of frames to display
        var data: Data?
        let key = colorDisplay ? Constants.CoreData.Capture.Frame.Color : Constants.CoreData.Capture.Frame.Depth
        data = frame?.value(forKey: key) as? Data
        
        // Display the first frame
        if let data = data {
            cell.imageView.image = UIImage(data: data)
        }
        
        return cell
    }
}
