//
//  ContentView.swift
//  CCSAM_cam
//
//  Created by Руслан Тихонов on 09.05.2025.
//
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var bleManager: BLEManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DeviceConnectionView()
                .tabItem {
                    Label("Connect", systemImage: "antenna.radiowaves.left.and.right")
                }
                .tag(0)
            
            CameraControlView()
                .tabItem {
                    Label("Control", systemImage: "slider.horizontal.3")
                }
                .tag(1)
            
            ImpulseResponseView()
                .tabItem {
                    Label("Results", systemImage: "waveform")
                }
                .tag(2)
        }
        .onChange(of: selectedTab) { newValue in
            if newValue > 0 && !bleManager.isConnected {
                selectedTab = 0
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(BLEManager())
    }
}
