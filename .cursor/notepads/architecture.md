# App Architecture

> MVVM архитектура для monotation iOS app

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                      SwiftUI Views                       │
│  (UI Layer - только отображение и взаимодействие)       │
└─────────────────────┬───────────────────────────────────┘
                      │ @ObservedObject / @StateObject
                      │ @Published properties
                      ↓
┌─────────────────────────────────────────────────────────┐
│                      ViewModels                          │
│  (Presentation Logic - бизнес-логика для UI)            │
└─────────────────────┬───────────────────────────────────┘
                      │ async/await calls
                      │ protocol-based
                      ↓
┌─────────────────────────────────────────────────────────┐
│                       Services                           │
│  (Data Layer - работа с backend, auth, database)        │
└─────────────────────┬───────────────────────────────────┘
                      │ Supabase SDK
                      │ Apple Sign In
                      ↓
┌─────────────────────────────────────────────────────────┐
│                        Models                            │
│  (Data structures - Codable, Identifiable)               │
└─────────────────────────────────────────────────────────┘
```

---

## Folder Structure

```
monotation/
├── App/
│   ├── monotationApp.swift              # @main entry point
│   └── AppState.swift                   # Global app state (auth, etc.)
│
├── Views/
│   ├── Auth/
│   │   └── AuthView.swift               # Apple Sign In screen
│   │
│   ├── Timer/
│   │   ├── TimerView.swift              # Main timer screen
│   │   ├── TimerSelectionView.swift     # Duration selection
│   │   └── TimerCircleView.swift        # Visual countdown component
│   │
│   ├── Meditation/
│   │   ├── MeditationFormView.swift     # Save meditation form
│   │   └── MeditationDetailView.swift   # Detailed view (future)
│   │
│   ├── History/
│   │   ├── HistoryView.swift            # List of meditations
│   │   └── MeditationCard.swift         # List item component
│   │
│   └── Components/
│       ├── CustomPicker.swift           # Reusable picker
│       └── LoadingView.swift            # Loading indicator
│
├── ViewModels/
│   ├── AuthViewModel.swift              # Auth state & logic
│   ├── TimerViewModel.swift             # Timer logic
│   ├── MeditationFormViewModel.swift    # Form validation & save
│   └── HistoryViewModel.swift           # Fetch history
│
├── Services/
│   ├── SupabaseService.swift            # Database CRUD operations
│   ├── AuthService.swift                # Apple Sign In + Supabase auth
│   └── NotificationService.swift        # Local notifications
│
├── Models/
│   ├── Meditation.swift                 # Main data model
│   ├── MeditationPose.swift             # Enum for poses
│   ├── MeditationPlace.swift            # Enum for places
│   ├── TimerState.swift                 # Timer state enum
│   └── ValidationError.swift            # Custom errors
│
├── Config/
│   └── SupabaseConfig.swift             # API keys (in .gitignore)
│
├── Extensions/
│   ├── Date+Extensions.swift
│   ├── TimeInterval+Extensions.swift
│   └── View+Extensions.swift
│
└── Resources/
    └── Assets.xcassets                  # Images, colors, etc.
```

---

## Layer Responsibilities

### 1. Views (SwiftUI)

**Что делают:**
- Отображают UI
- Реагируют на user input
- Биндят данные из ViewModel (@Published properties)
- Вызывают методы ViewModel

**Что НЕ делают:**
- Бизнес-логику
- Прямые вызовы API/Database
- Вычисления (кроме простых UI вычислений)
- Хранение состояния (кроме локального @State)

**Пример:**
```swift
struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()
    
    var body: some View {
        VStack {
            // Отображение данных из ViewModel
            Text(viewModel.formattedTime)
            
            // User action → вызов метода ViewModel
            Button("Start") {
                viewModel.startTimer()
            }
        }
    }
}
```

---

### 2. ViewModels

**Что делают:**
- Содержат бизнес-логику для UI
- Управляют состоянием экрана (@Published properties)
- Вызывают Services для данных
- Обрабатывают ошибки
- Форматируют данные для отображения

**Что НЕ делают:**
- Прямые вызовы Supabase API
- UI-специфичные операции (SwiftUI код)
- Хранение глобального состояния

**Пример:**
```swift
@MainActor
class TimerViewModel: ObservableObject {
    // Published state для UI
    @Published var timerState: TimerState = .idle
    @Published var selectedDuration: TimeInterval = 600
    @Published var errorMessage: String?
    
    // Dependencies (protocol-based для тестируемости)
    private let supabaseService: MeditationServiceProtocol
    
    init(supabaseService: MeditationServiceProtocol = SupabaseService.shared) {
        self.supabaseService = supabaseService
    }
    
    // Business logic
    func startTimer() {
        timerState = .running(remainingTime: selectedDuration)
        // Timer logic...
    }
    
    func saveMeditation(_ data: MeditationFormData) async {
        do {
            let meditation = data.toMeditation(...)
            try await supabaseService.insertMeditation(meditation)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // Computed properties для UI
    var formattedTime: String {
        // Format logic
    }
}
```

---

### 3. Services

**Что делают:**
- Взаимодействие с backend (Supabase)
- Аутентификация (Apple Sign In)
- Local notifications
- Другие side effects (file storage, etc.)

**Что НЕ делают:**
- UI логику
- Форматирование для отображения
- Зависимость от SwiftUI

**Пример:**
```swift
protocol MeditationServiceProtocol {
    func fetchMeditations(for userId: String) async throws -> [Meditation]
    func insertMeditation(_ meditation: Meditation) async throws
    func updateMeditation(_ meditation: Meditation) async throws
    func deleteMeditation(id: UUID) async throws
}

actor SupabaseService: MeditationServiceProtocol {
    static let shared = SupabaseService()
    
    private let client: SupabaseClient
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.url)!,
            supabaseKey: SupabaseConfig.anonKey
        )
    }
    
    func fetchMeditations(for userId: String) async throws -> [Meditation] {
        let response: [Meditation] = try await client
            .from("meditations")
            .select()
            .eq("user_id", value: userId)
            .order("start_time", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    func insertMeditation(_ meditation: Meditation) async throws {
        try await client
            .from("meditations")
            .insert(meditation)
            .execute()
    }
}
```

---

### 4. Models

**Что делают:**
- Определяют структуры данных
- Codable для JSON encoding/decoding
- Identifiable для SwiftUI lists
- Equatable для сравнений
- Computed properties (без side effects)

**Что НЕ делают:**
- Бизнес-логику (в ViewModel)
- API calls (в Services)
- UI код

**Пример:**
```swift
struct Meditation: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: String
    let startTime: Date
    let endTime: Date
    let pose: MeditationPose
    let place: MeditationPlace
    let note: String?
    let createdAt: Date
    
    // Computed property (pure function)
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}
```

---

## Navigation Flow

### App Entry

```swift
@main
struct monotationApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            if appState.isAuthenticated {
                TimerView()
                    .environmentObject(appState)
            } else {
                AuthView()
                    .environmentObject(appState)
            }
        }
    }
}
```

### AppState (Global State)

```swift
@MainActor
class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private let authService: AuthService
    
    init(authService: AuthService = .shared) {
        self.authService = authService
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        Task {
            isAuthenticated = await authService.isAuthenticated()
            if isAuthenticated {
                currentUser = await authService.currentUser()
            }
        }
    }
    
    func signOut() async {
        await authService.signOut()
        isAuthenticated = false
        currentUser = nil
    }
}
```

### Screen Navigation

```swift
// TimerView → MeditationFormView
struct TimerView: View {
    @State private var showForm = false
    
    var body: some View {
        NavigationStack {
            // Timer UI
            Button("Complete") {
                showForm = true
            }
            .sheet(isPresented: $showForm) {
                MeditationFormView(
                    startTime: startTime,
                    endTime: Date()
                )
            }
        }
    }
}

// TimerView → HistoryView
struct TimerView: View {
    var body: some View {
        NavigationStack {
            // Timer UI
            NavigationLink("History") {
                HistoryView()
            }
        }
    }
}
```

---

## Data Flow

### 1. Fetching Data (Read)

```
User opens HistoryView
        ↓
HistoryView created
        ↓
HistoryViewModel init
        ↓
viewModel.fetchMeditations() called
        ↓
HistoryViewModel → SupabaseService.fetchMeditations()
        ↓
SupabaseService → Supabase API
        ↓
Response: [Meditation]
        ↓
ViewModel updates @Published meditations
        ↓
SwiftUI re-renders HistoryView
        ↓
User sees list
```

### 2. Saving Data (Write)

```
User completes timer
        ↓
MeditationFormView shown
        ↓
User fills form
        ↓
User taps "Save"
        ↓
MeditationFormViewModel.save() called
        ↓
Validation → Result<Void, ValidationError>
        ↓
If valid: ViewModel → SupabaseService.insertMeditation()
        ↓
SupabaseService → Supabase API
        ↓
Success/Failure
        ↓
ViewModel updates @Published state (success/error)
        ↓
SwiftUI shows success/error UI
        ↓
Dismiss form, back to TimerView
```

---

## Dependency Injection

### Protocol-based Services

**Зачем:**
- Тестируемость (mock services)
- Гибкость (замена реализации)
- Separation of concerns

**Пример:**
```swift
// Protocol
protocol MeditationServiceProtocol {
    func fetchMeditations(for userId: String) async throws -> [Meditation]
}

// Production implementation
actor SupabaseService: MeditationServiceProtocol {
    // Real Supabase calls
}

// Mock for testing
class MockMeditationService: MeditationServiceProtocol {
    func fetchMeditations(for userId: String) async throws -> [Meditation] {
        return Meditation.sampleList
    }
}

// ViewModel uses protocol
class HistoryViewModel: ObservableObject {
    private let service: MeditationServiceProtocol
    
    init(service: MeditationServiceProtocol = SupabaseService.shared) {
        self.service = service
    }
}

// Testing
let mockService = MockMeditationService()
let viewModel = HistoryViewModel(service: mockService)
```

---

## State Management

### Local State (@State)

```swift
struct TimerView: View {
    @State private var showHistory = false  // View-local state
    
    var body: some View {
        Button("History") {
            showHistory.toggle()
        }
    }
}
```

### ViewModel State (@StateObject / @ObservedObject)

```swift
struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()  // Owned by view
    
    var body: some View {
        Text(viewModel.formattedTime)  // Reactive to @Published changes
    }
}

struct MeditationFormView: View {
    @ObservedObject var viewModel: MeditationFormViewModel  // Passed from parent
}
```

### Global State (@EnvironmentObject)

```swift
struct TimerView: View {
    @EnvironmentObject var appState: AppState  // Shared across app
    
    var body: some View {
        if let user = appState.currentUser {
            Text("Welcome, \(user.name)")
        }
    }
}
```

---

## Error Handling

### Service Level

```swift
enum SupabaseError: LocalizedError {
    case networkFailure
    case unauthorized
    case notFound
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .networkFailure: return "Network connection failed"
        case .unauthorized: return "Unauthorized access"
        case .notFound: return "Resource not found"
        case .unknown(let error): return error.localizedDescription
        }
    }
}

actor SupabaseService {
    func fetchMeditations(...) async throws -> [Meditation] {
        do {
            return try await client.from("meditations")...
        } catch {
            throw SupabaseError.unknown(error)
        }
    }
}
```

### ViewModel Level

```swift
class HistoryViewModel: ObservableObject {
    @Published var meditations: [Meditation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchMeditations() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            meditations = try await service.fetchMeditations(for: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

### View Level

```swift
struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    
    var body: some View {
        List(viewModel.meditations) { meditation in
            MeditationCard(meditation: meditation)
        }
        .alert("Error", isPresented: $viewModel.hasError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
        .task {
            await viewModel.fetchMeditations()
        }
    }
}
```

---

## Concurrency (@MainActor)

### ViewModels должны быть @MainActor

```swift
@MainActor  // UI updates must be on main thread
class TimerViewModel: ObservableObject {
    @Published var remainingTime: TimeInterval = 0
    
    func startTimer() {
        // This runs on MainActor
        Task {
            // Background work
            await someHeavyOperation()
            
            // UI update (automatically on main thread due to @MainActor)
            remainingTime = 0
        }
    }
}
```

### Services могут быть actor (thread-safe)

```swift
actor SupabaseService {
    // All methods here are isolated
    // Automatically thread-safe
    
    func fetchMeditations() async throws -> [Meditation] {
        // Database call
    }
}
```

---

## Testing Strategy (Future)

### Unit Tests for ViewModels

```swift
@testable import monotation

class TimerViewModelTests: XCTestCase {
    var viewModel: TimerViewModel!
    var mockService: MockMeditationService!
    
    override func setUp() {
        mockService = MockMeditationService()
        viewModel = TimerViewModel(service: mockService)
    }
    
    func testStartTimer() {
        viewModel.startTimer()
        XCTAssertTrue(viewModel.timerState.isRunning)
    }
    
    func testSaveMeditation() async throws {
        let data = MeditationFormData(...)
        await viewModel.saveMeditation(data)
        XCTAssertEqual(mockService.savedMeditations.count, 1)
    }
}
```

### UI Tests (Critical Flows)

```swift
class monotationUITests: XCTestCase {
    func testAuthFlow() {
        let app = XCUIApplication()
        app.launch()
        
        // Tap Apple Sign In
        app.buttons["Sign in with Apple"].tap()
        
        // Verify timer screen appears
        XCTAssertTrue(app.navigationBars["Timer"].exists)
    }
}
```

---

## Performance Considerations

### Lazy Loading

```swift
struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.meditations) { meditation in
                MeditationCard(meditation: meditation)
                    .onAppear {
                        if meditation == viewModel.meditations.last {
                            Task {
                                await viewModel.loadMore()
                            }
                        }
                    }
            }
        }
    }
}
```

### Debouncing

```swift
class MeditationFormViewModel: ObservableObject {
    @Published var note: String = ""
    
    private var debounceTask: Task<Void, Never>?
    
    func noteChanged(_ newValue: String) {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5s
            await validateNote(newValue)
        }
    }
}
```

---

**This architecture ensures:**
- ✅ Clear separation of concerns
- ✅ Testable code
- ✅ Scalable structure
- ✅ SwiftUI best practices
- ✅ Thread-safe operations
- ✅ Easy to maintain

