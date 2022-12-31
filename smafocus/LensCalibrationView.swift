//
//  LensCalibrationView.swift
//  smafocus
//
//  Created by nao on 2022/10/28.
//

import SwiftUI
import CoreData

struct LensCalibrationView: View {
    @EnvironmentObject var bleManager : BMCameraManager
    @EnvironmentObject var navigationShare : NavigationShare
    //@EnvironmentObject var lensCalibrationManager : LensCalibrationManager
    //@EnvironmentObject var faceDepthManager : FaceDepthManager
    @EnvironmentObject var qrCodeDepthManager : QrCodeDepthManager
    @Environment(\.managedObjectContext) var viewContext
    @FetchRequest(sortDescriptors: [])
    var lensCalibrations : FetchedResults<LensCalibration>
    
    @State var lensCalibrationName = ""
    @State var focusSliderValue : Double = 0.0
    @State private var isDisableLidarFunc = false
    let imageScale = 5.0
    
    var body: some View {
        VStack{
            HStack{
                if qrCodeDepthManager.colorCGImage != nil {
                    ZStack(alignment: .topLeading){
                        Image(qrCodeDepthManager.colorCGImage, scale: imageScale, label: Text("colorCGImage"))
                        if ((qrCodeDepthManager.qrCodeRect != nil)) {
                            Rectangle()
                                .fill(Color.red)
                                .opacity(0.5)
                                .offset(x: qrCodeDepthManager.imageSize.width * qrCodeDepthManager.qrCodeRect.minX / imageScale,
                                        y: qrCodeDepthManager.imageSize.height * (1.0 - qrCodeDepthManager.qrCodeRect.maxY) / imageScale)
                                .frame(width: qrCodeDepthManager.imageSize.width * qrCodeDepthManager.qrCodeRect.width / imageScale,
                                       height: qrCodeDepthManager.imageSize.height * qrCodeDepthManager.qrCodeRect.height / imageScale)
                        }
                    }
                }
                VStack{
                    if qrCodeDepthManager.colorCGImage != nil {
                        Text("Depth : \(qrCodeDepthManager.qrCodeDepth) [m]")
                            .padding()
                    }
                    Text("Focus Value : \(Int(focusSliderValue))")
                        .padding()
                    
                    Slider(
                        value: $focusSliderValue,
                        in: 0...2048,
                        step: 1,
                        minimumValueLabel: Text("0"),
                        maximumValueLabel: Text("2048"),
                        label: { EmptyView() }
                    )
                    .padding()
                    .onChange(of: focusSliderValue, perform: {newValue in
                        bleManager.changeFocus(focus: Int(newValue))
                    })
                    HStack{
                        Spacer()
                        Button(action: {
                            if ((focusSliderValue - 10.0) >= 0){
                                focusSliderValue -= 10
                            }else{
                                focusSliderValue = 0
                            }
                            bleManager.changeFocus(focus: Int(focusSliderValue))
                        }, label: {Text("-10")})
                        Spacer()
                        Spacer()
                        Spacer()
                        Spacer()
                        Spacer()
                        Spacer()
                        Button(action: {
                            if ((focusSliderValue + 10.0) <= 2048){
                                focusSliderValue += 10
                            }else{
                                focusSliderValue = 2048
                            }
                            bleManager.changeFocus(focus: Int(focusSliderValue))
                        }, label: {Text("+10")})
                        Spacer()
                    }
                    .padding()
                    Button(action: {
                        navigationShare.isCalibrating = false
                        bleManager.isConnecting = false
                        bleManager.isConnecting = true
                    }, label: {Text("Exit Calibration Mode")})
                    .padding()
                }
            }
        }
        .navigationBarTitle(Text("Lens Calibration"))
        .navigationBarBackButtonHidden(true)
        .onAppear{
            isDisableLidarFunc = !qrCodeDepthManager.start()
        }
        .onDisappear{
            qrCodeDepthManager.stop()
        }
    }
    
}

struct LensCalibrationView_Previews: PreviewProvider {
    static var previews: some View {
        LensCalibrationView()
            .environmentObject(BMCameraManager())
            .environmentObject(NavigationShare())
            .environmentObject(FaceDepthManager())
            .environmentObject(QrCodeDepthManager())
            //.environmentObject(LensCalibrationManager())
    }
}
