//
//  LensCalibrationManager.swift
//  smafocus
//
//  Created by nao on 2022/10/29.
//

import Foundation
import SwiftUI
import CoreData

class LensCalibrationManager : ObservableObject{
    var distance1 = 0.0
    var distance2 = 0.0
    var focus1 = 0.0
    var focus2 = 0.0
    var name = "default lens"
    var slope = 0.0
    var intercept = 0.0
    var version = 1
    
    init(){
    }
    
}
