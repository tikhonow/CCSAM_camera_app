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
    @State private var showWhatsNew = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bleManager)
                .onAppear {
                    checkAppVersion()
                }
                .sheet(isPresented: $showWhatsNew) {
                    WhatsNewView(isPresented: $showWhatsNew)
                }
        }
    }
    
    private func checkAppVersion() {
        // Всегда показываем экран "Что нового" при каждом запуске приложения
        showWhatsNew = true
        
        // Старая логика сохранена в комментариях на случай, если понадобится показывать
        // экран "Что нового" только при обновлении версии
        /*
        // Получаем текущую версию приложения
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        
        // Ключ для хранения последней просмотренной версии в UserDefaults
        let lastVersionKey = "lastViewedVersion"
        
        // Получаем последнюю просмотренную версию
        let lastViewedVersion = UserDefaults.standard.string(forKey: lastVersionKey) ?? ""
        
        // Если версии не совпадают, показываем экран "Что нового"
        if currentVersion != lastViewedVersion {
            showWhatsNew = true
            
            // Сохраняем текущую версию как просмотренную
            UserDefaults.standard.set(currentVersion, forKey: lastVersionKey)
        }
        */
    }
}
