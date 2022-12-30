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
    @State private var isDisableLidarFunc = false
    
    let imageScale = 5.0
    
    var columns : [GridItem] = Array(repeating: .init(.flexible()), count: 2)
    
    var body: some View {
        VStack{
            NavigationLink(destination: LensCalibrationView(), isActive: $navigationShare.isCalibrating, label: {EmptyView()})
            HStack{
                if faceDepthManager.colorCGImage != nil {
                    ZStack(alignment: .topLeading){
                        Image(faceDepthManager.colorCGImage, scale: imageScale, label: Text("colorCGImage"))
                        if ((faceDepthManager.faceRect != nil)) {
                            Rectangle()
                                .fill(Color.orange)
                                .opacity(0.5)
                                .offset(x: faceDepthManager.imageSize.width * faceDepthManager.faceRect.minX / imageScale,
                                        y: faceDepthManager.imageSize.height * (1.0 - faceDepthManager.faceRect.maxY) / imageScale)
                                .frame(width: faceDepthManager.imageSize.width * faceDepthManager.faceRect.width / imageScale,
                                       height: faceDepthManager.imageSize.height * faceDepthManager.faceRect.height / imageScale)
                        }
                    }
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
            isDisableLidarFunc = !faceDepthManager.start()
        }
        .onDisappear{
            faceDepthManager.stop()
        }
        .alert("Alert", isPresented: $isDisableLidarFunc) {
            Button("OK") {
                // 了解ボタンが押された時の処理
            }
        } message: {
            Text("Can not run this application. This iPhone is NOT equipped the LiDAR device.")
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
