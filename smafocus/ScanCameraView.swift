//
//  ContentView.swift
//  smafocus
//
//  Created by nao on 2022/10/27.
//

import SwiftUI

struct ScanCameraView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
    }
}

struct ScanCameraView_Previews: PreviewProvider {
    static var previews: some View {
        ScanCameraView()
    }
}
