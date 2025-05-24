import SwiftUI

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
    LicenseView()
} 