import SwiftUI
import Foundation

// Enum для единиц измерения
enum MeasurementUnit: String, CaseIterable, Identifiable {
    case meters = "Метры"
    case feet = "Футы"
    case inches = "Дюймы"
    case centimeters = "Сантиметры"
    
    var id: String { rawValue }
    
    var symbol: String {
        switch self {
        case .meters: return "м"
        case .feet: return "фт"
        case .inches: return "дюйм"
        case .centimeters: return "см"
        }
    }
    
    var shortSymbol: String {
        switch self {
        case .meters: return "м"
        case .feet: return "ft"
        case .inches: return "in"
        case .centimeters: return "см"
        }
    }
    
    // Коэффициенты конвертации из метров
    var conversionFactor: Float {
        switch self {
        case .meters: return 1.0
        case .feet: return 3.28084
        case .inches: return 39.3701
        case .centimeters: return 100.0
        }
    }
}

// Менеджер настроек приложения
class SettingsManager: ObservableObject {
    @Published var measurementUnit: MeasurementUnit {
        didSet {
            UserDefaults.standard.set(measurementUnit.rawValue, forKey: "measurementUnit")
        }
    }
    
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }
    
    init() {
        // Загружаем сохраненные настройки
        let savedUnit = UserDefaults.standard.string(forKey: "measurementUnit") ?? MeasurementUnit.meters.rawValue
        self.measurementUnit = MeasurementUnit(rawValue: savedUnit) ?? .meters
        
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    }
    
    // Конвертация значения из метров в выбранную единицу измерения
    func convert(value: Float) -> Float {
        return value * measurementUnit.conversionFactor
    }
    
    // Форматирование размера с учетом единиц измерения
    func formatDimension(_ value: Float) -> String {
        let convertedValue = convert(value: value)
        return String(format: "%.2f %@", convertedValue, measurementUnit.shortSymbol)
    }
    
    // Форматирование размеров (ширина x высота)
    func formatDimensions(width: Float, height: Float) -> String {
        let convertedWidth = convert(value: width)
        let convertedHeight = convert(value: height)
        return String(format: "%.2f x %.2f %@", convertedWidth, convertedHeight, measurementUnit.shortSymbol)
    }
    
    // Сброс настроек к значениям по умолчанию
    func resetToDefaults() {
        measurementUnit = .meters
        isDarkMode = false
        notificationsEnabled = true
    }
} 