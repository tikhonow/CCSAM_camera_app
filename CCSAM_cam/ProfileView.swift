import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsManager: SettingsManager
    @State private var showSettings = false
    @State private var showAbout = false
    @State private var showSupport = false
    @State private var showUpdatesView = false
    
    var body: some View {
        NavigationView {
            List {
                // Секция профиля
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Пользователь")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("CCSAM Camera App")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // Основные разделы
                Section {
                    Button {
                        showSettings = true
                    } label: {
                        ProfileRowView(
                            icon: "gear",
                            title: "Настройки",
                            subtitle: "Единицы измерения и другие настройки",
                            color: .blue
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        showUpdatesView = true
                    } label: {
                        ProfileRowView(
                            icon: "arrow.down.circle",
                            title: "Обновления",
                            subtitle: "Проверить наличие обновлений приложения",
                            color: .purple
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        showAbout = true
                    } label: {
                        ProfileRowView(
                            icon: "info.circle",
                            title: "О приложении",
                            subtitle: "Информация и лицензионное соглашение",
                            color: .green
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        showSupport = true
                    } label: {
                        ProfileRowView(
                            icon: "envelope",
                            title: "Поддержка",
                            subtitle: "Связаться с разработчиком",
                            color: .orange
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Информационная секция
                Section {
                    HStack {
                        Text("Версия приложения")
                        Spacer()
                        Text(AppConstants.appVersion)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Единицы измерения")
                        Spacer()
                        Text(settingsManager.measurementUnit.rawValue)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Информация")
                }
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(settingsManager)
            }
            .sheet(isPresented: $showUpdatesView) {
                UpdatesView()
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .sheet(isPresented: $showSupport) {
                SupportView()
            }
        }
    }
}

struct ProfileRowView: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ProfileView()
        .environmentObject(SettingsManager())
} 
