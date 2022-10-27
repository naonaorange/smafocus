//
//  Persistent.swift
//  smafocus
//
//  Created by nao on 2022/10/28.
//

import CoreData

struct PersistenceController {
    let container: NSPersistentContainer
    
    init(){
        container = NSPersistentContainer(name: "MyCoreData")
        container.loadPersistentStores(completionHandler: { (storeDesciption, error) in
            if let error = error as NSError? {
                print("[Persistent] ERROR!: Failed to load persistent stores \(error)")
            }
        })
    }
}
