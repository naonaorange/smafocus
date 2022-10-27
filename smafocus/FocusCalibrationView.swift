//
//  FocusCalibrationView.swift
//  BLESample
//
//  Created by nao on 2022/10/24.
//

import SwiftUI
import CoreData

struct FocusCalibrationView: View {
    @EnvironmentObject var bleManager : BMCameraManager
    @EnvironmentObject var navigationShare : NavigationShare
    
    @Environment(\.managedObjectContext) var viewContext
    @FetchRequest(sortDescriptors: [])
    var focusCalibrations : FetchedResults<FocusCalibration>
    
    @State var focusSliderValue : Double = 0
    
    var body: some View {
        VStack{
            HStack{
                List{
                    Section(header: Text("Distance")){
                        if (focusCalibrations.count > 0){
                            var f = focusCalibrations[0]
                            Text("\(f.distance1)")
                            Text("\(f.distance2)")
                        }
                    }
                }
                .listStyle(GroupedListStyle())
                List{
                    Section(header: Text("Focus")){
                        if (focusCalibrations.count > 0){
                            var f = focusCalibrations[0]
                            Text("\(f.focus1)")
                            Text("\(f.focus2)")
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
                   label: { EmptyView() })
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
    }
    
    func onAppear(){
        if (focusCalibrations.count <= 0){
            initializeFocusCalibration()
        }
    }
    func initializeFocusCalibration(){
        let f = FocusCalibration(context: viewContext)
        f.distance1 = 0.0
        f.distance2 = 0.0
        f.focus1 = 0.0
        f.focus2 = 0.0
        f.name = "default name"
        f.slope = 0.0
        f.intercept = 0.0
        f.version = 1
        do{
            try viewContext.save()
        }catch{
            fatalError("fail to save")
        }
    }
}

struct FocusCalibrationView_Previews: PreviewProvider {
    static var previews: some View {
        FocusCalibrationView()
            .environmentObject(BMCameraManager())
            .environmentObject(NavigationShare())
    }
}
