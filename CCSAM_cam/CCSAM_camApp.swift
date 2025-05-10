//
//  CCSAM_camApp.swift
//  CCSAM_cam
//
//  Created by Руслан Тихонов on 09.05.2025.
//

import SwiftUI

@main
struct CCSAM_camApp: App {
    @StateObject private var bleManager = BLEManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bleManager)
        }
    }
}
