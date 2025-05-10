import SwiftUI

struct CameraControlView: View {
    @EnvironmentObject private var bleManager: BLEManager
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            VStack {
                if !bleManager.isConnected {
                    NoDeviceConnectedView()
                } else {
                    // Status indicator
                    HStack {
                        Circle()
                            .fill(bleManager.receiveInProgress ? Color.green : Color.blue)
                            .frame(width: 12, height: 12)
                        
                        Text(bleManager.receiveInProgress ? "Получение данных..." : "Готов к работе")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(bleManager.statusMessage)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Mode selection buttons
                    VStack(spacing: 20) {
                        Text("Выберите режим работы")
                            .font(.headline)
                            .padding(.bottom, 10)
                        
                        Button(action: {
                            isProcessing = true
                            bleManager.startRIRMode()
                            
                            // После некоторого времени деактивируем индикатор занятости
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                isProcessing = false
                            }
                        }) {
                            HStack {
                                Image(systemName: "waveform")
                                    .font(.system(size: 24))
                                Text("Получить импульсный отклик (RIR)")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(bleManager.receiveInProgress || isProcessing)
                        
                        Button(action: {
                            isProcessing = true
                            bleManager.startSnapshotMode()
                            
                            // После некоторого времени деактивируем индикатор занятости
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                isProcessing = false
                            }
                        }) {
                            HStack {
                                Image(systemName: "camera")
                                    .font(.system(size: 24))
                                Text("Создать акустический снимок")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(bleManager.receiveInProgress || isProcessing)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Processing indicator
                    if isProcessing || bleManager.receiveInProgress {
                        ProgressView("Обработка...")
                            .padding()
                    }
                }
            }
            .navigationTitle("Управление камерой")
        }
    }
}

struct CameraControlView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 1. Сценарий: устройство НЕ подключено
            CameraControlView()
                .environmentObject(makeManager(isConnected: false,
                                               status: "No Device Connected"))
                .previewDisplayName("Disconnected")
            
            // 2. Сценарий: устройство подключено и готово к измерению
            CameraControlView()
                .environmentObject(makeManager(isConnected: true,
                                               status: "Ready"))
                .previewDisplayName("Connected")
        }
        .previewDevice("iPhone 14 Pro")
    }
    
    // Вспомогательная функция для инициализации BLEManager
    private static func makeManager(isConnected: Bool,
                                    status: String) -> BLEManager {
        let m = BLEManager()
        m.isConnected = isConnected
        m.statusMessage = status
        return m
    }
}
