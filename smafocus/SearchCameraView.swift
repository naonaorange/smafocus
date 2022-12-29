//
//  SearchCameraView.swift
//  smafocus
//
//  Created by nao on 2022/10/27.
//

import SwiftUI

struct SearchCameraView: View {
    @State private var selectedPeripheralName: String? = ""
    @EnvironmentObject var bleManager : BMCameraManager
    @EnvironmentObject var navigationShare : NavigationShare
    
    var body: some View {
        NavigationView {
            VStack{
                NavigationLink(destination: LensCalibrationView(), isActive: $navigationShare.isCalibrating, label: {EmptyView()})
                NavigationLink(destination: BLEConnectionView(), isActive: $bleManager.isConnecting, label: {EmptyView()})
                Text("")
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
                        }, label: {Text("CONNECT")})
                    }else if(bleManager.isScaning){
                        Button(action: {
                            bleManager.stopScan()
                        }, label: {Text("STOP SEACHING")})
                    }else{
                        Button(action: {
                            bleManager.startScan()
                        }, label: {Text("START SEACHING")})
                    }
                }
                .padding()
            }
            .navigationBarTitle(Text("smafocus"))
            .navigationBarBackButtonHidden(true)
            .onAppear(){
                if(navigationShare.isDebugging){
                    bleManager.isConnecting = true
                }
            }
        }
    }
}

struct SearchCameraView_Previews: PreviewProvider {
    static var previews: some View {
        SearchCameraView()
            .environmentObject(BMCameraManager())
            .environmentObject(NavigationShare())
    }
}
