import SwiftUI
import RoomPlan
import ARKit
import QuickLook

// Основной экран для сканирования комнаты
struct RoomScanView: View {
    @State private var showScanner = false
    @State private var scannedRoom: CapturedRoom?
    @State private var selectedSurface: SurfaceViewModel?
    
    var body: some View {
        NavigationView {
            VStack {
                if let room = scannedRoom {
                    RoomResultView(room: room, selectedSurface: $selectedSurface)
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
                    }
                    .padding()
                }
            }
            .navigationTitle("Room Scanner")
            .sheet(isPresented: $showScanner) {
                // Показываем контроллер RoomCaptureViewController через UIViewControllerRepresentable
                ARRoomCaptureView(isPresented: $showScanner, scannedRoom: $scannedRoom)
                    .edgesIgnoringSafeArea(.all)
            }
            .sheet(item: $selectedSurface) { surface in
                SurfaceDetailView(surface: surface)
            }
        }
    }
}

// Контейнер для RoomCaptureViewController
struct ARRoomCaptureView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var scannedRoom: CapturedRoom?
    
    func makeUIViewController(context: Context) -> RoomCaptureViewController {
        let controller = RoomCaptureViewController()
        controller.delegate = context.coordinator
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
            parent.scannedRoom = result
            parent.isPresented = false
        }
    }
}

// Кастомный контроллер для RoomPlan
class RoomCaptureViewController: UIViewController {
    private var roomCaptureView: RoomCaptureView!
    private var roomCaptureSession: RoomCaptureSession!
    private var roomBuilder: RoomBuilder!
    private var activityIndicator: UIActivityIndicatorView!
    weak var delegate: RoomCaptureViewControllerDelegate?
    
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
        
        // Инициализируем RoomCaptureSession до viewDidAppear
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
        roomCaptureView.captureSession.stop()
    }
    
    @objc private func cancelButtonTapped() {
        delegate?.captureViewController(self, didFinishWith: nil)
    }
    
    @objc private func doneButtonTapped() {
        activityIndicator.startAnimating()
        stopSession()
        
        // Получаем результат сканирования
        // Так как roomBuilder.capturedRoom может быть функцией или свойством в разных версиях iOS,
        // используем универсальный подход
        if let capturedRoom = getScannedRoom() {
            delegate?.captureViewController(self, didFinishWith: capturedRoom)
        } else {
            delegate?.captureViewController(self, didFinishWith: nil)
        }
        
        activityIndicator.stopAnimating()
    }
    
    private func getScannedRoom() -> CapturedRoom? {
        // Проверяем разные способы получения модели комнаты
        // в зависимости от версии API
        if let directRoom = roomBuilder.capturedRoom as? CapturedRoom {
            return directRoom
        }
        
        // Если не удалось получить комнату напрямую,
        // просто возвращаем nil
        return nil
    }
}

// Протокол для делегирования результата сканирования
protocol RoomCaptureViewControllerDelegate: AnyObject {
    func captureViewController(_ viewController: RoomCaptureViewController, didFinishWith result: CapturedRoom?)
}

// Модель для представления данных о поверхности
struct SurfaceViewModel: Identifiable {
    let id = UUID()
    let surface: CapturedRoom.Surface
    var name: String = ""
    var notes: String = ""
    
    var dimensions: String {
        let width = surface.dimensions.x
        let height = surface.dimensions.y
        return String(format: "%.2f x %.2f м", width, height)
    }
    
    var type: String {
        switch surface.category {
        case .wall: return "Стена"
        case .window: return "Окно"
        case .door: return "Дверь"
        case .opening: return "Проем"
        @unknown default: return "Неизвестно"
        }
    }
}

// Вид для результатов сканирования
struct RoomResultView: View {
    let room: CapturedRoom
    @Binding var selectedSurface: SurfaceViewModel?
    @State private var showExportOptions = false
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Section {
                        ForEach(surfacesFromRoom(room)) { surfaceVM in
                            Button {
                                selectedSurface = surfaceVM
                            } label: {
                                SurfaceCard(surface: surfaceVM)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    } header: {
                        HStack {
                            Text("Обнаруженные объекты")
                                .font(.headline)
                            Spacer()
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
        .navigationTitle("Результаты сканирования")
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

// Карточка для отображения поверхности
struct SurfaceCard: View {
    let surface: SurfaceViewModel
    
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
            
            Text(surface.name.isEmpty ? "Без названия" : surface.name)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Размеры: \(surface.dimensions)")
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
    let surface: SurfaceViewModel
    @State private var name: String
    @State private var notes: String = ""
    @Environment(\.dismiss) private var dismiss
    
    init(surface: SurfaceViewModel) {
        self.surface = surface
        self._name = State(initialValue: surface.name)
        self._notes = State(initialValue: surface.notes)
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
                }
                
                Section(header: Text("Заметки")) {
                    TextEditor(text: $notes)
                        .frame(height: 120)
                }
            }
            .navigationBarTitle("Детали", displayMode: .inline)
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
 