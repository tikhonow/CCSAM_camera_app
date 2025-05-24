import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showLicense = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Логотип и название приложения
                    VStack(spacing: 16) {
                        Image(systemName: "house.and.flag.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("CCSAM Camera")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Версия 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Описание приложения
                    VStack(alignment: .leading, spacing: 16) {
                        Text("О приложении")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("CCSAM Camera — это продвинутое приложение для 3D-сканирования помещений с использованием технологии LiDAR. Приложение позволяет создавать точные трехмерные модели комнат, измерять размеры объектов и сохранять результаты для дальнейшего использования.")
                            .font(.body)
                            .lineSpacing(4)
                        
                        Text("Основные возможности:")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            AboutFeatureRow(icon: "camera.fill", text: "3D-сканирование комнат с помощью LiDAR")
                            AboutFeatureRow(icon: "ruler.fill", text: "Точные измерения стен, окон и дверей")
                            AboutFeatureRow(icon: "square.and.arrow.down", text: "Сохранение и загрузка моделей комнат")
                            AboutFeatureRow(icon: "gear", text: "Настройка единиц измерения")
                            AboutFeatureRow(icon: "cube", text: "Интерактивный просмотр 3D-моделей")
                        }
                    }
                    .padding(.horizontal)
                    
                    // Информация о разработчике
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Разработчик")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Руслан Тихонов")
                                .font(.headline)
                            
                            Text("iOS разработчик, специализирующийся на технологиях дополненной реальности и компьютерного зрения.")
                                .font(.body)
                                .lineSpacing(4)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Кнопки действий
                    VStack(spacing: 12) {
                        Button {
                            showLicense = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("Лицензионное соглашение")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Благодарности
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Благодарности")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Особая благодарность Apple за предоставление RoomPlan API и SceneKit framework, которые сделали возможной разработку этого приложения.")
                            .font(.body)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal)
                    
                    // Копирайт
                    Text("© 2025 Руслан Тихонов. Все права защищены.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("О приложении")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showLicense) {
                LicenseView()
            }
        }
    }
}

struct AboutFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}

struct LicenseView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("ЛИЦЕНЗИОННОЕ СОГЛАШЕНИЕ")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                    
                    Group {
                        Text("1. ПРЕДОСТАВЛЕНИЕ ЛИЦЕНЗИИ")
                            .font(.headline)
                        
                        Text("Настоящим предоставляется лицензия на использование приложения CCSAM Camera в соответствии с условиями данного соглашения.")
                        
                        Text("2. ОГРАНИЧЕНИЯ")
                            .font(.headline)
                            .padding(.top, 12)
                        
                        Text("Вы не можете:\n• Воспроизводить, копировать или распространять приложение\n• Модифицировать или создавать производные работы\n• Использовать приложение в коммерческих целях без разрешения")
                        
                        Text("3. КОНФИДЕНЦИАЛЬНОСТЬ")
                            .font(.headline)
                            .padding(.top, 12)
                        
                        Text("Приложение обрабатывает данные 3D-сканирования локально на вашем устройстве. Никакие персональные данные не передаются третьим лицам.")
                        
                        Text("4. ОГРАНИЧЕНИЕ ОТВЕТСТВЕННОСТИ")
                            .font(.headline)
                            .padding(.top, 12)
                        
                        Text("Приложение предоставляется «как есть» без каких-либо гарантий. Разработчик не несет ответственности за любые прямые или косвенные убытки.")
                        
                        Text("5. ИЗМЕНЕНИЯ")
                            .font(.headline)
                            .padding(.top, 12)
                        
                        Text("Разработчик оставляет за собой право изменять условия данного соглашения. Продолжение использования приложения означает согласие с изменениями.")
                    }
                    .font(.body)
                    .lineSpacing(4)
                    
                    Text("Дата последнего обновления: 23 мая 2025 г.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 16)
                }
                .padding()
            }
            .navigationTitle("Лицензия")
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

#Preview {
    AboutView()
} 
