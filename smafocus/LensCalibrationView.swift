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
    @EnvironmentObject var faceDepthManager : FaceDepthManager
    @Environment(\.managedObjectContext) var viewContext
    @FetchRequest(sortDescriptors: [])
    var lensCalibrations : FetchedResults<LensCalibration>
    
    @State var lensCalibrationName = ""
    @State var focusSliderValue : Double = 0.0
    
    var body: some View {
        VStack{
            //Text("Calibrate Lens Parameters")
            //TextField("Lens Calibration Name", text: $lensCalibrationName)
            /*
            List{
                ForEach(lensCalibrations) {calib in
                    if((calib.name?.isEmpty) == false) {
                        Text(calib.name!)
                    }
                }
            }
            */
            if faceDepthManager.colorCGImage != nil {
                Image(faceDepthManager.colorCGImage, scale: 8, label: Text("colorCGImage"))
                Text("Depth : \(faceDepthManager.faceDepth) [m]")
                
            }
            /*
            Button(action: {
                let c = LensCalibration(context: viewContext)
                c.name = "test"
                do{
                    try viewContext.save()
                } catch{
                    print("error")
                }
            }, label: {Text("save")})
            .padding()
            Button(action: {
                for i in (0 ..< lensCalibrations.count).reversed(){
                    viewContext.delete(lensCalibrations[i])
                    do{
                        try viewContext.save()
                    } catch{
                        print("error")
                    }
                }
            }, label: {Text("delete")})
            */
            /*
            List{
                HStack{
                    Spacer()
                    Text("Distance [mm]")
                    Spacer()
                    Spacer()
                    Text("Focus        ")
                    Spacer()
                }
                HStack{
                    Spacer()
                    Text("\(lensCalibrationManager.distance1)")
                    Spacer()
                    Spacer()
                    Text("\(lensCalibrationManager.distance2)")
                    Spacer()
                }
                HStack{
                    Spacer()
                    Text("\(lensCalibrationManager.focus1)")
                    Spacer()
                    Spacer()
                    Text("\(lensCalibrationManager.focus2)")
                    Spacer()
                }
            }
                .listStyle(GroupedListStyle())
            */
            Text("Focus Value : \(Int(focusSliderValue))")
                        
            Slider(
                value: $focusSliderValue,
                in: 0...2048,
                step: 1,
                minimumValueLabel: Text("0"),
                   maximumValueLabel: Text("2048"),
                   label: { EmptyView() }
            )
            //.padding()
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
            //.padding()
            Button(action: {
                navigationShare.isCalibrating = false
                bleManager.isConnecting = false
                bleManager.isConnecting = true
            }, label: {Text("Exit Calibration Mode")})
            //.padding()
        }
        .navigationBarTitle(Text("Lens Calibration"))
        .navigationBarBackButtonHidden(true)
    }
    
}

struct LensCalibrationView_Previews: PreviewProvider {
    static var previews: some View {
        LensCalibrationView()
            .environmentObject(BMCameraManager())
            .environmentObject(NavigationShare())
            .environmentObject(FaceDepthManager())
            //.environmentObject(LensCalibrationManager())
    }
}
