//
//  BLEManager.swift
//  CCSAM_cam
//
//  Created by Руслан Тихонов on 09.05.2025.
//

import Foundation
import CoreBluetooth
import Combine
import AVFoundation
import UIKit

class BLEManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isScanning = false
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var connectedDevice: CBPeripheral?
    @Published var isConnected = false
    @Published var impulseResponseData: [Float] = []
    @Published var statusMessage = "Ready to scan"
    @Published var receiveInProgress = false
    @Published var rt60Value: Double? = nil
    @Published var wavFileURL: URL? = nil
    @Published var snapshotImage: UIImage? = nil
    
    // MARK: - Дополнительные публикуемые свойства
    @Published var earlyDecayTime: Double? = nil // EDT
    @Published var clarityFactor: Double? = nil // C50
    @Published var definitionFactor: Double? = nil // D50
    @Published var centralTime: Double? = nil // Ts
    @Published var bassRatio: Double? = nil // BR
    @Published var frequencyRT60: [String: Double] = [:] // RT60 на разных частотах
    
    // MARK: - BLE Properties
    private var centralManager: CBCentralManager!
    private var serviceUUID = CBUUID(string: "12345678-1234-1234-1234-1234567890AB") // Example service UUID for acoustic camera
    private var controlCharacteristicUUID = CBUUID(string: "12345678-1234-1234-1234-1234567890AC") // Example characteristic UUID for control
    private var dataCharacteristicUUID = CBUUID(string: "12345678-1234-1234-1234-1234567890AD") // Example characteristic UUID for data
    
    private var controlCharacteristic: CBCharacteristic?
    private var dataCharacteristic: CBCharacteristic?
    
    // Буфер для приема изображений
    private var imageDataBuffer = Data()
    private var expectedImageSize: Int = 0
    private var receivingImageData = false
    private var imageWidth: Int = 0
    private var imageHeight: Int = 0
    private var isHeaderReceived = false
    private var isJPEGMode = false
    
    // Command codes
    private let CMD_RIR_MODE: UInt8 = 0x10
    private let CMD_SNAPSHOT_MODE: UInt8 = 0x20
    
    // Recording properties
    private var audioRecorder: AVAudioRecorder?
    
    override init() {
        super.init()
        // Явно указываем, что требуется предоставить разрешение для Bluetooth
        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionShowPowerAlertKey: true]
        )
    }
    
    // MARK: - Public Methods
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            statusMessage = "Bluetooth is not available"
            return
        }
        
        discoveredDevices.removeAll()
        isScanning = true
        statusMessage = "Scanning for devices..."
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        
        // Auto-stop scanning after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.stopScanning()
        }
    }
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        statusMessage = "Scan stopped"
    }
    
    func connect(to peripheral: CBPeripheral) {
        statusMessage = "Connecting to \(peripheral.name ?? "device")..."
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnect() {
        if let connectedDevice = connectedDevice {
            centralManager.cancelPeripheralConnection(connectedDevice)
        }
    }
    
    // MARK: - Camera Control Methods
    func startRIRMode() {
        guard let characteristic = controlCharacteristic, let peripheral = connectedDevice else {
            statusMessage = "Device not ready"
            return
        }
        
        let commandData = Data([CMD_RIR_MODE])
        peripheral.writeValue(commandData, for: characteristic, type: .withResponse)
        statusMessage = "Starting RIR mode..."
        receiveInProgress = true
    }
    
    func startSnapshotMode() {
        guard let characteristic = controlCharacteristic, let peripheral = connectedDevice else {
            statusMessage = "Device not ready"
            return
        }
        
        // Отправляем команду "SNAPSHOT" с переводом строки
        let commandData = "SNAPSHOT".data(using: .utf8)!
        peripheral.writeValue(commandData, for: characteristic, type: .withResponse)
        statusMessage = "Starting snapshot mode..."
        receiveInProgress = true
        
        // Очищаем буфер и готовимся к приему изображения
        imageDataBuffer = Data()
        receivingImageData = true
        isHeaderReceived = false
        expectedImageSize = 0
    }
    
    // MARK: - Audio Recording Methods
    func startAudioRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
            
            let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentPath.appendingPathComponent("impulse_response_\(Date().timeIntervalSince1970).wav")
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            
            statusMessage = "Recording started..."
            wavFileURL = audioFilename
            
        } catch {
            statusMessage = "Recording failed: \(error.localizedDescription)"
        }
    }
    
    func stopAudioRecording() {
        audioRecorder?.stop()
        statusMessage = "Recording stopped"
        
        // Calculate RT60 from the recorded audio if needed
        if let url = wavFileURL {
            calculateRT60(from: url)
            performAdvancedAnalysis() // Добавляем расширенный анализ после расчета RT60
        }
    }
    
    // MARK: - RT60 Calculation
    func calculateRT60(from audioURL: URL) {
        do {
            let audioFile = try AVAudioFile(forReading: audioURL)
            let format = audioFile.processingFormat
            let frameCount = UInt32(audioFile.length)
            
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
            try audioFile.read(into: buffer!)
            
            // Get samples from the buffer
            guard let samples = buffer?.floatChannelData?[0] else {
                statusMessage = "Failed to get audio samples"
                return
            }
            
            var sampleArray = [Float]()
            for i in 0..<Int(frameCount) {
                sampleArray.append(samples[i])
            }
            
            // Basic RT60 calculation
            // Find peak value
            let peakValue = sampleArray.max() ?? 0
            
            // Find time where signal drops by 60dB (or find -60dB point)
            let thresholdValue = peakValue * pow(10, -60/20) // -60dB
            
            var rt60Time = 0.0
            let sampleRate = Double(format.sampleRate)
            
            for (index, value) in sampleArray.enumerated() {
                if abs(value) <= thresholdValue {
                    rt60Time = Double(index) / sampleRate
                    break
                }
            }
            
            rt60Value = rt60Time
            statusMessage = "RT60 calculated: \(String(format: "%.2f", rt60Time)) seconds"
            
        } catch {
            statusMessage = "RT60 calculation failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Расширенный анализ RIR
    func performAdvancedAnalysis() {
        guard !impulseResponseData.isEmpty else { return }
        
        // Вычисление EDT (Early Decay Time)
        calculateEDT()
        
        // Вычисление ясности и разборчивости
        calculateClarityAndDefinition()
        
        // Вычисление центрального времени
        calculateCentralTime()
        
        // Симуляция расчета RT60 в разных частотных диапазонах
        simulateFrequencyRT60()
        
        statusMessage = "Выполнен расширенный анализ импульсного отклика"
    }
    
    // Вычисление EDT (Early Decay Time) - времени уменьшения уровня на 10 дБ, умноженного на 6
    private func calculateEDT() {
        let peakValue = impulseResponseData.max() ?? 0
        let thresholdValue = peakValue * pow(10, -10/20) // -10dB
        
        var edtTime = 0.0
        let sampleRate = 44100.0 // Предполагаемая частота дискретизации
        
        for (index, value) in impulseResponseData.enumerated() {
            if abs(value) <= thresholdValue {
                edtTime = Double(index) / sampleRate * 6.0 // Умножаем на 6 для получения EDT
                break
            }
        }
        
        earlyDecayTime = edtTime
    }
    
    // Расчет параметров ясности (C50) и разборчивости (D50)
    private func calculateClarityAndDefinition() {
        // Расчет для 50 мс (примерно 2205 сэмплов при 44.1кГц)
        let boundary = min(2205, impulseResponseData.count)
        
        let earlyEnergy = impulseResponseData[0..<boundary].map { $0 * $0 }.reduce(0, +)
        let lateEnergy = impulseResponseData[boundary..<impulseResponseData.count].map { $0 * $0 }.reduce(0, +)
        
        // C50 = 10 * log10(early/late) дБ
        clarityFactor = 10.0 * log10(Double(earlyEnergy / max(lateEnergy, 0.000001)))
        
        // D50 = early/(early+late)
        definitionFactor = Double(earlyEnergy / (earlyEnergy + lateEnergy))
    }
    
    // Расчет центрального времени Ts
    private func calculateCentralTime() {
        var weightedSum = 0.0
        var totalEnergy = 0.0
        let sampleRate = 44100.0
        
        for (index, sample) in impulseResponseData.enumerated() {
            let t = Double(index) / sampleRate
            let energy = Double(sample * sample)
            
            weightedSum += t * energy
            totalEnergy += energy
        }
        
        centralTime = weightedSum / max(totalEnergy, 0.000001)
    }
    
    // Симуляция расчета RT60 в разных частотных диапазонах
    private func simulateFrequencyRT60() {
        // В реальном приложении здесь бы разделяли сигнал на частотные диапазоны
        // и проводили анализ для каждого отдельно
        // Здесь просто симуляция для демонстрации
        
        let rt60 = rt60Value ?? 1.0
        
        frequencyRT60 = [
            "125 Hz": rt60 * (1.0 + Double.random(in: -0.3...0.3)),
            "250 Hz": rt60 * (1.0 + Double.random(in: -0.25...0.25)),
            "500 Hz": rt60 * (1.0 + Double.random(in: -0.2...0.2)),
            "1000 Hz": rt60,
            "2000 Hz": rt60 * (1.0 + Double.random(in: -0.15...0.15)),
            "4000 Hz": rt60 * (1.0 - Double.random(in: 0.1...0.4))
        ]
        
        // Расчет Bass Ratio (BR) - отношение времени реверберации на низких частотах к средним
        let lowFreq = (frequencyRT60["125 Hz"] ?? rt60) + (frequencyRT60["250 Hz"] ?? rt60)
        let midFreq = (frequencyRT60["500 Hz"] ?? rt60) + (frequencyRT60["1000 Hz"] ?? rt60)
        
        bassRatio = lowFreq / midFreq
    }
    
    // Обработка данных, полученных по BLE
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            statusMessage = "Error reading characteristic value: \(error.localizedDescription)"
            return
        }
        
        guard let data = characteristic.value, !data.isEmpty else {
            statusMessage = "Received empty data packet"
            return
        }
        
        if characteristic.uuid == dataCharacteristicUUID {
            if receivingImageData {
                // Обрабатываем данные изображения
                processImageData(data)
            } else {
                // Обрабатываем данные импульсного отклика
                parseImpulseResponseData(data)
            }
        }
    }
    
    // Обработка данных изображения
    private func processImageData(_ data: Data) {
        // Если это первый пакет и заголовок еще не получен
        if !isHeaderReceived {
            if let headerString = String(data: data, encoding: .utf8) {
                statusMessage = "Получен заголовок: \(headerString)"
                
                if headerString.hasPrefix("RAW:") {
                    // Парсим размеры изображения из формата "RAW:W,H"
                    let headerContent = headerString.dropFirst(4)
                    let headerParts = headerContent.components(separatedBy: ",")
                    
                    if headerParts.count >= 2, 
                       let width = Int(headerParts[0].trimmingCharacters(in: .whitespaces)),
                       let height = Int(headerParts[1].trimmingCharacters(in: .whitespacesAndNewlines)) {
                        
                        imageWidth = width
                        imageHeight = height
                        expectedImageSize = width * height * 2 // RGB565 = 2 байта на пиксель
                        isHeaderReceived = true
                        isJPEGMode = false
                        
                        statusMessage = "Начало приема RAW изображения: \(width)x\(height), ожидается \(expectedImageSize) байт"
                    } else {
                        statusMessage = "Ошибка в формате RAW-заголовка: \(headerString)"
                    }
                    return
                } else if headerString.hasPrefix("SIZE:") {
                    // Парсим размер JPEG изображения
                    if let sizeValue = Int(headerString.dropFirst(5).trimmingCharacters(in: .whitespacesAndNewlines)) {
                        expectedImageSize = sizeValue
                        isHeaderReceived = true
                        isJPEGMode = true
                        
                        statusMessage = "Начало приема JPEG изображения: ожидается \(expectedImageSize) байт"
                    } else {
                        statusMessage = "Ошибка в формате JPEG-заголовка: \(headerString)"
                    }
                    return
                } else {
                    statusMessage = "Неизвестный формат заголовка: \(headerString)"
                    return
                }
            }
        }
        
        // Если уже получили заголовок, добавляем бинарные данные в буфер
        if isHeaderReceived {
            imageDataBuffer.append(data)
            
            // Отображаем прогресс
            let progress = Float(imageDataBuffer.count) / Float(expectedImageSize) * 100
            statusMessage = "Прием изображения: \(Int(progress))% (\(imageDataBuffer.count)/\(expectedImageSize) байт)"
            
            // Если получили все данные
            if imageDataBuffer.count >= expectedImageSize {
                if isJPEGMode {
                    constructImageFromJPEGData()
                } else {
                    constructImageFromRGB565Data()
                }
            }
        }
    }
    
    // Создание изображения из JPEG данных
    private func constructImageFromJPEGData() {
        guard isHeaderReceived && imageDataBuffer.count >= expectedImageSize else { 
            statusMessage = "Недостаточно данных для создания JPEG изображения"
            return 
        }
        
        if let image = UIImage(data: imageDataBuffer) {
            DispatchQueue.main.async {
                self.snapshotImage = image
                self.statusMessage = "JPEG изображение успешно получено (\(image.size.width)x\(image.size.height))"
                self.resetImageReceivingState()
            }
        } else {
            statusMessage = "Не удалось создать UIImage из полученных JPEG данных"
            resetImageReceivingState()
        }
    }
    
    // Конвертирование RGB565 данных в UIImage
    private func constructImageFromRGB565Data() {
        guard isHeaderReceived && imageDataBuffer.count >= expectedImageSize else { 
            statusMessage = "Недостаточно данных для создания RAW изображения"
            return 
        }
        
        // Создаем контекст для рисования
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bytesPerRow = imageWidth * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let context = CGContext(
            data: nil,
            width: imageWidth,
            height: imageHeight,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            statusMessage = "Не удалось создать контекст для изображения"
            resetImageReceivingState()
            return
        }
        
        guard let buffer = context.data else {
            statusMessage = "Не удалось получить буфер контекста"
            resetImageReceivingState()
            return
        }
        
        // Конвертируем RGB565 в RGBA
        let rgba = buffer.bindMemory(to: UInt32.self, capacity: imageWidth * imageHeight)
        
        for y in 0..<imageHeight {
            for x in 0..<imageWidth {
                let pixelIndex = y * imageWidth + x
                let byteIndex = pixelIndex * 2 // 2 байта на пиксель в RGB565
                
                if byteIndex + 1 < imageDataBuffer.count {
                    // Считываем 2 байта для RGB565
                    let byte1 = imageDataBuffer[byteIndex]
                    let byte2 = imageDataBuffer[byteIndex + 1]
                    
                    // Распаковываем RGB565 в компоненты (little-endian)
                    let rgb565 = UInt16(byte1) | (UInt16(byte2) << 8)
                    
                    // Извлекаем компоненты RGB из RGB565
                    let r = UInt8((rgb565 & 0xF800) >> 11) << 3  // 5 бит для R (биты 11-15)
                    let g = UInt8((rgb565 & 0x07E0) >> 5) << 2   // 6 бит для G (биты 5-10)
                    let b = UInt8((rgb565 & 0x001F)) << 3        // 5 бит для B (биты 0-4)
                    
                    // Собираем RGBA (порядок компонентов зависит от bitmapInfo)
                    let argb: UInt32 = (UInt32(255) << 24) | (UInt32(r) << 16) | (UInt32(g) << 8) | UInt32(b)
                    rgba[pixelIndex] = argb
                }
            }
        }
        
        if let cgImage = context.makeImage() {
            DispatchQueue.main.async {
                self.snapshotImage = UIImage(cgImage: cgImage)
                self.statusMessage = "RGB565 изображение успешно получено (\(self.imageWidth)x\(self.imageHeight))"
                self.resetImageReceivingState()
            }
        } else {
            statusMessage = "Не удалось создать UIImage из RGB565 данных"
            resetImageReceivingState()
        }
    }
    
    // Сброс состояния приема изображения
    private func resetImageReceivingState() {
        receiveInProgress = false
        receivingImageData = false
        imageDataBuffer = Data()
        isHeaderReceived = false
    }
    
    // Helper to parse impulse response data from raw BLE data
    private func parseImpulseResponseData(_ data: Data) {
        // This is a simplified example - actual parsing would depend on the device's data format
        let byteCount = data.count / MemoryLayout<Float>.size
        impulseResponseData = [Float](repeating: 0.0, count: byteCount)
        
        data.withUnsafeBytes { rawBufferPointer in
            if let floatBuffer = rawBufferPointer.bindMemory(to: Float.self).baseAddress {
                for i in 0..<byteCount {
                    impulseResponseData[i] = floatBuffer[i]
                }
            }
        }
        
        statusMessage = "Received impulse response data: \(impulseResponseData.count) points"
        receiveInProgress = false
        
        // Save the received data as WAV file
        saveImpulseResponseAsWav()
        
        // Выполнить расширенный анализ
        performAdvancedAnalysis()
    }
    
    // Save impulse response data as WAV file
    private func saveImpulseResponseAsWav() {
        guard !impulseResponseData.isEmpty else { return }
        
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let wavFileName = "impulse_response_\(Date().timeIntervalSince1970).wav"
        let fileURL = documentPath.appendingPathComponent(wavFileName)
        
        // WAV file header constants
        let sampleRate: UInt32 = 44100
        let bitsPerSample: UInt16 = 32
        let numChannels: UInt16 = 1
        
        // Create WAV header
        var header = Data()
        
        // "RIFF" chunk descriptor
        header.append("RIFF".data(using: .ascii)!)
        let dataSize = UInt32(impulseResponseData.count * 4) + 36
        header.append(withUnsafeBytes(of: dataSize.littleEndian) { Data($0) })
        header.append("WAVE".data(using: .ascii)!)
        
        // "fmt " sub-chunk
        header.append("fmt ".data(using: .ascii)!)
        let fmtSize: UInt32 = 16
        header.append(withUnsafeBytes(of: fmtSize.littleEndian) { Data($0) })
        let audioFormat: UInt16 = 3 // IEEE float
        header.append(withUnsafeBytes(of: audioFormat.littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: numChannels.littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: sampleRate.littleEndian) { Data($0) })
        let byteRate = UInt32(sampleRate * UInt32(numChannels) * UInt32(bitsPerSample) / 8)
        header.append(withUnsafeBytes(of: byteRate.littleEndian) { Data($0) })
        let blockAlign = UInt16(numChannels * bitsPerSample / 8)
        header.append(withUnsafeBytes(of: blockAlign.littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: bitsPerSample.littleEndian) { Data($0) })
        
        // "data" sub-chunk
        header.append("data".data(using: .ascii)!)
        let subchunk2Size = UInt32(impulseResponseData.count * 4)
        header.append(withUnsafeBytes(of: subchunk2Size.littleEndian) { Data($0) })
        
        // Create the data
        var soundData = Data()
        for sample in impulseResponseData {
            soundData.append(withUnsafeBytes(of: sample) { Data($0) })
        }
        
        // Write to file
        do {
            try header.write(to: fileURL)
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            fileHandle.seekToEndOfFile()
            fileHandle.write(soundData)
            fileHandle.closeFile()
            
            wavFileURL = fileURL
            statusMessage = "Saved WAV file: \(wavFileName)"
            
            // Calculate RT60
            calculateRT60(from: fileURL)
            
        } catch {
            statusMessage = "Failed to save WAV file: \(error.localizedDescription)"
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            statusMessage = "Bluetooth is powered on"
        case .poweredOff:
            statusMessage = "Bluetooth is powered off"
            isConnected = false
            connectedDevice = nil
        case .resetting:
            statusMessage = "Bluetooth is resetting"
        case .unauthorized:
            statusMessage = "Bluetooth is unauthorized"
        case .unsupported:
            statusMessage = "Bluetooth is not supported"
        case .unknown:
            statusMessage = "Bluetooth state is unknown"
        @unknown default:
            statusMessage = "Unknown Bluetooth state"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredDevices.contains(peripheral) {
            discoveredDevices.append(peripheral)
            statusMessage = "Discovered: \(peripheral.name ?? "Unknown device")"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedDevice = peripheral
        isConnected = true
        statusMessage = "Connected to \(peripheral.name ?? "device")"
        
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        statusMessage = "Failed to connect: \(error?.localizedDescription ?? "Unknown error")"
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedDevice = nil
        isConnected = false
        controlCharacteristic = nil
        dataCharacteristic = nil
        statusMessage = "Disconnected from \(peripheral.name ?? "device")"
        
        if let error = error {
            statusMessage = "Disconnected with error: \(error.localizedDescription)"
        }
    }
}

// MARK: - CBPeripheralDelegate
extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            statusMessage = "Error discovering services: \(error.localizedDescription)"
            return
        }
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            peripheral.discoverCharacteristics([controlCharacteristicUUID, dataCharacteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            statusMessage = "Error discovering characteristics: \(error.localizedDescription)"
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == controlCharacteristicUUID {
                controlCharacteristic = characteristic
                statusMessage = "Found control characteristic"
            } else if characteristic.uuid == dataCharacteristicUUID {
                dataCharacteristic = characteristic
                // Enable notifications for the data characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                statusMessage = "Found data characteristic and enabled notifications"
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            statusMessage = "Error writing to characteristic: \(error.localizedDescription)"
        } else {
            statusMessage = "Successfully wrote to characteristic"
        }
    }
}
