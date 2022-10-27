//
//  AutoFocusView.swift
//  smafocus
//
//  Created by nao on 2022/10/23.
//

import SwiftUI

struct BLEConnectionView: View {
    @EnvironmentObject var bleManager : BMCameraManager
    @EnvironmentObject var navigationShare : NavigationShare
    
    //@Binding var navigationPath: [String]
    
    var body: some View {
        //NavigationView{
            VStack{
                NavigationLink(destination: LensCalibrationView(), isActive: $navigationShare.isCalibrating, label: {EmptyView()})
                Text("")
                Text("Camera : \(bleManager.deviceName)")
                Text("Lens Calibration : ")
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
        //}
    }
}

struct BLEConnectionView_Previews: PreviewProvider {
    @State static var navigationPath : [String] = []
    static var previews: some View {
        BLEConnectionView()
            .environmentObject(BMCameraManager())
            .environmentObject(NavigationShare())
    }
}
