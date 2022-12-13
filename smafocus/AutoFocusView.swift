//
//  AutoFocusView.swift
//  smafocus
//
//  Created by nao on 2022/10/23.
//

import SwiftUI
import CoreData
import Foundation

struct Person: Identifiable {
    public let id = UUID()
    public var givenName: String
    public var familyName: String
}

struct BLEConnectionView: View {
    @EnvironmentObject var bleManager : BMCameraManager
    @EnvironmentObject var navigationShare : NavigationShare
    @EnvironmentObject var faceDepthManager : FaceDepthManager
    //@EnvironmentObject var lensCalibrationManager : LensCalibrationManager
        
    @State var selection = 0
    
    var columns : [GridItem] = Array(repeating: .init(.flexible()), count: 2)
    
    var body: some View {
        VStack{
            NavigationLink(destination: LensCalibrationView(), isActive: $navigationShare.isCalibrating, label: {EmptyView()})
            HStack{
                if faceDepthManager.colorCGImage != nil {
                    Image(faceDepthManager.colorCGImage, scale: 5, label: Text("colorCGImage"))
                    
                }
                VStack{
                    Text("Depth : \(faceDepthManager.faceDepth) [m]")
                        .padding()
                    Text("Focus: \(faceDepthManager.focus)")
                        .padding()
                    Button(action: {
                        faceDepthManager.startAutoFocus(manager: bleManager)
                    }, label: {Text("START AUTO FOCUS")})
                    .padding()
                    Button(action: {
                        faceDepthManager.stopAutoFocus()
                    }, label: {Text("STOP AUTO FOCUS")})
                    .padding()
                    Button(action: {
                        navigationShare.isCalibrating = true
                    }, label: {Text("CALIBRATION")})
                    .padding()
                    Button(action: {
                        bleManager.disconnect()
                    }, label: {Text("DISCONNECT")})
                    .padding()
                }
            }
        }
        .navigationBarTitle(Text("Auto Focus"))
        .navigationBarBackButtonHidden(true)
        .onAppear{
            faceDepthManager.start()
        }
        .onDisappear{
            faceDepthManager.stop()
        }
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
