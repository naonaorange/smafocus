//
//  AutoFocusView.swift
//  smafocus
//
//  Created by nao on 2022/10/23.
//

import SwiftUI
import CoreData

struct BLEConnectionView: View {
    @EnvironmentObject var bleManager : BMCameraManager
    @EnvironmentObject var navigationShare : NavigationShare
    
    @Environment(\.managedObjectContext) var viewContext
    @FetchRequest(sortDescriptors: [])
    var lensCalibrations : FetchedResults<LensCalibration>
    
    //@Binding var navigationPath: [String]
    @State var selection = 0
    
    var body: some View {
        //NavigationView{
            VStack{
                NavigationLink(destination: LensCalibrationView(), isActive: $navigationShare.isCalibrating, label: {EmptyView()})
                Text("")
                Text("Camera : \(bleManager.deviceName)")
                HStack{
                    Text("Lens Calibration : ")
                    Picker(selection: $selection, label: Text("")){
                        if (lensCalibrations.count > 0){
                            let l = lensCalibrations[0]
                            Text("\(l.name!)")
                        }else{
                            Text("")
                        }
                    }
                    
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
