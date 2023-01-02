//
//  LensCalibrationManager.swift
//  smafocus
//
//  Created by nao on 2022/10/29.
//

import Foundation
import SwiftUI


class LensCalibrationManager: NSObject, ObservableObject{
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
    struct LensCalibrationParameter : Identifiable, Codable{
        public let id = UUID()
        public var name : String
        public var focusDepthSets : [FocusDepthSet]
        public var version : Int
    }

    struct FocusDepthSet: Identifiable, Codable {
        public let id = UUID()
        public var focus: Double
        public var depth: Double
    }
    
    @Published var lensCalibrationParameters : [LensCalibrationParameter] = []
    
    override init(){
        super.init()
        load()
        
    }
    
    func add(focus: Double, depth: Double){
        lensCalibrationParameters[0].focusDepthSets.append(FocusDepthSet(focus: focus, depth: depth))
        save()
    }
    
    func deleteAll(){
        lensCalibrationParameters[0].focusDepthSets = []
        save()
    }
    
    func save(){
        let jsonEncoder = JSONEncoder()
        guard let data = try? jsonEncoder.encode(lensCalibrationParameters) else {
            return
        }
        UserDefaults.standard.set(data, forKey: "lensCalibrationParameters")
    }
    
    func load() {
        let jsonDecoder = JSONDecoder()
        guard let data = UserDefaults.standard.data(forKey: "lensCalibrationParameters"),
              let p = try? jsonDecoder.decode([LensCalibrationParameter].self, from: data) else {
                var focusDepthSets = [
                    FocusDepthSet(focus: 1.0, depth: 2.0),
                    FocusDepthSet(focus: 5.0, depth: 6.0),
                    FocusDepthSet(focus: 10.0, depth: 11.0)
                ]
                lensCalibrationParameters = []
                lensCalibrationParameters.append(LensCalibrationParameter(name: "Test Lens", focusDepthSets: focusDepthSets, version: 1))
                return
        }
        lensCalibrationParameters = p
    }
}
