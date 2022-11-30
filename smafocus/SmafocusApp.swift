//
//  smafocusApp.swift
//  smafocus
//
//  Created by nao on 2022/10/27.
//

import SwiftUI

@main
struct SmafocusApp: App {
    let persistenceController = PersistenceController()
    var body: some Scene {
        WindowGroup {
            SearchCameraView()
                .environmentObject(BMCameraManager())
                .environmentObject(NavigationShare())
                //.environmentObject(LensCalibrationManager())
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
