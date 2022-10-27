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
    
    @Environment(\.managedObjectContext) var viewContext
    @FetchRequest(sortDescriptors: [])
    var lensCalibrations : FetchedResults<LensCalibration>
    
    @State var focusSliderValue : Double = 0.0
    
    var body: some View {
        VStack{
            Text("")
            HStack{
                List{
                    Section(header: Text("Distance")){
                        if (lensCalibrations.count > 0){
                            let l = lensCalibrations[0]
                            Text("\(l.distance1)")
                            Text("\(l.distance2)")
                        }
                    }
                }
                .listStyle(GroupedListStyle())
                List{
                    Section(header: Text("Focus")){
                        if (lensCalibrations.count > 0){
                            let l = lensCalibrations[0]
                            Text("\(l.focus1)")
                            Text("\(l.focus2)")
                        }
                    }
                }
                .listStyle(GroupedListStyle())
            }
            Text("Focus Value : \(Int(focusSliderValue))")
                        
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
            }, label: {Text("calib false")})
        }
        .onAppear(perform: {onAppear()})
        .navigationBarTitle(Text("Lens Calibration"))
        .navigationBarBackButtonHidden(true)
    }
    
    func onAppear(){
        if (lensCalibrations.count <= 0){
            initializeLensCalibration()
        }
    }
    
    func initializeLensCalibration(){
        let l = LensCalibration(context: viewContext)
        l.distance1 = 0.0
        l.distance2 = 0.0
        l.focus1 = 0.0
        l.focus2 = 0.0
        l.name = "default name"
        l.slope = 0.0
        l.intercept = 0.0
        l.version = 1
        do{
            try viewContext.save()
        }catch{
            print("[LensCalibrationView] Error! : Failed to initialize the lens calibration")
        }
    }
}

struct LensCalibrationView_Previews: PreviewProvider {
    static var previews: some View {
        LensCalibrationView()
            .environmentObject(BMCameraManager())
            .environmentObject(NavigationShare())
    }
}
