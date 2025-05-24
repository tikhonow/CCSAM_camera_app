import SwiftUI
import MessageUI

struct SupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showMailComposer = false
    @State private var showMailAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Заголовок
                    VStack(spacing: 16) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Поддержка")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Мы всегда готовы помочь!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Контактная информация
                    VStack(spacing: 16) {
                        SupportCard(
                            icon: "envelope.fill",
                            title: "Email поддержки",
                            subtitle: "tikhonov.ruslan@example.com",
                            color: .blue
                        ) {
                            if MFMailComposeViewController.canSendMail() {
                                showMailComposer = true
                            } else {
                                showMailAlert = true
                            }
                        }
                        
                        SupportCard(
                            icon: "phone.fill",
                            title: "Телефон",
                            subtitle: "+7 (XXX) XXX-XX-XX",
                            color: .green
                        ) {
                            if let url = URL(string: "tel:+7XXXXXXXXXX") {
                                UIApplication.shared.open(url)
                            }
                        }
                        
                        SupportCard(
                            icon: "globe",
                            title: "Веб-сайт",
                            subtitle: "www.ccsam-camera.com",
                            color: .orange
                        ) {
                            if let url = URL(string: "https://www.example.com") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Часто задаваемые вопросы
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Часто задаваемые вопросы")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        FAQItem(
                            question: "Как сканировать комнату?",
                            answer: "Перейдите на вкладку 'Room', нажмите 'Начать сканирование' и медленно двигайтесь по комнате, направляя камеру на стены, окна и двери."
                        )
                        
                        FAQItem(
                            question: "Почему не сохраняются комнаты?",
                            answer: "Убедитесь, что у приложения есть разрешение на доступ к файлам, и что на устройстве достаточно свободного места."
                        )
                        
                        FAQItem(
                            question: "Как изменить единицы измерения?",
                            answer: "Откройте профиль пользователя, затем перейдите в 'Настройки' и выберите нужную единицу измерения."
                        )
                        
                        FAQItem(
                            question: "Поддерживается ли мое устройство?",
                            answer: "Приложение работает на устройствах с LiDAR: iPhone 12 Pro и новее, iPad Pro 2020 и новее."
                        )
                    }
                    .padding(.horizontal)
                    
                    // Системная информация
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Информация для диагностики")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 8) {
                            InfoRow(title: "Версия приложения", value: "1.0.0")
                            InfoRow(title: "Версия iOS", value: UIDevice.current.systemVersion)
                            InfoRow(title: "Модель устройства", value: UIDevice.current.model)
                            InfoRow(title: "LiDAR поддержка", value: ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) ? "Да" : "Нет")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Кнопка обратной связи
                    VStack(spacing: 12) {
                        Button {
                            if MFMailComposeViewController.canSendMail() {
                                showMailComposer = true
                            } else {
                                showMailAlert = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("Отправить отзыв")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        Button {
                            if let url = URL(string: "https://apps.apple.com/app/id1234567890") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "star.fill")
                                Text("Оценить в App Store")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Поддержка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showMailComposer) {
                MailComposeView()
            }
            .alert("Почта недоступна", isPresented: $showMailAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("На этом устройстве не настроена почта. Пожалуйста, напишите нам на tikhonov.ruslan@example.com")
            }
        }
    }
}

struct SupportCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.1))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(question)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(answer)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                    .transition(.opacity.combined(with: .slide))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct MailComposeView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients(["tikhonov.ruslan@example.com"])
        composer.setSubject("CCSAM Camera - Обратная связь")
        
        let deviceInfo = """
        
        ---
        Информация об устройстве:
        Приложение: CCSAM Camera v1.0.0
        iOS: \(UIDevice.current.systemVersion)
        Устройство: \(UIDevice.current.model)
        LiDAR: \(ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) ? "Поддерживается" : "Не поддерживается")
        """
        
        composer.setMessageBody("Здравствуйте!\n\nОпишите вашу проблему или предложение:\n\n\(deviceInfo)", isHTML: false)
        
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}

import ARKit

#Preview {
    SupportView()
} 