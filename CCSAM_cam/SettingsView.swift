import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsManager: SettingsManager
    @State private var showResetAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Секция единиц измерения
                Section {
                    ForEach(MeasurementUnit.allCases) { unit in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(unit.rawValue)
                                    .font(.headline)
                                
                                Text("Символ: \(unit.symbol)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if settingsManager.measurementUnit == unit {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                                    .font(.headline)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                settingsManager.measurementUnit = unit
                            }
                        }
                    }
                } header: {
                    Label("Единицы измерения", systemImage: "ruler")
                } footer: {
                    Text("Выберите единицы измерения для отображения размеров комнат и объектов")
                        .font(.caption)
                }
                
                // Секция внешнего вида
                Section {
                    Toggle(isOn: $settingsManager.isDarkMode) {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.purple)
                                .frame(width: 24, height: 24)
                            
                            Text("Темный режим")
                        }
                    }
                    
                    Toggle(isOn: $settingsManager.notificationsEnabled) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                                .frame(width: 24, height: 24)
                            
                            Text("Уведомления")
                        }
                    }
                } header: {
                    Label("Внешний вид и уведомления", systemImage: "paintbrush")
                }
                
                // Секция предварительного просмотра
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Пример размеров:")
                            .font(.headline)
                        
                        HStack {
                            Text("Стена:")
                            Spacer()
                            Text(settingsManager.formatDimensions(width: 3.5, height: 2.4))
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text("Окно:")
                            Spacer()
                            Text(settingsManager.formatDimensions(width: 1.2, height: 1.5))
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text("Дверь:")
                            Spacer()
                            Text(settingsManager.formatDimensions(width: 0.9, height: 2.1))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Label("Предварительный просмотр", systemImage: "eye")
                } footer: {
                    Text("Так будут отображаться размеры в приложении")
                        .font(.caption)
                }
                
                // Секция действий
                Section {
                    Button {
                        showResetAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.red)
                            
                            Text("Сбросить настройки")
                                .foregroundColor(.red)
                        }
                    }
                } footer: {
                    Text("Это действие вернет все настройки к значениям по умолчанию")
                        .font(.caption)
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
            .alert("Сбросить настройки", isPresented: $showResetAlert) {
                Button("Отмена", role: .cancel) {}
                Button("Сбросить", role: .destructive) {
                    withAnimation {
                        settingsManager.resetToDefaults()
                    }
                }
            } message: {
                Text("Вы уверены, что хотите сбросить все настройки к значениям по умолчанию?")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager())
} 