//
//  Logger.swift
//  LivingBIM
//
//  Created by Morio Ramdenbourg on 12/11/17.
//  Copyright © 2017 CAEE. All rights reserved.
//

import Foundation

// Pretty Log to the console for a module
func log(name n: String, _ items: Any...) {
    print("[" + n + "]", terminator: " ")
    for item in items {
        print(item, terminator: " ")
    }
    print()
}
