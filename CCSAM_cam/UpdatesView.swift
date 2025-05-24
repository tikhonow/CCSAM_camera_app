import SwiftUI

// Модель для информации об обновлении
struct UpdateInfo: Identifiable {
    let id = UUID()
    let version: String
    let title: String
    let releaseDate: Date
    let description: String
    let features: [String] // Упрощаем - просто массив строк
    let bugFixes: [String]
    let systemRequirements: String
    let downloadSize: String
    let isSecurityUpdate: Bool
}

// Состояния загрузки обновлений
enum UpdatesState {
    case loading
    case noUpdates
    case hasUpdates(UpdateInfo)
    case error(String)
}

struct UpdatesView: View {
    @State private var updatesState: UpdatesState = .loading
    @State private var showUpdateDetails = false
    @State private var automaticUpdates = true
    @State private var betaUpdates = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Настройки обновлений
                Section {
                    HStack {
                        Text("Автоматические обновления")
                        Spacer()
                        Text(automaticUpdates ? "Вкл" : "Выкл")
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Бета-обновления")
                        Spacer()
                        Text(betaUpdates ? "Вкл" : "Выкл")
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Содержимое обновления
                switch updatesState {
                case .loading:
                    loadingSection
                case .noUpdates:
                    noUpdatesSection
                case .hasUpdates(let updateInfo):
                    updateAvailableSection(updateInfo)
                case .error(let errorMessage):
                    errorSection(errorMessage)
                }
            }
            .navigationTitle("Обновления")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadUpdates()
            }
            .sheet(isPresented: $showUpdateDetails) {
                if case .hasUpdates(let updateInfo) = updatesState {
                    UpdateDetailsView(updateInfo: updateInfo)
                }
            }
        }
    }
    
    // MARK: - Loading Section
    private var loadingSection: some View {
        Section {
            HStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                
                Text("Проверка обновлений...")
                    .padding(.leading, 12)
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - No Updates Section
    private var noUpdatesSection: some View {
        Section {
            VStack(alignment: .center, spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
                
                Text("CCSAM Camera обновлена")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text("Версия 1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Ваше устройство обновлено до последней версии")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Update Available Section
    private func updateAvailableSection(_ updateInfo: UpdateInfo) -> some View {
        Section {
            VStack(spacing: 0) {
                // Иконка и информация о версии
                HStack(spacing: 16) {
                    // Простая иконка версии в стиле iOS
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                        
                        VStack(spacing: 2) {
                            Text(updateInfo.version.split(separator: ".").first.map(String.init) ?? "1")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text(updateInfo.version.split(separator: ".").dropFirst().joined(separator: "."))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CCSAM Camera \(updateInfo.version)")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Text(updateInfo.downloadSize)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 16)
                
                // Описание обновления
                VStack(alignment: .leading, spacing: 12) {
                    Text(updateInfo.description)
                        .font(.subheadline)
                        .lineSpacing(4)
                    
                    if updateInfo.isSecurityUpdate {
                        Text("Информацию о содержимом безопасности обновлений CCSAM Camera можно найти по адресу:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("https://support.ccsam.com/security")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 20)
                
                // Кнопка "Подробнее"
                HStack {
                    Button {
                        showUpdateDetails = true
                    } label: {
                        Text("Подробнее...")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 24)
                
                // Кнопки обновления
                VStack(spacing: 12) {
                    Button {
                        print("Обновить сейчас...")
                    } label: {
                        Text("Обновить сейчас")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    
                    Button {
                        print("Обновить сегодня ночью...")
                    } label: {
                        Text("Обновить сегодня ночью")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.clear)
                            .cornerRadius(10)
                    }
                }
                .padding(.bottom, 16)
                
                // Пояснение для ночного обновления
                Text("Если вы выберете «Обновить сегодня ночью», устройство попытается выполнить обновление, когда оно будет заблокировано и у него будет достаточный заряд аккумулятора.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Error Section
    private func errorSection(_ message: String) -> some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                
                Text("Ошибка проверки обновлений")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button {
                    loadUpdates()
                } label: {
                    Text("Повторить")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Helper Methods
    private func loadUpdates() {
        updatesState = .loading
        
        // Имитируем 5-секундную загрузку
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            // По умолчанию показываем "нет обновлений"
            updatesState = .noUpdates
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
}

// MARK: - Update Details View (упрощенный)
struct UpdateDetailsView: View {
    let updateInfo: UpdateInfo
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text(updateInfo.description)
                        .font(.body)
                        .lineSpacing(4)
                } header: {
                    Text("Описание обновления")
                }
                
                if !updateInfo.features.isEmpty {
                    Section {
                        ForEach(Array(updateInfo.features.enumerated()), id: \.offset) { index, feature in
                            Text("• \(feature)")
                                .font(.subheadline)
                                .lineSpacing(2)
                        }
                    } header: {
                        Text("Что нового")
                    }
                }
                
                if !updateInfo.bugFixes.isEmpty {
                    Section {
                        ForEach(Array(updateInfo.bugFixes.enumerated()), id: \.offset) { index, fix in
                            Text("• \(fix)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineSpacing(2)
                        }
                    } header: {
                        Text("Исправления ошибок")
                    }
                }
                
                Section {
                    HStack {
                        Text("iOS:")
                        Spacer()
                        Text(updateInfo.systemRequirements)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Размер:")
                        Spacer()
                        Text(updateInfo.downloadSize)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Совместимость:")
                        Spacer()
                        Text("iPhone, iPad")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Информация")
                }
            }
            .navigationTitle("Подробности")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview Provider
struct UpdatesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Состояние загрузки
            UpdatesView()
                .previewDisplayName("Загрузка")
            
            // Есть обновление
            UpdatesViewWithUpdate()
                .previewDisplayName("Доступно обновление")
        }
    }
}

// Вспомогательный View для preview с обновлением
private struct UpdatesViewWithUpdate: View {
    @State private var updatesState: UpdatesState = .hasUpdates(sampleUpdateInfo)
    @State private var showUpdateDetails = false
    @State private var automaticUpdates = true
    @State private var betaUpdates = false
    
    var body: some View {
        NavigationView {
            List {
                
                if case .hasUpdates(let updateInfo) = updatesState {
                    Section {
                        VStack(spacing: 0) {
                            // Иконка и информация о версии
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(LinearGradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 60, height: 60)
                                    
                                    VStack(spacing: 2) {
                                        Text("1")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        Text("1.0")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("CCSAM Camera \(updateInfo.version)")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                    
                                    Text(updateInfo.downloadSize)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.bottom, 16)
                            
                            // Описание обновления
                            VStack(alignment: .leading, spacing: 12) {
                                Text(updateInfo.description)
                                    .font(.subheadline)
                                    .lineSpacing(4)
                                
                                if updateInfo.isSecurityUpdate {
                                    Text("Информацию о содержимом безопасности обновлений CCSAM Camera можно найти по адресу:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("https://support.ccsam.com/security")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 20)
                            
                            // Кнопка "Подробнее"
                            HStack {
                                Button { showUpdateDetails = true } label: {
                                    Text("Подробнее...")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                                Spacer()
                            }
                            .padding(.bottom, 24)
                            
                            // Кнопки обновления
                            VStack(spacing: 12) {
                                Button { } label: {
                                    Text("Обновить сейчас")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(10)
                                }
                                
                            }
                            .padding(.bottom, 16)
                            
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationTitle("Обновления")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {}
                }
            }
            .sheet(isPresented: $showUpdateDetails) {
                if case .hasUpdates(let updateInfo) = updatesState {
                    UpdateDetailsView(updateInfo: updateInfo)
                }
            }
        }
    }


// Пример данных для preview (упрощенный)
private let sampleUpdateInfo = UpdateInfo(
    version: "1.1.0",
    title: "Новые возможности и исправления ошибок",
    releaseDate: Date(),
    description: "Это обновление содержит новые возможности, исправления ошибок и обновления безопасности для вашего устройства.",
    features: [
        "Улучшенный алгоритм 3D-сканирования с повышенной точностью",
        "Поддержка новых форматов экспорта моделей",
        "Улучшенная производительность при работе с большими помещениями",
        "Новые инструменты для измерения расстояний"
    ],
    bugFixes: [
        "Исправлена ошибка с сохранением размеров окон",
        "Устранены проблемы с производительностью",
        "Исправлена ошибка с единицами измерения",
        "Улучшена стабильность приложения"
    ],
    systemRequirements: "iOS 15.0+",
    downloadSize: "45.2 МБ",
    isSecurityUpdate: true
) 
