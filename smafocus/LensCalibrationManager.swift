//
//  LensCalibrationManager.swift
//  smafocus
//
//  Created by nao on 2022/10/29.
//

import Foundation
import SwiftUI
import CoreData

struct LensCalibrationManager {
    /*
    var distance1 = 0.0
    var distance2 = 0.0
    var focus1 = 0.0
    var focus2 = 0.0
    var name = "default lens"
    var slope = 0.0
    var intercept = 0.0
    var version = 1
    */
    let container : NSPersistentContainer
    
    init(){
        container = NSPersistentContainer(name: "MyCoreData")
        container.loadPersistentStores(completionHandler: {(storeDescription, error) in
            if let error = error as NSError? {
                print("error!")
            }
        })
    }
}
