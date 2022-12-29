//
//  NavigaionShare.swift
//  smafocus
//
//  Created by nao on 2022/10/25.
//

import Foundation

class NavigationShare : ObservableObject{
    @Published var isCalibrating : Bool = false
    @Published var isDebugging : Bool = true
    
    init(){
    }
}
