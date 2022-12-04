//
//  AutoFocusView.swift
//  smafocus
//
//  Created by nao on 2022/10/23.
//

import SwiftUI
import CoreData

struct Person: Identifiable {
    public let id = UUID()
    public var givenName: String
    public var familyName: String
}

struct BLEConnectionView: View {
    @EnvironmentObject var bleManager : BMCameraManager
    @EnvironmentObject var navigationShare : NavigationShare
    //@EnvironmentObject var lensCalibrationManager : LensCalibrationManager
    
    @State var selection = 0
    
    var columns : [GridItem] = Array(repeating: .init(.flexible()), count: 2)
    
    var body: some View {
        VStack{
            NavigationLink(destination: LensCalibrationView(), isActive: $navigationShare.isCalibrating, label: {EmptyView()})
            Text("")
            Text("Camera : \(bleManager.deviceName)")
            HStack{
                Text("Lens Calibration : ")
                /*
                Picker(selection: $selection, label: Text("")){
                    Text(lensCalibrationManager.name)
                }
                */
                
            }
            Button(action: {
                navigationShare.isCalibrating = true
            }, label: {Text("CALIBRATION")})
            .padding()
            Button(action: {
                bleManager.disconnect()
            }, label: {Text("DISCONNECT")})
            .padding()
        }
        .navigationBarTitle(Text("Auto Focus"))
        .navigationBarBackButtonHidden(true)
    }
}

struct BLEConnectionView_Previews: PreviewProvider {
    @State static var navigationPath : [String] = []
    static var previews: some View {
        BLEConnectionView()
            .environmentObject(BMCameraManager())
            .environmentObject(NavigationShare())
            .environmentObject(FaceDepthManager())
            //.environmentObject(LensCalibrationManager())
    }
}
