import SwiftUI
import RoomPlan
import ARKit
import QuickLook
import ModelIO
import SceneKit
import SceneKit.ModelIO

// Сервис для хранения данных о комнате
class RoomDataManager: ObservableObject {
    @Published var savedRooms: [SavedRoom] = []
    private let savedRoomsKey = "savedRoomsIndex"
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let isFirstLaunchKey = "RoomDataManagerFirstLaunch"
    
    init() {
        // Проверяем, доступны ли защищенные данные (устройство разблокировано)
        if #available(iOS 14.0, *), !UIApplication.shared.isProtectedDataAvailable {
            print("RoomDataManager: Защищенные данные недоступны, ожидание разблокировки устройства")
            
            // Подписываемся на уведомление о разблокировке устройства
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(protectedDataDidBecomeAvailable),
                name: UIApplication.protectedDataDidBecomeAvailableNotification,
                object: nil
            )
        } else {
            // Устройство разблокировано, загружаем данные
            loadRooms()
        }
    }
    
    @objc private func protectedDataDidBecomeAvailable() {
        print("RoomDataManager: Защищенные данные стали доступны, загружаем комнаты")
        loadRooms()
        
        // Отписываемся от уведомления
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.protectedDataDidBecomeAvailableNotification,
            object: nil
        )
    }
    
    // Сохранить новую комнату
    func saveRoom(_ capturedRoom: CapturedRoom, name: String = "Новая комната") {
        let id = UUID()
        let newSavedRoom = SavedRoom(
            id: id,
            name: name,
            date: Date(),
            surfaces: surfacesFromRoom(capturedRoom)
        )
        
        // Сохраняем модель комнаты в файл
        saveCapturedRoomToFile(capturedRoom, with: id)
        
        // Добавляем информацию о комнате в список
        savedRooms.append(newSavedRoom)
        saveRoomsToStorage()
    }
    
    // Принудительно сохранить изменения на диск
    func forceSynchronize() {
        let currentRooms = savedRooms
        UserDefaults.standard.synchronize() // Для старых версий iOS
        
        // Дополнительная защита - перезагружаем после сохранения
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Проверяем, не потерялись ли данные
            let savedData = UserDefaults.standard.data(forKey: self.savedRoomsKey)
            if savedData == nil && !currentRooms.isEmpty {
                print("RoomDataManager: Данные не сохранились, повторяем сохранение")
                self.savedRooms = currentRooms
                self.saveRoomsToStorage()
            }
        }
    }
    
    // Сохраняем CapturedRoom в файл на диске
    private func saveCapturedRoomToFile(_ room: CapturedRoom, with id: UUID) {
        let roomURL = documentsDirectory.appendingPathComponent("room_\(id.uuidString).usdz")
        
        do {
            try room.export(to: roomURL)
            print("Комната успешно сохранена в: \(roomURL.path)")
        } catch {
            print("Ошибка при сохранении комнаты в файл: \(error.localizedDescription)")
        }
    }
    
    // Загрузить CapturedRoom из файла
    func loadCapturedRoom(with id: UUID) -> CapturedRoom? {
        let roomURL = documentsDirectory.appendingPathComponent("room_\(id.uuidString).usdz")
        
        // В текущем API RoomPlan нет прямого способа загрузить CapturedRoom из файла
        // Здесь нужно было бы использовать API для загрузки модели из USDZ
        // В этом примере мы возвращаем заглушку
        
        return nil // В реальном приложении здесь должна быть загрузка модели
    }
    
    // Загрузить комнаты из хранилища
    private func loadRooms() {
        guard let roomsData = UserDefaults.standard.data(forKey: savedRoomsKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            let roomIndexes = try decoder.decode([SavedRoom].self, from: roomsData)
            self.savedRooms = roomIndexes
            print("RoomDataManager: Загружено \(roomIndexes.count) комнат")
        } catch {
            print("Ошибка при загрузке комнат: \(error.localizedDescription)")
        }
    }
    
    // Сохранить комнаты в хранилище
    func saveRoomsToStorage() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(savedRooms)
            UserDefaults.standard.set(data, forKey: savedRoomsKey)
            print("RoomDataManager: Сохранено \(savedRooms.count) комнат")
            forceSynchronize()
        } catch {
            print("Ошибка при сохранении комнат: \(error.localizedDescription)")
        }
    }
    
    // Удалить комнату
    func deleteRoom(at indexSet: IndexSet) {
        // Удаляем файлы комнат
        for index in indexSet {
            if index < savedRooms.count {
                let roomToDelete = savedRooms[index]
                let fileURL = documentsDirectory.appendingPathComponent("room_\(roomToDelete.id.uuidString).usdz")
                
                do {
                    try FileManager.default.removeItem(at: fileURL)
                    print("Удален файл комнаты: \(fileURL.path)")
                } catch {
                    print("Не удалось удалить файл комнаты: \(error.localizedDescription)")
                }
            }
        }
        
        // Удаляем записи о комнатах
        savedRooms.remove(atOffsets: indexSet)
        saveRoomsToStorage()
    }
    
    // Получить поверхности из комнаты
    private func surfacesFromRoom(_ room: CapturedRoom) -> [SurfaceViewModel] {
        var surfaces = [SurfaceViewModel]()
        
        // Добавляем все стены
        surfaces.append(contentsOf: room.walls.map { SurfaceViewModel(surface: $0) })
        
        // Добавляем все окна
        surfaces.append(contentsOf: room.windows.map { SurfaceViewModel(surface: $0) })
        
        // Добавляем все двери
        surfaces.append(contentsOf: room.doors.map { SurfaceViewModel(surface: $0) })
        
        // Добавляем все проемы
        surfaces.append(contentsOf: room.openings.map { SurfaceViewModel(surface: $0) })
        
        return surfaces
    }
    
    // Обновить поверхность и сохранить изменения
    func updateSurface(_ surface: SurfaceViewModel, in roomId: UUID?) {
        guard let roomId = roomId,
              let roomIndex = savedRooms.firstIndex(where: { $0.id == roomId }) else { return }
        
        // Находим индекс поверхности в комнате
        if let surfaceIndex = savedRooms[roomIndex].surfaces.firstIndex(where: { $0.id == surface.id }) {
            // Обновляем поверхность
            savedRooms[roomIndex].surfaces[surfaceIndex] = surface
            
            // Сохраняем изменения
            saveRoomsToStorage()
            
            print("RoomDataManager: Обновлена поверхность \(surface.name) в комнате \(savedRooms[roomIndex].name)")
        }
    }
}

// Модель для сохраненной комнаты
class SavedRoom: Identifiable, Codable, ObservableObject {
    let id: UUID
    @Published var name: String
    let date: Date
    @Published var surfaces: [SurfaceViewModel]
    
    // Сохраняем основные параметры комнаты для случая, когда файл недоступен
    var roomWidth: Float = 0
    var roomHeight: Float = 0
    var roomLength: Float = 0
    var wallCount: Int = 0
    var windowCount: Int = 0
    var doorCount: Int = 0
    
    // CapturedRoom загружаем динамически из файла
    var capturedRoom: CapturedRoom? {
        let roomDataManager = RoomDataManager()
        return roomDataManager.loadCapturedRoom(with: id)
    }
    
    // Требуется для Codable
    enum CodingKeys: String, CodingKey {
        case id, name, date, surfaces, roomWidth, roomHeight, roomLength, wallCount, windowCount, doorCount
    }
    
    // Декодирование
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        date = try container.decode(Date.self, forKey: .date)
        surfaces = try container.decode([SurfaceViewModel].self, forKey: .surfaces)
        roomWidth = try container.decode(Float.self, forKey: .roomWidth)
        roomHeight = try container.decode(Float.self, forKey: .roomHeight)
        roomLength = try container.decode(Float.self, forKey: .roomLength)
        wallCount = try container.decode(Int.self, forKey: .wallCount)
        windowCount = try container.decode(Int.self, forKey: .windowCount)
        doorCount = try container.decode(Int.self, forKey: .doorCount)
    }
    
    // Кодирование
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(date, forKey: .date)
        try container.encode(surfaces, forKey: .surfaces)
        try container.encode(roomWidth, forKey: .roomWidth)
        try container.encode(roomHeight, forKey: .roomHeight)
        try container.encode(roomLength, forKey: .roomLength)
        try container.encode(wallCount, forKey: .wallCount)
        try container.encode(windowCount, forKey: .windowCount)
        try container.encode(doorCount, forKey: .doorCount)
    }
    
    init(id: UUID, name: String, date: Date, surfaces: [SurfaceViewModel]) {
        self.id = id
        self.name = name
        self.date = date
        self.surfaces = surfaces
        
        // Вычисляем основные параметры комнаты
        self.wallCount = surfaces.filter { $0.surfaceCategory == 0 }.count
        self.windowCount = surfaces.filter { $0.surfaceCategory == 1 }.count
        self.doorCount = surfaces.filter { $0.surfaceCategory == 2 }.count
        
        // Вычисляем примерные размеры комнаты по поверхностям
        let walls = surfaces.filter { $0.surfaceCategory == 0 }
        if !walls.isEmpty {
            let xDimensions = walls.map { $0.dimensionX }
            let yDimensions = walls.map { $0.dimensionY }
            
            if let maxX = xDimensions.max(), let maxY = yDimensions.max() {
                self.roomWidth = maxX
                self.roomHeight = maxY
            }
        }
    }
}

// Модель для представления данных о поверхности
class SurfaceViewModel: Identifiable, Codable, ObservableObject {
    let id = UUID()
    @Published var name: String
    @Published var notes: String
    
    // Эти свойства нельзя сериализовать через Codable, храним их отдельно
    var surfaceCategory: Int
    var dimensionX: Float
    var dimensionY: Float
    var transform: [Float]
    
    func dimensions(using settingsManager: SettingsManager) -> String {
        return settingsManager.formatDimensions(width: dimensionX, height: dimensionY)
    }
    
    var dimensions: String {
        return String(format: "%.2f x %.2f м", dimensionX, dimensionY)
    }
    
    var type: String {
        switch surfaceCategory {
        case 0: return "Стена"
        case 1: return "Окно"
        case 2: return "Дверь"
        case 3: return "Проем"
        default: return "Неизвестно"
        }
    }
    
    // Требуется для Codable
    enum CodingKeys: String, CodingKey {
        case id, name, notes, surfaceCategory, dimensionX, dimensionY, transform
    }
    
    // Декодирование
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // id уже определен как let
        name = try container.decode(String.self, forKey: .name)
        notes = try container.decode(String.self, forKey: .notes)
        surfaceCategory = try container.decode(Int.self, forKey: .surfaceCategory)
        dimensionX = try container.decode(Float.self, forKey: .dimensionX)
        dimensionY = try container.decode(Float.self, forKey: .dimensionY)
        transform = try container.decode([Float].self, forKey: .transform)
    }
    
    // Кодирование
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(notes, forKey: .notes)
        try container.encode(surfaceCategory, forKey: .surfaceCategory)
        try container.encode(dimensionX, forKey: .dimensionX)
        try container.encode(dimensionY, forKey: .dimensionY)
        try container.encode(transform, forKey: .transform)
    }
    
    init(surface: CapturedRoom.Surface, name: String = "", notes: String = "") {
        self.name = name
        self.notes = notes
        
        // Сохраняем только необходимые данные
        self.dimensionX = surface.dimensions.x
        self.dimensionY = surface.dimensions.y
        
        // Преобразуем category в Int для Codable
        switch surface.category {
        case .wall: self.surfaceCategory = 0
        case .window: self.surfaceCategory = 1
        case .door: self.surfaceCategory = 2
        case .opening: self.surfaceCategory = 3
        @unknown default: self.surfaceCategory = -1
        }
        
        // Преобразуем матрицу трансформации в массив
        let matrix = surface.transform
        transform = [
            matrix.columns.0.x, matrix.columns.0.y, matrix.columns.0.z, matrix.columns.0.w,
            matrix.columns.1.x, matrix.columns.1.y, matrix.columns.1.z, matrix.columns.1.w,
            matrix.columns.2.x, matrix.columns.2.y, matrix.columns.2.z, matrix.columns.2.w,
            matrix.columns.3.x, matrix.columns.3.y, matrix.columns.3.z, matrix.columns.3.w
        ]
    }
}

// Тип уведомления
enum NotificationType: Equatable {
    case error
    case warning
    case info
    
    var color: Color {
        switch self {
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .error: return "exclamationmark.triangle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

// Структура уведомления
struct ScanningNotification: Identifiable, Equatable {
    let id = UUID()
    let type: NotificationType
    let message: String
    let timestamp = Date()
    
    // Реализация Equatable
    static func == (lhs: ScanningNotification, rhs: ScanningNotification) -> Bool {
        lhs.id == rhs.id
    }
}

// Вид для отображения уведомления
struct NotificationBanner: View {
    let notification: ScanningNotification
    
    var body: some View {
        HStack {
            Image(systemName: notification.type.icon)
                .foregroundColor(notification.type.color)
            
            Text(notification.message)
                .font(.subheadline)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}

// Основной экран для сканирования комнаты
struct RoomScanView: View {
    @State private var showScanner = false
    @State private var scannedRoom: CapturedRoom?
    @State private var selectedSurface: SurfaceViewModel?
    @State private var roomName = "Новая комната"
    @State private var showSaveDialog = false
    // Используем один общий экземпляр RoomDataManager для всего приложения
    @StateObject private var roomDataManager = RoomDataManager()
    @State private var showSavedRooms = false
    @State private var notifications: [ScanningNotification] = []
    @State private var showingMetadataOnly = false
    @State private var selectedSavedRoom: SavedRoom? = nil
    
    // Проверка наличия сохраненных данных при запуске
    init() {
        // Этот инициализатор используется для логирования, но нам не нужно здесь ничего делать,
        // т.к. StateObject будет инициализирован автоматически
    }
    
    func showNotification(_ message: String, _ type: NotificationType) {
        let notification = ScanningNotification(type: type, message: message)
        notifications.append(notification)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            notifications.removeAll { $0.id == notification.id }
        }
    }
    
    var notificationsView: some View {
        VStack {
            ForEach(notifications) { notification in
                NotificationBanner(notification: notification)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if let room = scannedRoom {
                    RoomResultView(room: room, selectedSurface: $selectedSurface, showNotification: showNotification)
                } else if showingMetadataOnly, let room = selectedSavedRoom {
                    MetadataRoomView(savedRoom: room, showNotification: showNotification)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Сканирование комнаты")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Используйте LiDAR для создания 3D модели вашей комнаты")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button {
                            showScanner = true
                        } label: {
                            Text("Начать сканирование")
                                .font(.headline)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top, 20)
                        
                        if !roomDataManager.savedRooms.isEmpty {
                            Button {
                                showSavedRooms = true
                            } label: {
                                Text("Мои сохраненные комнаты (\(roomDataManager.savedRooms.count))")
                                    .font(.headline)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.top, 10)
                        }
                    }
                    .padding()
                }
                
                // Отображение уведомлений
                notificationsView
                    .animation(.easeInOut, value: notifications.map { $0.id })
            }
            .navigationTitle("Room Scanner")
            .toolbar {
                if scannedRoom != nil || showingMetadataOnly {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Мои комнаты") {
                            showSavedRooms = true
                        }
                    }
                    
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        if scannedRoom != nil {
                        Button("Сохранить") {
                            showSaveDialog = true
                            }
                        }
                        
                        Button("Новое сканирование") {
                            showScanner = true
                            showingMetadataOnly = false
                            selectedSavedRoom = nil
                        }
                    }
                }
            }
            .sheet(isPresented: $showScanner) {
                ARRoomCaptureView(isPresented: $showScanner, scannedRoom: $scannedRoom, showNotification: showNotification)
                    .edgesIgnoringSafeArea(.all)
            }
            .sheet(item: $selectedSurface) { surface in
                SurfaceDetailView(surface: surface, dataManager: roomDataManager)
                    .onDisappear {
                        // Перезагружаем данные для обновления UI
                        if showingMetadataOnly {
                            let currentRoomId = selectedSavedRoom?.id
                            // Находим обновленную комнату
                            if let roomId = currentRoomId,
                               let updatedRoom = roomDataManager.savedRooms.first(where: { $0.id == roomId }) {
                                selectedSavedRoom = updatedRoom
                            }
                        }
                    }
            }
            .sheet(isPresented: $showSavedRooms) {
                SavedRoomsView(rooms: $roomDataManager.savedRooms, dataManager: roomDataManager, onSelect: { savedRoom in
                    if let loadedRoom = savedRoom.capturedRoom {
                        scannedRoom = loadedRoom
                        showingMetadataOnly = false
                        selectedSavedRoom = nil
                    } else {
                        // Если не удалось загрузить полную модель, показываем только метаданные
                        scannedRoom = nil
                        showingMetadataOnly = true
                        selectedSavedRoom = savedRoom
                        showNotification("Загружены только метаданные комнаты", .info)
                    }
                    showSavedRooms = false
                })
            }
            .alert("Сохранить комнату", isPresented: $showSaveDialog) {
                TextField("Название комнаты", text: $roomName)
                Button("Отмена", role: .cancel) {}
                Button("Сохранить") {
                    if let room = scannedRoom {
                        roomDataManager.saveRoom(room, name: roomName)
                        showNotification("Комната успешно сохранена", .info)
                    }
                }
            } message: {
                Text("Введите название для сохранения комнаты")
            }
        }
    }
}

// Представление списка сохраненных комнат
struct SavedRoomsView: View {
    @Binding var rooms: [SavedRoom]
    var dataManager: RoomDataManager
    var onSelect: (SavedRoom) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var selectedRoom: SavedRoom? = nil
    @State private var showLoadingError = false
    
    var body: some View {
        NavigationView {
            ZStack {
            List {
                ForEach(rooms) { room in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(room.name)
                                .font(.headline)
                            
                            Text(formattedDate(room.date))
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("\(room.surfaces.count) объектов")
                                .font(.caption)
                                .foregroundColor(.gray)
                                
                                Text("Стены: \(room.wallCount), Окна: \(room.windowCount), Двери: \(room.doorCount)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button {
                                loadRoom(room)
                        } label: {
                            Text("Открыть")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                            loadRoom(room)
                    }
                }
                .onDelete { indexSet in
                        dataManager.deleteRoom(at: indexSet)
                    }
                }
                
                if isLoading {
                    ProgressView("Загрузка комнаты...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
            .navigationTitle("Сохраненные комнаты")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
            .alert("Ошибка загрузки", isPresented: $showLoadingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Не удалось загрузить модель комнаты. Файл может быть поврежден или удален. Доступен только просмотр метаданных.")
            }
        }
    }
    
    private func loadRoom(_ room: SavedRoom) {
        isLoading = true
        selectedRoom = room
        
        // Поскольку мы не можем загрузить полную CapturedRoom из файла в данный момент,
        // всегда показываем метаданные комнаты
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            
            // Здесь всегда открываем комнату даже без 3D-модели
            // В будущем можно реализовать проверку на наличие файла
            onSelect(room)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Контейнер для RoomCaptureViewController
struct ARRoomCaptureView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var scannedRoom: CapturedRoom?
    var showNotification: (String, NotificationType) -> Void
    
    func makeUIViewController(context: Context) -> RoomCaptureViewController {
        let controller = RoomCaptureViewController()
        controller.delegate = context.coordinator
        controller.showNotification = showNotification
        return controller
    }
    
    func updateUIViewController(_ uiViewController: RoomCaptureViewController, context: Context) {
        // Обновление не требуется
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, RoomCaptureViewControllerDelegate {
        var parent: ARRoomCaptureView
        
        init(parent: ARRoomCaptureView) {
            self.parent = parent
        }
        
        func captureViewController(_ viewController: RoomCaptureViewController, didFinishWith result: CapturedRoom?) {
            DispatchQueue.main.async {
                if let room = result {
                    print("Получена модель комнаты")
                    self.parent.scannedRoom = room
                    // Сохраняем результат для предотвращения потери при закрытии
                    UserDefaults.standard.set(true, forKey: "hasScannedRoom")
                } else {
                    print("Не удалось получить модель комнаты")
                }
                self.parent.isPresented = false
            }
        }
    }
}

// Кастомный контроллер для RoomPlan
class RoomCaptureViewController: UIViewController, RoomCaptureViewDelegate, RoomCaptureSessionDelegate {
    private var roomCaptureView: RoomCaptureView!
    private var roomCaptureSession: RoomCaptureSession!
    private var roomBuilder: RoomBuilder!
    private var activityIndicator: UIActivityIndicatorView!
    weak var delegate: RoomCaptureViewControllerDelegate?
    var showNotification: ((String, NotificationType) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRoomCaptureView()
        setupActivityIndicator()
        setupCloseButton()
        setupDoneButton()
    }
    
    private func setupRoomCaptureView() {
        roomCaptureView = RoomCaptureView(frame: view.bounds)
        roomCaptureView.translatesAutoresizingMaskIntoConstraints = false
        roomCaptureView.delegate = self  // Устанавливаем делегат для RoomCaptureView
        view.addSubview(roomCaptureView)
        
        NSLayoutConstraint.activate([
            roomCaptureView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            roomCaptureView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            roomCaptureView.topAnchor.constraint(equalTo: view.topAnchor),
            roomCaptureView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Настраиваем сессию сканирования
        let configOptions = RoomBuilder.ConfigurationOptions()
        roomBuilder = RoomBuilder(options: configOptions)
        roomCaptureSession = roomCaptureView.captureSession
        roomCaptureSession.delegate = self  // Устанавливаем делегат для сессии
    }
    
    private func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupCloseButton() {
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupDoneButton() {
        let doneButton = UIButton(type: .system)
        doneButton.setTitle("Готово", for: .normal)
        doneButton.backgroundColor = .systemBlue
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.layer.cornerRadius = 20
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        view.addSubview(doneButton)
        
        NSLayoutConstraint.activate([
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            doneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            doneButton.widthAnchor.constraint(equalToConstant: 120),
            doneButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }
    
    private func startSession() {
        let sessionConfig = RoomCaptureSession.Configuration()
        roomCaptureView.captureSession.run(configuration: sessionConfig)
    }
    
    private func stopSession() {
        roomCaptureSession.stop()
    }
    
    @objc private func cancelButtonTapped() {
        delegate?.captureViewController(self, didFinishWith: nil)
    }
    
    @objc private func doneButtonTapped() {
        activityIndicator.startAnimating()
        stopSession()
    }
    
    // MARK: - RoomCaptureViewDelegate
    
    func captureView(_ captureView: RoomCaptureView, didPresent error: Error) {
        showNotification?("Ошибка сканирования: \(error.localizedDescription)", .error)
    }
    
    func captureViewDidStartProcessing(_ captureView: RoomCaptureView) {
        activityIndicator.startAnimating()
        showNotification?("Начало обработки сканирования...", .info)
    }
    
    func captureViewDidStopProcessing(_ captureView: RoomCaptureView) {
        activityIndicator.stopAnimating()
    }
    
    // MARK: - RoomCaptureSessionDelegate
    
    func captureSession(_ session: RoomCaptureSession, didUpdate progress: Float) {
        let progressPercent = Int(progress * 100)
        if progressPercent % 20 == 0 { // Показываем уведомление каждые 20%
            showNotification?("Прогресс сканирования: \(progressPercent)%", .info)
        }
    }
    
    func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
        if let error = error {
            showNotification?("Ошибка сканирования: \(error.localizedDescription)", .error)
            DispatchQueue.main.async {
                self.delegate?.captureViewController(self, didFinishWith: nil)
            }
            return
        }
        
        showNotification?("Создание модели комнаты...", .info)
        Task {
            do {
                let finalRoom = try await roomBuilder.capturedRoom(from: data)
                DispatchQueue.main.async {
                    self.showNotification?("Модель комнаты успешно создана", .info)
                    self.delegate?.captureViewController(self, didFinishWith: finalRoom)
                }
            } catch {
                DispatchQueue.main.async {
                    self.showNotification?("Ошибка создания модели: \(error.localizedDescription)", .error)
                    self.delegate?.captureViewController(self, didFinishWith: nil)
                }
            }
        }
    }
}

// Протокол для делегирования результата сканирования
protocol RoomCaptureViewControllerDelegate: AnyObject {
    func captureViewController(_ viewController: RoomCaptureViewController, didFinishWith result: CapturedRoom?)
}

// Вид для результатов сканирования
struct RoomResultView: View {
    let room: CapturedRoom
    @Binding var selectedSurface: SurfaceViewModel?
    @State private var showExportOptions = false
    @State private var showModel = true
    var showNotification: (String, NotificationType) -> Void
    
    var body: some View {
        VStack {
            if showModel {
                // 3D модель комнаты с обработчиком нажатий
                RoomModelView(room: room, onSelectSurface: { surface in
                    selectedSurface = surface
                    showNotification("Выбрана поверхность: \(surface.type)", .info)
                })
                .frame(height: 300)
                .cornerRadius(12)
                .padding()
                .overlay(
                    VStack {
                        Spacer()
                        Text("Нажмите на любой элемент комнаты для просмотра деталей")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                            .padding(.bottom, 8)
                    }
                )
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Section {
                        let surfaces = surfacesFromRoom(room)
                        if surfaces.isEmpty {
                            Text("Нет обнаруженных объектов")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(surfaces) { surfaceVM in
                                Button {
                                    selectedSurface = surfaceVM
                                } label: {
                                    SurfaceCard(surface: surfaceVM)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    } header: {
                        HStack {
                            Text("Обнаруженные объекты")
                                .font(.headline)
                            Spacer()
                            
                            Button {
                                showModel.toggle()
                            } label: {
                                Image(systemName: showModel ? "eye.slash" : "eye")
                            }
                            
                            Button {
                                showExportOptions = true
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            showNotification("Загружена модель комнаты с \(room.walls.count) стенами", .info)
        }
        .navigationTitle("Результаты сканирования")
        .sheet(isPresented: $showExportOptions) {
            ExportOptionsView(room: room)
        }
    }
    
    private func surfacesFromRoom(_ room: CapturedRoom) -> [SurfaceViewModel] {
        var surfaces = [SurfaceViewModel]()
        
        // Добавляем все стены
        surfaces.append(contentsOf: room.walls.map { SurfaceViewModel(surface: $0) })
        
        // Добавляем все окна
        surfaces.append(contentsOf: room.windows.map { SurfaceViewModel(surface: $0) })
        
        // Добавляем все двери
        surfaces.append(contentsOf: room.doors.map { SurfaceViewModel(surface: $0) })
        
        // Добавляем все проемы
        surfaces.append(contentsOf: room.openings.map { SurfaceViewModel(surface: $0) })
        
        return surfaces
    }
}

// Вид для 3D-модели комнаты с возможностью взаимодействия
struct RoomModelView: UIViewRepresentable {
    let room: CapturedRoom
    var onSelectSurface: ((SurfaceViewModel) -> Void)? = nil
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = UIColor.systemBackground
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.scene = createScene(context: context)
        
        // Добавляем обработчик нажатия
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Обновление не требуется
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        let parent: RoomModelView
        // Словарь для сопоставления узлов и информации о поверхностях
        private var nodeToSurfaceInfo: [SCNNode: (category: String, index: Int)] = [:]
        
        init(_ parent: RoomModelView) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gestureRecognize: UIGestureRecognizer) {
            // Получаем view
            guard let scnView = gestureRecognize.view as? SCNView else { return }
            
            // Получаем координаты нажатия
            let p = gestureRecognize.location(in: scnView)
            let hitResults = scnView.hitTest(p, options: [:])
            
            // Проверяем, нажал ли пользователь на объект
            if let hit = hitResults.first {
                let node = hit.node
                
                // Подсвечиваем выбранный объект
                highlightNode(node)
                
                // Проверяем, есть ли информация о поверхности для этого узла
                if let info = nodeToSurfaceInfo[node] {
                        // Получаем поверхность в зависимости от категории
                        var surface: CapturedRoom.Surface?
                    switch info.category {
                        case "wall":
                        if info.index < self.parent.room.walls.count {
                            surface = self.parent.room.walls[info.index]
                            }
                        case "window":
                        if info.index < self.parent.room.windows.count {
                            surface = self.parent.room.windows[info.index]
                            }
                        case "door":
                        if info.index < self.parent.room.doors.count {
                            surface = self.parent.room.doors[info.index]
                            }
                        case "opening":
                        if info.index < self.parent.room.openings.count {
                            surface = self.parent.room.openings[info.index]
                            }
                        default:
                            break
                        }
                        
                        // Если нашли поверхность, создаем модель и вызываем обработчик
                        if let surface = surface {
                            let surfaceVM = SurfaceViewModel(surface: surface)
                            DispatchQueue.main.async {
                                self.parent.onSelectSurface?(surfaceVM)
                            }
                        }
                    }
                }
            }
        
        func registerNode(_ node: SCNNode, forCategory category: String, index: Int) {
            nodeToSurfaceInfo[node] = (category: category, index: index)
        }
        
        func highlightNode(_ node: SCNNode) {
            // Создаем действие подсветки
            let originalColor = node.geometry?.firstMaterial?.diffuse.contents as? UIColor ?? UIColor.white
            let highlightColor = UIColor.yellow
            
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.2
            
            // Меняем цвет материала
            node.geometry?.firstMaterial?.diffuse.contents = highlightColor
            
            SCNTransaction.commit()
            
            // Возвращаем исходный цвет через 0.5 секунды
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.2
                node.geometry?.firstMaterial?.diffuse.contents = originalColor
                SCNTransaction.commit()
            }
        }
    }
    
    private func createScene(context: Context) -> SCNScene {
        let scene = SCNScene()
        
        // Добавляем камеру
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        
        // Находим максимальный размер комнаты для позиционирования камеры
        let maxDimension = max(
            room.walls.map { $0.dimensions.x }.max() ?? 0,
            room.walls.map { $0.dimensions.y }.max() ?? 0
        )
        
        // Позиционируем камеру
        cameraNode.position = SCNVector3(0, 0, maxDimension * 2)
        scene.rootNode.addChildNode(cameraNode)
        
        // Добавляем освещение
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 100
        scene.rootNode.addChildNode(ambientLight)
        
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.intensity = 800
        directionalLight.position = SCNVector3(5, 5, 5)
        scene.rootNode.addChildNode(directionalLight)
        
        // Конвертируем CapturedRoom в SCNScene
        // Добавляем стены
        for (index, wall) in room.walls.enumerated() {
            addSurfaceToScene(scene, surface: wall, category: "wall", index: index, coordinator: context.coordinator)
        }
        
        // Добавляем окна
        for (index, window) in room.windows.enumerated() {
            addSurfaceToScene(scene, surface: window, category: "window", index: index, coordinator: context.coordinator)
        }
        
        // Добавляем двери
        for (index, door) in room.doors.enumerated() {
            addSurfaceToScene(scene, surface: door, category: "door", index: index, coordinator: context.coordinator)
        }
        
        // Добавляем проемы
        for (index, opening) in room.openings.enumerated() {
            addSurfaceToScene(scene, surface: opening, category: "opening", index: index, coordinator: context.coordinator)
        }
        
        return scene
    }
    
    private func addSurfaceToScene(_ scene: SCNScene, surface: CapturedRoom.Surface, category: String, index: Int, coordinator: Coordinator) {
        // Создаем геометрию на основе размеров поверхности
        let width = surface.dimensions.x
        let height = surface.dimensions.y
        
        let geometry = SCNBox(width: CGFloat(width), 
                              height: CGFloat(height), 
                              length: 0.1, 
                              chamferRadius: 0)
        
        // Создаем цвет в зависимости от категории
        var color: UIColor
        switch category {
        case "wall":
            color = UIColor.lightGray
        case "window":
            color = UIColor.blue.withAlphaComponent(0.5)
        case "door":
            color = UIColor.brown
        case "opening":
            color = UIColor.green.withAlphaComponent(0.5)
        default:
            color = UIColor.gray
        }
        
        // Создаем материал
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.transparency = category == "window" || category == "opening" ? 0.5 : 1.0
        geometry.materials = [material]
        
        // Создаем node
        let node = SCNNode(geometry: geometry)
        node.name = "\(category)_\(index)"
        
        // Регистрируем узел в координаторе
        coordinator.registerNode(node, forCategory: category, index: index)
        
        // Устанавливаем позицию на основе transform
        let transform = surface.transform
        let position = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        node.position = position
        
        // Применяем поворот из transform
        node.transform = SCNMatrix4(transform)
        
        // Добавляем node на сцену
        scene.rootNode.addChildNode(node)
    }
}

// Экран экспорта модели
struct ExportOptionsView: View {
    let room: CapturedRoom
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat = ExportFormat.usdz
    @State private var isExporting = false
    @State private var showPreview = false
    @State private var exportedFileURL: URL?
    @State private var exportError: Error?
    @State private var showError = false
    
    enum ExportFormat: String, CaseIterable {
        case usdz = "USDZ"
        case obj = "OBJ"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Формат экспорта")) {
                    Picker("Формат", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section {
                    Button(action: exportModel) {
                        if isExporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Экспортировать модель")
                        }
                    }
                    .disabled(isExporting)
                }
            }
            .navigationTitle("Экспорт модели")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
            .alert("Ошибка экспорта", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportError?.localizedDescription ?? "Неизвестная ошибка")
            }
            .sheet(isPresented: $showPreview) {
                if let url = exportedFileURL {
                    QuickLookPreview(url: url)
                }
            }
        }
    }
    
    private func exportModel() {
        isExporting = true
        
        Task {
            do {
                let fileManager = FileManager.default
                let tempDir = fileManager.temporaryDirectory
                let fileName = "room_\(Date().timeIntervalSince1970)"
                
                switch selectedFormat {
                case .usdz:
                    let usdzURL = tempDir.appendingPathComponent("\(fileName).usdz")
                    try await room.export(to: usdzURL)
                    exportedFileURL = usdzURL
                case .obj:
                    let objURL = tempDir.appendingPathComponent("\(fileName).obj")
                    // Здесь должен быть код экспорта в OBJ формат
                    break
                }
                
                await MainActor.run {
                    isExporting = false
                    if exportedFileURL != nil {
                        showPreview = true
                    }
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    exportError = error
                    showError = true
                }
            }
        }
    }
}

// Вспомогательное представление для предпросмотра файлов через QuickLook
struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        
        init(url: URL) {
            self.url = url
            super.init()
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return url as QLPreviewItem
        }
    }
}

// Карточка для отображения поверхности
struct SurfaceCard: View {
    let surface: SurfaceViewModel
    @EnvironmentObject private var settingsManager: SettingsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForSurfaceType(surface.type))
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text(surface.type)
                    .font(.headline)
                Spacer()
            }
            
            if !surface.name.isEmpty {
                Text(surface.name)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            } else {
                Text("Без названия")
                .font(.subheadline)
                .foregroundColor(.secondary)
                    .italic()
            }
            
            Text("Размеры: \(surface.dimensions(using: settingsManager))")
                .font(.subheadline)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func iconForSurfaceType(_ type: String) -> String {
        switch type {
        case "Стена": return "wall.fill"
        case "Окно": return "window.horizontal"
        case "Дверь": return "door.sliding.right.hand"
        case "Проем": return "door.right.hand.open"
        default: return "questionmark.square"
        }
    }
}

// Вид для отображения деталей о поверхности
struct SurfaceDetailView: View {
    @ObservedObject var surface: SurfaceViewModel
    @State private var name: String
    @State private var notes: String = ""
    @Environment(\.dismiss) private var dismiss
    @State private var showMeasurements = false
    @State private var showARView = false
    @ObservedObject var dataManager: RoomDataManager
    @State private var roomId: UUID? = nil
    
    init(surface: SurfaceViewModel, dataManager: RoomDataManager) {
        self._surface = ObservedObject(wrappedValue: surface)
        self._name = State(initialValue: surface.name)
        self._notes = State(initialValue: surface.notes)
        self._dataManager = ObservedObject(wrappedValue: dataManager)
        
        // Находим комнату, которой принадлежит эта поверхность
        if let room = dataManager.savedRooms.first(where: { room in
            room.surfaces.contains { $0.id == surface.id }
        }) {
            self._roomId = State(initialValue: room.id)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Информация")) {
                    TextField("Название", text: $name)
                    
                    VStack(alignment: .leading) {
                        Text("Тип")
                        Text(surface.type)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Размеры")
                        Text(surface.dimensions)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Показать измерения") {
                        showMeasurements.toggle()
                    }
                    
                    if showMeasurements {
                        DetailedMeasurementsView(surface: surface)
                    }
                }
                
                Section(header: Text("Заметки")) {
                    TextEditor(text: $notes)
                        .frame(height: 120)
                }
                
                Section {
                    Button("Показать в AR") {
                        showARView = true
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationBarTitle("Детали \(surface.type)", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        // Сохраняем внесенные изменения
                        surface.name = name
                        surface.notes = notes
                        
                        // Обновляем поверхность в комнате при наличии ID комнаты
                        dataManager.updateSurface(surface, in: roomId)
                        
                        // Вызываем метод сохранения для всех изменений
                        dataManager.saveRoomsToStorage()
                        
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showARView) {
                Text("AR визуализация")
                    .font(.title)
                    .padding()
            }
        }
    }
}

// Детальная информация о размерах поверхности
struct DetailedMeasurementsView: View {
    let surface: SurfaceViewModel
    @EnvironmentObject private var settingsManager: SettingsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ширина: \(settingsManager.formatDimension(surface.dimensionX))")
            Text("Высота: \(settingsManager.formatDimension(surface.dimensionY))")
            
            Divider()
            
            let area = surface.dimensionX * surface.dimensionY
            let convertedArea = settingsManager.convert(value: area)
            Text("Площадь: \(String(format: "%.2f", convertedArea)) \(settingsManager.measurementUnit.shortSymbol)²")
            
            // Уровень достоверности больше не доступен в нашей модели данных
            Text("Тип поверхности: \(surface.type)")
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// Представление только для метаданных комнаты
struct MetadataRoomView: View {
    @ObservedObject var savedRoom: SavedRoom
    var showNotification: (String, NotificationType) -> Void
    @State private var selectedSurface: SurfaceViewModel?
    @StateObject private var roomDataManager = RoomDataManager()
    @EnvironmentObject private var settingsManager: SettingsManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Просмотр сохранённой комнаты")
                    .font(.title)
                    .fontWeight(.bold)
                
                // 3D модель на основе сохраненных данных
                SavedRoomModelView(savedRoom: savedRoom, onSelectSurface: { surface in
                    selectedSurface = surface
                    showNotification("Выбрана поверхность: \(surface.type)", .info)
                })
                .frame(height: 300)
                .cornerRadius(12)
                .padding()
                .overlay(
                    VStack {
                        Spacer()
                        Text("Нажмите на любой элемент комнаты для просмотра деталей")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                            .padding(.bottom, 8)
                    }
                )
                
                Divider()
                
                // Информация о комнате
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("Информация о комнате")
                            .font(.headline)
                    }
                    
                    Group {
                        HStack {
                            Text("Название:")
                                .fontWeight(.medium)
                            Text(savedRoom.name)
                        }
                        
                        HStack {
                            Text("Дата сканирования:")
                                .fontWeight(.medium)
                            Text(formattedDate(savedRoom.date))
                        }
                        
                        HStack {
                            Text("Всего объектов:")
                                .fontWeight(.medium)
                            Text("\(savedRoom.surfaces.count)")
                        }
                    }
                    .padding(.leading)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Параметры комнаты
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "ruler")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("Параметры комнаты")
                            .font(.headline)
                    }
                    
                    Group {
                        HStack {
                            Text("Стены:")
                                .fontWeight(.medium)
                            Text("\(savedRoom.wallCount)")
                        }
                        
                        HStack {
                            Text("Окна:")
                                .fontWeight(.medium)
                            Text("\(savedRoom.windowCount)")
                        }
                        
                        HStack {
                            Text("Двери:")
                                .fontWeight(.medium)
                            Text("\(savedRoom.doorCount)")
                        }
                        
                        if savedRoom.roomWidth > 0 && savedRoom.roomHeight > 0 {
                            HStack {
                                Text("Примерные размеры:")
                                    .fontWeight(.medium)
                                Text(settingsManager.formatDimensions(width: savedRoom.roomWidth, height: savedRoom.roomHeight))
                            }
                        }
                    }
                    .padding(.leading)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Список поверхностей с заголовком
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "square.3.stack.3d")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("Обнаруженные поверхности")
                            .font(.headline)
                    }
                    
                    ForEach(savedRoom.surfaces) { surface in
                        Button {
                            selectedSurface = surface
                        } label: {
                            SurfaceCard(surface: surface)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Button {
                    showNotification("Для полного просмотра комнаты необходимо отсканировать её заново", .warning)
                } label: {
                    Text("Отсканировать комнату заново")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 20)
            }
            .padding()
        }
        .onAppear {
            showNotification("Загружена сохраненная комната", .info)
        }
        .sheet(item: $selectedSurface) { surface in
            SurfaceDetailView(surface: surface, dataManager: roomDataManager)
                .onDisappear {
                    // Обновляем UI после закрытия окна редактирования
                    roomDataManager.saveRoomsToStorage()
                }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Вид для 3D-модели сохраненной комнаты с возможностью взаимодействия
struct SavedRoomModelView: UIViewRepresentable {
    let savedRoom: SavedRoom
    var onSelectSurface: ((SurfaceViewModel) -> Void)? = nil
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = UIColor.systemBackground
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.scene = createScene(context: context)
        
        // Добавляем обработчик нажатия
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Обновление не требуется
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        let parent: SavedRoomModelView
        // Словарь для сопоставления узлов и индексов поверхностей
        private var nodeToSurfaceIndex: [SCNNode: Int] = [:]
        
        init(_ parent: SavedRoomModelView) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gestureRecognize: UIGestureRecognizer) {
            // Получаем view
            guard let scnView = gestureRecognize.view as? SCNView else { return }
            
            // Получаем координаты нажатия
            let p = gestureRecognize.location(in: scnView)
            let hitResults = scnView.hitTest(p, options: [:])
            
            // Проверяем, нажал ли пользователь на объект
            if let hit = hitResults.first {
                let node = hit.node
                
                // Подсвечиваем выбранный объект
                highlightNode(node)
                
                // Вывести информацию о нажатом объекте
                if let surfaceIndex = nodeToSurfaceIndex[node] {
                    if surfaceIndex < self.parent.savedRoom.surfaces.count {
                        let surface = self.parent.savedRoom.surfaces[surfaceIndex]
                        DispatchQueue.main.async {
                            self.parent.onSelectSurface?(surface)
                        }
                    }
                }
            }
        }
        
        func registerNode(_ node: SCNNode, forSurfaceIndex index: Int) {
            nodeToSurfaceIndex[node] = index
        }
        
        func highlightNode(_ node: SCNNode) {
            // Создаем действие подсветки
            let originalColor = node.geometry?.firstMaterial?.diffuse.contents as? UIColor ?? UIColor.white
            let highlightColor = UIColor.yellow
            
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.2
            
            // Меняем цвет материала
            node.geometry?.firstMaterial?.diffuse.contents = highlightColor
            
            SCNTransaction.commit()
            
            // Возвращаем исходный цвет через 0.5 секунды
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.2
                node.geometry?.firstMaterial?.diffuse.contents = originalColor
                SCNTransaction.commit()
            }
        }
    }
    
    private func createScene(context: Context) -> SCNScene {
        let scene = SCNScene()
        
        // Добавляем камеру
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        
        // Находим максимальный размер комнаты для позиционирования камеры
        let maxDimension = max(
            savedRoom.roomWidth,
            savedRoom.roomHeight
        )
        
        // Позиционируем камеру
        cameraNode.position = SCNVector3(0, 0, maxDimension * 2)
        scene.rootNode.addChildNode(cameraNode)
        
        // Добавляем освещение
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 100
        scene.rootNode.addChildNode(ambientLight)
        
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.intensity = 800
        directionalLight.position = SCNVector3(5, 5, 5)
        scene.rootNode.addChildNode(directionalLight)
        
        // Добавляем поверхности из сохраненных данных
        for (index, surface) in savedRoom.surfaces.enumerated() {
            addSurfaceToScene(scene, surface: surface, index: index, coordinator: context.coordinator)
        }
        
        return scene
    }
    
    private func addSurfaceToScene(_ scene: SCNScene, surface: SurfaceViewModel, index: Int, coordinator: Coordinator) {
        // Создаем геометрию на основе размеров поверхности
        let width = CGFloat(surface.dimensionX)
        let height = CGFloat(surface.dimensionY)
        
        let geometry = SCNBox(width: width, 
                              height: height, 
                              length: 0.1, 
                              chamferRadius: 0)
        
        // Создаем цвет в зависимости от категории
        var color: UIColor
        switch surface.surfaceCategory {
        case 0: // стена
            color = UIColor.lightGray
        case 1: // окно
            color = UIColor.blue.withAlphaComponent(0.5)
        case 2: // дверь
            color = UIColor.brown
        case 3: // проем
            color = UIColor.green.withAlphaComponent(0.5)
        default:
            color = UIColor.gray
        }
        
        // Создаем материал
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.transparency = surface.surfaceCategory == 1 || surface.surfaceCategory == 3 ? 0.5 : 1.0
        geometry.materials = [material]
        
        // Создаем node
        let node = SCNNode(geometry: geometry)
        node.name = "\(surface.type)_\(index)"
        
        // Регистрируем узел для связи с индексом поверхности
        coordinator.registerNode(node, forSurfaceIndex: index)
        
        // Устанавливаем позицию на основе transform
        if surface.transform.count >= 16 {
            let columns = (
                SIMD4<Float>(surface.transform[0], surface.transform[1], surface.transform[2], surface.transform[3]),
                SIMD4<Float>(surface.transform[4], surface.transform[5], surface.transform[6], surface.transform[7]),
                SIMD4<Float>(surface.transform[8], surface.transform[9], surface.transform[10], surface.transform[11]),
                SIMD4<Float>(surface.transform[12], surface.transform[13], surface.transform[14], surface.transform[15])
            )
            
            let transform = simd_float4x4(columns: columns)
            let position = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            node.position = position
            
            // Применяем поворот из transform
            node.transform = SCNMatrix4(transform)
        } else {
            // Размещаем элементы в виде сетки если transform недоступен
            let gridX = CGFloat(index % 3) * (width + 0.1)
            let gridY = CGFloat(index / 3) * (height + 0.1)
            node.position = SCNVector3(Float(gridX), Float(gridY), 0)
        }
        
        // Добавляем node на сцену
        scene.rootNode.addChildNode(node)
    }
} 
 
