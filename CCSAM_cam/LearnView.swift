import SwiftUI

struct LearnView: View {
    @StateObject private var articleStore = ArticleStore()
    @State private var selectedCategory: String? = nil
    @State private var selectedArticle: Article? = nil
    @State private var showArticle = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Заголовок категории
                    Text("Акустика")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // Список статей
                    VStack(spacing: 16) {
                        ForEach(articleStore.articles) { article in
                            Button {
                                selectedArticle = article
                                showArticle = true
                            } label: {
                                ArticleCardView(article: article)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Обучение")
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                        Text("Browse")
                    }
                    .foregroundColor(.blue)
                }
            }
            .sheet(isPresented: $showArticle) {
                if let article = selectedArticle {
                    ArticleDetailView(article: article, isPresented: $showArticle)
                        .edgesIgnoringSafeArea(.bottom)
                }
            }
        }
    }
}

struct ArticleCardView: View {
    let article: Article
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Градиентное изображение
            articleBackground
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    Group {
                        if article.hasNotification {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Image(systemName: "exclamationmark")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )
                                .offset(x: -16, y: -16)
                        }
                    },
                    alignment: .topTrailing
                )
            
            // Текст под изображением
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(article.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // Градиентный фон для каждой статьи с иллюстрацией
    var articleBackground: some View {
        Group {
            if article.title.contains("акустическая") {
                // Акустическая камера (голубой)
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.cyan.opacity(0.5)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    ZStack {
                        // Стилизованное изображение микрофонов
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .offset(x: 100, y: -20)
                        
                        // Звуковые лучи
                        ForEach(0..<8) { i in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.6))
                                .frame(width: 20, height: 3)
                                .rotationEffect(.degrees(Double(i) * 45))
                                .offset(x: 100 + 50 * cos(Double(i) * .pi/4),
                                        y: -20 + 50 * sin(Double(i) * .pi/4))
                        }
                    }
                )
            } else if article.title.contains("Основы") {
                // Акустические измерения (зеленый)
                LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.6), Color.mint.opacity(0.4)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    ZStack {
                        // Стилизованное изображение волн
                        ForEach(0..<5) { i in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.7))
                                .frame(width: 80, height: 6)
                                .offset(x: -40 + Double(i) * 20, y: Double(i) * 25 - 50)
                        }
                    }
                )
            } else {
                // Интерпретация данных (оранжевый)
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.6), Color.yellow.opacity(0.4)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    ZStack {
                        // Стилизованное изображение графиков
                        ForEach(0..<4) { i in
                            VStack(spacing: 2) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.8))
                                    .frame(width: 10, height: 30 + Double(i) * 15)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 10, height: 2)
                            }
                            .offset(x: -50 + Double(i) * 35, y: 0)
                        }
                    }
                )
            }
        }
    }
}

struct ArticleDetailView: View {
    let article: Article
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Верхняя панель с заголовком и кнопкой "Done"
            HStack {
                Spacer()
                Text(article.title)
                    .font(.headline)
                Spacer()
                Button("Done") {
                    isPresented = false
                }
                .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.systemBackground))
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.gray.opacity(0.3)),
                alignment: .bottom
            )
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Главное изображение
                    articleBackground
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // Заголовок статьи
                    Text(article.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    // Подзаголовок
                    Text(article.subtitle)
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    // Содержание статьи
                    Text(article.content)
                        .font(.body)
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                }
            }
        }
        .background(Color(.systemBackground))
    }
    
    // Повторяем градиентный фон для детального вида
    var articleBackground: some View {
        Group {
            if article.title.contains("акустическая") {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.cyan.opacity(0.5)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .offset(x: 120, y: -20)
                        
                        ForEach(0..<8) { i in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.6))
                                .frame(width: 24, height: 4)
                                .rotationEffect(.degrees(Double(i) * 45))
                                .offset(x: 120 + 60 * cos(Double(i) * .pi/4),
                                        y: -20 + 60 * sin(Double(i) * .pi/4))
                        }
                    }
                )
            } else if article.title.contains("Основы") {
                LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.6), Color.mint.opacity(0.4)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    ZStack {
                        ForEach(0..<5) { i in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.7))
                                .frame(width: 100, height: 8)
                                .offset(x: -50 + Double(i) * 25, y: Double(i) * 30 - 60)
                        }
                    }
                )
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.6), Color.yellow.opacity(0.4)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    ZStack {
                        ForEach(0..<4) { i in
                            VStack(spacing: 3) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.8))
                                    .frame(width: 14, height: 40 + Double(i) * 20)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 14, height: 3)
                            }
                            .offset(x: -60 + Double(i) * 45, y: 0)
                        }
                    }
                )
            }
        }
    }
}

#Preview {
    LearnView()
} 