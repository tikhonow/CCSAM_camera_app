import SwiftUI

struct WhatsNewView: View {
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Фоновый градиент
            backgroundGradient
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                Text("Что нового в")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("CCSAM Camera")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Контейнер со списком функций
                VStack(spacing: 30) {
                    FeatureRow(
                        icon: "waveform",
                        iconColor: .blue,
                        title: "Анализ импульсного отклика",
                        description: "Исследуйте акустические параметры RT60, EDT, ясность и другие характеристики помещения."
                    )
                    
                    FeatureRow(
                        icon: "camera",
                        iconColor: .purple,
                        title: "Акустические снимки",
                        description: "Создавайте визуальную карту акустических характеристик комнаты с помощью снимков."
                    )
                    
                    FeatureRow(
                        icon: "house.fill",
                        iconColor: .green,
                        title: "Сканирование помещений",
                        description: "Используйте LiDAR для создания 3D-модели помещения и измерения его акустических свойств."
                    )
                    
                    FeatureRow(
                        icon: "mic.fill",
                        iconColor: .red,
                        title: "Запись с микрофона",
                        description: "Записывайте аудио через встроенный микрофон для проведения измерений без внешних устройств."
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Информация о политике конфиденциальности
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ваши данные измерений хранятся только на вашем устройстве")
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.secondary)
                        
                        Text("Подробнее о конфиденциальности...")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                // Кнопка продолжить
                Button {
                    isPresented = false
                } label: {
                    Text("Продолжить")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .padding(.horizontal)
        }
    }
    
    // Градиент для фона, адаптивный к темной теме
    private var backgroundGradient: some View {
        let colors = colorScheme == .dark ? 
            [Color.black, Color(UIColor.darkGray)] : 
            [Color.white, Color(UIColor.systemGray6)]
        
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct FeatureRow: View {
    let icon: String
    var iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

struct WhatsNewView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WhatsNewView(isPresented: .constant(true))
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            WhatsNewView(isPresented: .constant(true))
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
} 
