//
//  ScanCameraView.swift
//  smafocus
//
//  Created by nao on 2022/10/27.
//

import SwiftUI

struct ScanCameraView: View {
    @State private var selectedPeripheralName: String? = ""
    @EnvironmentObject var bleManager : BMCameraManager
    @EnvironmentObject var navigationShare : NavigationShare
    
    var body: some View {
        NavigationView {
            VStack{
                NavigationLink(destination: FocusCalibrationView(), isActive: $navigationShare.isCalibrating, label: {EmptyView()})
                NavigationLink(destination: BLEConnectionView(), isActive: $bleManager.isConnecting, label: {EmptyView()})
                Text("Camera List")
                    .padding()
                List(selection: $selectedPeripheralName){
                    ForEach(bleManager.peripherals){ p in
                        Text(p.name).tag(p.name)
                    }
                }
                Group{
                    if selectedPeripheralName != "" {
                        Button(action: {
                            bleManager.connect(peripheralName: selectedPeripheralName!)
                        }, label: {Text("CONNECT TO CAMERA")})
                    }else if(bleManager.isScaning){
                        Button(action: {
                            bleManager.stopScan()
                        }, label: {Text("STOP SEACHING FOR CAMERAS")})
                    }else{
                        Button(action: {
                            bleManager.startScan()
                        }, label: {Text("START SEACHING FOR CAMERAS")})
                    }
                }
                .padding()
            }
                //.navigationBarTitle(Text("BLE SAMPLE APP"))
        }
    }
}

struct ScanCameraView_Previews: PreviewProvider {
    static var previews: some View {
        ScanCameraView()
            .environmentObject(BMCameraManager())
            .environmentObject(NavigationShare())
    }
}
