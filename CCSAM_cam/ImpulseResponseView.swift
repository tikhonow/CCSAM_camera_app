import SwiftUI
import Charts
import AVFoundation
import ActivityKit

// Определение структуры для Live Activity
struct RIRRecordingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var progress: Double
        var remainingTime: Double
    }
    
    var recordingName: String
}

struct ImpulseResponseView: View {
    @EnvironmentObject private var bleManager: BLEManager
    @State private var selectedTab = 0
    @State private var recordingDuration: Double = 5.0
    @State private var showingRIRRecordingView = false
    @State private var recordedRIRData: [Float] = []
    
    var body: some View {
        NavigationView {
            VStack {
                if !bleManager.isConnected {
                    NoDeviceConnectedView()
                } else {
                    // Tab selector
                    Picker("Выберите тип данных", selection: $selectedTab) {
                        Text("Импульсный отклик").tag(0)
                        Text("Акустический снимок").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    if selectedTab == 0 {
                        // Импульсный отклик
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                if !bleManager.impulseResponseData.isEmpty {
                                    Text("Импульсный отклик")
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    ImpulseResponseChart(data: bleManager.impulseResponseData)
                                        .frame(height: 300)
                                        .padding(.horizontal)
                                    
                                    Divider()
                                    
                                    // Acoustic parameters section
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Акустические параметры")
                                            .font(.headline)
                                            .padding(.horizontal)
                                        
                                        // RT60 information
                                        if let rt60 = bleManager.rt60Value {
                                            HStack {
                                                Text("RT60:")
                                                    .font(.headline)
                                                Text("\(String(format: "%.2f", rt60)) секунд")
                                                    .font(.headline)
                                                    .foregroundColor(.blue)
                                                
                                                Spacer()
                                                
                                                Button(action: {
                                                    // Recalculate RT60 if needed
                                                    if let url = bleManager.wavFileURL {
                                                        bleManager.calculateRT60(from: url)
                                                    }
                                                }) {
                                                    Image(systemName: "arrow.clockwise")
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                            .padding(.horizontal)
                                            
                                            // EDT
                                            if let edt = bleManager.earlyDecayTime {
                                                HStack {
                                                    Text("EDT:")
                                                        .font(.subheadline)
                                                    Text("\(String(format: "%.2f", edt)) секунд")
                                                        .font(.subheadline)
                                                        .foregroundColor(.blue)
                                                }
                                                .padding(.horizontal)
                                            }
                                            
                                            // C50 и D50
                                            if let clarity = bleManager.clarityFactor, 
                                               let definition = bleManager.definitionFactor {
                                                HStack {
                                                    Text("C50: \(String(format: "%.1f", clarity)) дБ")
                                                        .font(.subheadline)
                                                    Spacer()
                                                    Text("D50: \(String(format: "%.1f", definition * 100))%")
                                                        .font(.subheadline)
                                                }
                                                .padding(.horizontal)
                                            }
                                            
                                            // Центральное время
                                            if let ts = bleManager.centralTime {
                                                Text("Центральное время: \(String(format: "%.1f", ts * 1000)) мс")
                                                    .font(.subheadline)
                                                    .padding(.horizontal)
                                            }
                                            
                                            // RT60 в разных частотных диапазонах
                                            if !bleManager.frequencyRT60.isEmpty {
                                                VStack(alignment: .leading) {
                                                    Text("RT60 по частотам:")
                                                        .font(.subheadline)
                                                        .fontWeight(.bold)
                                                        .padding(.top, 4)
                                                    
                                                    ForEach(bleManager.frequencyRT60.sorted(by: { $0.key < $1.key }), id: \.key) { freq, value in
                                                        HStack {
                                                            Text(freq)
                                                                .font(.caption)
                                                            Spacer()
                                                            Text("\(String(format: "%.2f", value)) с")
                                                                .font(.caption)
                                                        }
                                                    }
                                                    
                                                    // Отношение басов (BR)
                                                    if let br = bleManager.bassRatio {
                                                        HStack {
                                                            Text("Bass Ratio:")
                                                                .font(.caption)
                                                                .fontWeight(.bold)
                                                            Spacer()
                                                            Text("\(String(format: "%.2f", br))")
                                                                .font(.caption)
                                                        }
                                                        .padding(.top, 4)
                                                    }
                                                }
                                                .padding(.horizontal)
                                                .padding(.vertical, 4)
                                                .background(Color.gray.opacity(0.1))
                                                .cornerRadius(8)
                                                .padding(.horizontal)
                                            }
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    Text("Статистика данных")
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    DataStatisticsView(data: bleManager.impulseResponseData)
                                        .padding(.horizontal)
                                }
                                
                                // Если есть записанные данные RIR, показываем их
                                if !recordedRIRData.isEmpty {
                                    Divider()
                                    
                                    Text("Записанный RIR")
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    ImpulseResponseChart(data: recordedRIRData)
                                        .frame(height: 300)
                                        .padding(.horizontal)
                                    
                                    DataStatisticsView(data: recordedRIRData)
                                        .padding(.horizontal)
                                }
                                
                                VStack(spacing: 20) {
                                    // Кнопка для записи RIR
                                    Button(action: {
                                        showingRIRRecordingView = true
                                    }) {
                                        HStack {
                                            Image(systemName: "waveform.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(.green)
                                            
                                            Text("Записать RIR")
                                                .font(.headline)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(UIColor.systemGray6))
                                        .cornerRadius(10)
                                    }
                                    .padding(.horizontal)
                                }
                                .padding(.vertical)
                            }
                            .padding(.vertical)
                        }
                        .sheet(isPresented: $showingRIRRecordingView) {
                            RIRRecordingView(recordingDuration: $recordingDuration, recordedData: $recordedRIRData)
                        }
                    } else {
                        // Акустический снимок
                        if let image = bleManager.snapshotImage {
                            ScrollView {
                                VStack(spacing: 20) {
                                    Text("Акустический снимок")
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(10)
                                        .padding(.horizontal)
                                    
                                    Text("Время получения: \(Date().formatted(date: .abbreviated, time: .standard))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal)
                                    
                                    // Кнопка для сохранения в галерею
                                    Button(action: {
                                        saveImageToGallery(image)
                                    }) {
                                        HStack {
                                            Image(systemName: "square.and.arrow.down")
                                            Text("Сохранить в галерею")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                    }
                                    .padding(.horizontal)
                                }
                                .padding(.vertical)
                            }
                        } else {
                            VStack(spacing: 20) {
                                Image(systemName: "camera")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                
                                Text("Нет акустического снимка")
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Text("Нажмите 'Создать акустический снимок' в разделе 'Управление'")
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.gray)
                                    .padding()
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle(selectedTab == 0 ? "Импульсный отклик" : "Акустический снимок")
        }
    }
    
    // Функция для сохранения изображения в галерею
    private func saveImageToGallery(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}

// Новый компонент для записи RIR
struct RIRRecordingView: View {
    @Binding var recordingDuration: Double
    @Binding var recordedData: [Float]
    @State private var isRecording = false
    @State private var countdown: Double = 0
    @State private var audioRecorder: AVAudioRecorder?
    @State private var timer: Timer?
    @State private var activity: Activity<RIRRecordingAttributes>? = nil
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Запись RIR")
                    .font(.title)
                    .padding()
                
                Text("Подготовьте стартовый пистолет или другой источник импульсного звука")
                    .multilineTextAlignment(.center)
                    .padding()
                
                VStack(alignment: .leading) {
                    Text("Продолжительность записи: \(String(format: "%.1f", recordingDuration)) секунд")
                    
                    Slider(value: $recordingDuration, in: 1...30, step: 0.5)
                        .padding(.vertical)
                }
                .padding()
                
                if isRecording {
                    Text("Идет запись: \(String(format: "%.1f", countdown)) сек")
                        .font(.title)
                        .foregroundColor(.red)
                        .padding()
                    
                    ProgressView(value: countdown, total: recordingDuration)
                        .padding()
                }
                
                Button(action: {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                }) {
                    HStack {
                        Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.system(size: 24))
                        
                        Text(isRecording ? "Остановить запись" : "Начать запись")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isRecording ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
                
                Spacer()
            }
            .navigationBarItems(trailing: Button("Готово") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
            
            let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentPath.appendingPathComponent("rir_recording.wav")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            
            isRecording = true
            countdown = recordingDuration
            
            // Запускаем Live Activity для Dynamic Island
            startLiveActivity()
            
            // Запускаем таймер для обратного отсчета
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                if countdown > 0 {
                    countdown -= 0.1
                    
                    // Обновляем Live Activity
                    updateLiveActivity()
                } else {
                    stopRecording()
                }
            }
            
        } catch {
            print("Ошибка записи: \(error.localizedDescription)")
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        timer?.invalidate()
        
        // Останавливаем Live Activity
        endLiveActivity()
        
        // Обработка записанного аудио для получения RIR
        if let url = audioRecorder?.url {
            processRecordedAudio(url: url)
        }
    }
    
    private func processRecordedAudio(url: URL) {
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat
            let frameCount = UInt32(audioFile.length)
            
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                print("Ошибка создания буфера")
                return
            }
            
            try audioFile.read(into: buffer)
            
            // Преобразуем аудиоданные в массив Float
            var audioData: [Float] = []
            
            if let channelData = buffer.floatChannelData?[0] {
                let channelDataPtr = UnsafeMutableBufferPointer(start: channelData, 
                                                               count: Int(buffer.frameLength))
                audioData = Array(channelDataPtr)
            }
            
            // Нормализация данных
            if let maxValue = audioData.max() {
                if maxValue > 0 {
                    for i in 0..<audioData.count {
                        audioData[i] = audioData[i] / maxValue
                    }
                }
            }
            
            // Обновляем привязанную переменную с данными RIR
            DispatchQueue.main.async {
                self.recordedData = audioData
                self.presentationMode.wrappedValue.dismiss()
            }
            
        } catch {
            print("Ошибка обработки аудио: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Live Activity Methods
    
    private func startLiveActivity() {
        if #available(iOS 16.1, *) {
            let initialContentState = RIRRecordingAttributes.ContentState(
                progress: 0,
                remainingTime: recordingDuration
            )
            
            let activityAttributes = RIRRecordingAttributes(recordingName: "Запись RIR")
            
            do {
                activity = try Activity.request(
                    attributes: activityAttributes,
                    contentState: initialContentState,
                    pushType: nil
                )
            } catch {
                print("Error starting live activity: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateLiveActivity() {
        if #available(iOS 16.1, *) {
            let progress = 1.0 - (countdown / recordingDuration)
            
            let updatedContentState = RIRRecordingAttributes.ContentState(
                progress: progress,
                remainingTime: countdown
            )
            
            Task {
                await activity?.update(using: updatedContentState)
            }
        }
    }
    
    private func endLiveActivity() {
        if #available(iOS 16.1, *) {
            Task {
                await activity?.end(dismissalPolicy: .immediate)
            }
        }
    }
}

struct ImpulseResponseChart: View {
    let data: [Float]
    
    var body: some View {
        if #available(iOS 16.0, *) {
            Chart {
                ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Время", index),
                        y: .value("Амплитуда", value)
                    )
                    .foregroundStyle(Color.blue)
                }
            }
            .chartXAxis {
                AxisMarks(position: .bottom)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        } else {
            // Fallback for iOS 15 and below
            LegacyChartView(data: data)
        }
    }
}

struct LegacyChartView: View {
    let data: [Float]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let maxValue = data.max() ?? 1
                let minValue = data.min() ?? -1
                let range = max(abs(maxValue), abs(minValue)) * 2
                
                let xStep = width / CGFloat(data.count - 1)
                let yMiddle = height / 2
                
                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * xStep
                    let y = yMiddle - CGFloat(value / range) * height
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.blue, lineWidth: 2)
            
            // Draw horizontal axis
            Path { path in
                path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
                path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height / 2))
            }
            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        }
    }
}

struct DataStatisticsView: View {
    let data: [Float]
    
    var max: Float {
        data.max() ?? 0
    }
    
    var min: Float {
        data.min() ?? 0
    }
    
    var average: Float {
        data.reduce(0, +) / Float(data.count)
    }
    
    var rms: Float {
        let sumOfSquares = data.reduce(0) { $0 + $1 * $1 }
        return sqrt(sumOfSquares / Float(data.count))
    }
    
    var body: some View {
        VStack(spacing: 10) {
            StatRow(label: "Количество точек", value: "\(data.count)")
            StatRow(label: "Максимум", value: String(format: "%.4f", max))
            StatRow(label: "Минимум", value: String(format: "%.4f", min))
            StatRow(label: "Среднее", value: String(format: "%.4f", average))
            StatRow(label: "RMS", value: String(format: "%.4f", rms))
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct ImpulseResponseView_Previews: PreviewProvider {
    static var previews: some View {
        let previewManager = BLEManager()
        previewManager.isConnected = true
        previewManager.impulseResponseData = [
            1.0353, 0.9882, 0.9804, 0.9866, 0.9605, 0.8853, 0.9059, 0.8663, 0.8501, 0.8435,
            0.8216, 0.8316, 0.8018, 0.7735, 0.7647, 0.7475, 0.7560, 0.7077, 0.7039, 0.6668,
            0.6193, 0.6701, 0.6613, 0.6164, 0.6642, 0.5774, 0.5954, 0.5790, 0.6019, 0.5893,
            0.5519, 0.5455, 0.5095, 0.4772, 0.4997, 0.4997, 0.5114, 0.5012, 0.4599, 0.4524,
            0.4284, 0.4120, 0.3976, 0.4622, 0.4046, 0.3978, 0.3735, 0.4062, 0.3506, 0.3711,
            0.9500, 0.3683, 0.3432, 0.3228, 0.3390, 0.3414, 0.3276, 0.3259, 0.3008, 0.3000,
            0.2877, 0.2880, 0.2731, 0.2491, 0.2816, 0.2645, 0.2345, 0.2711, 0.2385, 0.2526,
            0.2612, 0.2443, 0.2597, 0.2075, 0.2357, 0.2094, 0.2013, 0.2028, 0.2039, 0.2071,
            0.1786, 0.2159, 0.2033, 0.1594, 0.2161, 0.2206, 0.2026, 0.1719, 0.1506, 0.1897,
            0.1572, 0.1865, 0.1630, 0.1752, 0.1597, 0.1637, 0.1468, 0.1794, 0.1434, 0.1461,
            0.1730, 0.1057, 0.1046, 0.1468, 0.1015, 0.1613, 0.1118, 0.1027, 0.1538, 0.1427,
            0.1482, 0.1267, 0.0892, 0.1426, 0.0969, 0.1163, 0.1172, 0.0932, 0.1067, 0.1110,
            0.3982, 0.0669, 0.0931, 0.1120, 0.0699, 0.0791, 0.0718, 0.1159, 0.0908, 0.0839,
            0.0589, 0.0836, 0.0579, 0.0706, 0.0558, 0.0807, 0.0774, 0.0604, 0.0712, 0.0402,
            0.0310, 0.0684, 0.0618, 0.0700, 0.1038, 0.0739, 0.0357, 0.0752, 0.0255, 0.0416,
            0.0484, 0.0831, 0.0329, 0.0304, 0.0440, 0.0318, 0.0667, 0.0217, 0.0195, 0.0328,
            0.0308, 0.0785, 0.0582, 0.0401, 0.0131, 0.0538, 0.0161, 0.0045, 0.0585, 0.0404,
            0.0518, 0.0391, 0.0492, 0.0184, 0.0101, 0.0438, 0.0135, 0.0152, 0.0193, 0.0282,
            0.0202, -0.0007, 0.0134, -0.0187, 0.0377, -0.0073, 0.0021, 0.0248, 0.0085, 0.0537,
            -0.0035, 0.0273, 0.0207, -0.0023, 0.0311, 0.0168, 0.0353, 0.0359, 0.0623, 0.0454
        ]
        previewManager.rt60Value = 1.23
        return ImpulseResponseView()
            .environmentObject(previewManager)
            .previewDevice("iPhone 14 Pro")
            .previewDisplayName("Impulse Response (RIR)")
    }
}

