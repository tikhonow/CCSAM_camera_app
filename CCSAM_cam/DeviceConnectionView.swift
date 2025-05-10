import SwiftUI
import CoreBluetooth

struct DeviceConnectionView: View {
    @EnvironmentObject private var bleManager: BLEManager
    
    var body: some View {
        NavigationView {
            VStack {
                // Status message
                Text(bleManager.statusMessage)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                // Scan button
                Button(action: {
                    if bleManager.isScanning {
                        bleManager.stopScanning()
                    } else {
                        bleManager.startScanning()
                    }
                }) {
                    Text(bleManager.isScanning ? "Stop Scanning" : "Scan for Devices")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(bleManager.isScanning ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                
                // Disconnect button (only shown when connected)
                if bleManager.isConnected {
                    Button(action: {
                        bleManager.disconnect()
                    }) {
                        Text("Disconnect")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }
                
                // Device list
                if bleManager.discoveredDevices.isEmpty && bleManager.isScanning {
                    Text("Searching for devices...")
                        .padding()
                } else if bleManager.discoveredDevices.isEmpty {
                    Text("No devices found")
                        .padding()
                } else {
                    List {
                        ForEach(bleManager.discoveredDevices, id: \.identifier) { device in
                            DeviceRow(device: device)
                                .onTapGesture {
                                    bleManager.connect(to: device)
                                }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
                
                Spacer()
            }
            .navigationTitle("Connect to Device")
        }
    }
}

struct DeviceRow: View {
    let device: CBPeripheral
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(device.name ?? "Unknown Device")
                    .font(.headline)
                Text(device.identifier.uuidString)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "antenna.radiowaves.left.and.right")
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}
struct DeviceConnectionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 1. Сценарий: идёт сканирование, устройств нет
            DeviceConnectionView()
                .environmentObject(makeManager(isScanning: true,
                                               status: "Searching for devices…",
                                               isConnected: false,
                                               devices: []))
                .previewDisplayName("Scanning…")
            
            // 2. Сценарий: сканирование остановлено, устройств нет
            DeviceConnectionView()
                .environmentObject(makeManager(isScanning: false,
                                               status: "No devices found",
                                               isConnected: false,
                                               devices: []))
                .previewDisplayName("No Devices")
        }
        .previewDevice("iPhone 14 Pro")
    }
    
    // Вспомогательная функция для создания менеджера с нужным состоянием
    private static func makeManager(isScanning: Bool,
                                    status: String,
                                    isConnected: Bool,
                                    devices: [CBPeripheral]) -> BLEManager {
        let m = BLEManager()
        m.isScanning = isScanning
        m.statusMessage = status
        m.isConnected = isConnected
        m.discoveredDevices = devices
        return m
    }
}
