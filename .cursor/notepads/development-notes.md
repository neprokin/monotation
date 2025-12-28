# Development Notes

> Практические заметки для разработки monotation

---

## Timer Implementation

### Timer.publish для UI updates

```swift
import Combine

class TimerViewModel: ObservableObject {
    @Published var remainingTime: TimeInterval = 0
    @Published var timerState: TimerState = .idle
    
    private var timerCancellable: AnyCancellable?
    private var startTime: Date?
    private var selectedDuration: TimeInterval = 600
    
    func startTimer() {
        startTime = Date()
        remainingTime = selectedDuration
        timerState = .running(remainingTime: selectedDuration)
        
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }
    }
    
    private func updateTimer() {
        guard let startTime = startTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        remainingTime = max(0, selectedDuration - elapsed)
        
        if remainingTime <= 0 {
            completeTimer()
        }
    }
    
    func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    func completeTimer() {
        stopTimer()
        timerState = .completed
        sendNotification()
        triggerHaptic()
    }
}
```

### Background Mode (App в фоне)

**Проблема**: Timer останавливается когда app уходит в фон.

**Решение**: Сохранить timestamp начала, восстановить при возврате.

```swift
class TimerViewModel: ObservableObject {
    private var backgroundEnteredDate: Date?
    
    init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        backgroundEnteredDate = Date()
        // Schedule local notification for timer completion
        scheduleTimerNotification()
    }
    
    @objc private func appWillEnterForeground() {
        guard let backgroundDate = backgroundEnteredDate else { return }
        
        // Calculate elapsed time while in background
        let timeInBackground = Date().timeIntervalSince(backgroundDate)
        remainingTime = max(0, remainingTime - timeInBackground)
        
        if remainingTime <= 0 {
            completeTimer()
        }
        
        backgroundEnteredDate = nil
    }
}
```

### Local Notification при завершении

```swift
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    
    private init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print("Notification permission: \(granted)")
        }
    }
    
    func scheduleTimerCompletion(in timeInterval: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Медитация завершена"
        content.body = "Время вышло. Пора сохранить вашу медитацию."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "timerComplete",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
```

### Haptic Feedback

```swift
import UIKit

extension TimerViewModel {
    func triggerHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func triggerImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
```

---

## Supabase Integration

### Setup

```swift
// SupabaseConfig.swift (добавить в .gitignore!)
enum SupabaseConfig {
    static let url = "https://your-project.supabase.co"
    static let anonKey = "your-anon-key"
}

// SupabaseService.swift
import Supabase

actor SupabaseService {
    static let shared = SupabaseService()
    
    private let client: SupabaseClient
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.url)!,
            supabaseKey: SupabaseConfig.anonKey
        )
    }
    
    var auth: AuthClient {
        client.auth
    }
}
```

### CRUD Operations

```swift
// Fetch (SELECT)
func fetchMeditations(for userId: String) async throws -> [Meditation] {
    let response: [Meditation] = try await client
        .from("meditations")
        .select()
        .eq("user_id", value: userId)
        .order("start_time", ascending: false)
        .limit(50)  // pagination
        .execute()
        .value
    
    return response
}

// Insert
func insertMeditation(_ meditation: Meditation) async throws {
    try await client
        .from("meditations")
        .insert(meditation)
        .execute()
}

// Update
func updateMeditation(_ meditation: Meditation) async throws {
    try await client
        .from("meditations")
        .update(meditation)
        .eq("id", value: meditation.id.uuidString)
        .execute()
}

// Delete
func deleteMeditation(id: UUID) async throws {
    try await client
        .from("meditations")
        .delete()
        .eq("id", value: id.uuidString)
        .execute()
}
```

### Error Handling

```swift
func fetchMeditations(for userId: String) async throws -> [Meditation] {
    do {
        return try await client.from("meditations")...
    } catch let error as URLError {
        throw SupabaseError.networkFailure
    } catch {
        throw SupabaseError.unknown(error)
    }
}
```

---

## Apple Sign In

### Setup в Xcode

1. **Target → Signing & Capabilities**
2. **+ Capability → Sign in with Apple**
3. **Выбрать Team и Bundle ID**

### Implementation

```swift
import AuthenticationServices

class AuthService {
    static let shared = AuthService()
    
    private let supabase = SupabaseService.shared
    
    func signInWithApple() async throws {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        
        // Present auth UI
        // Get credentials
        // Send to Supabase
    }
}
```

### Supabase Auth Integration

```swift
func authenticateWithSupabase(idToken: String, nonce: String) async throws {
    let session = try await supabase.auth.signInWithIdToken(
        credentials: .init(
            provider: .apple,
            idToken: idToken,
            nonce: nonce
        )
    )
    
    // Store session
    // Update app state
}
```

---

## Markdown Generation

### Структура для AI-анализа (v2.0)

```swift
extension Meditation {
    func asMarkdown() -> String {
        var markdown = "# Медитация \(startTime.formatted())\n\n"
        
        // Metadata
        markdown += "- **Дата**: \(startTime.formatted(date: .long, time: .omitted))\n"
        markdown += "- **Время начала**: \(startTime.formatted(date: .omitted, time: .shortened))\n"
        markdown += "- **Длительность**: \(formattedDuration)\n"
        markdown += "- **Поза**: \(pose.rawValue)\n"
        markdown += "- **Место**: \(place.displayName)\n\n"
        
        // User note
        if let note = note, !note.isEmpty {
            markdown += "## Заметка\n\n"
            markdown += note
            markdown += "\n"
        }
        
        return markdown
    }
    
    // Для экспорта всей истории (future)
    static func exportAsMarkdown(_ meditations: [Meditation]) -> String {
        var markdown = "# История медитаций\n\n"
        
        for meditation in meditations {
            markdown += meditation.asMarkdown()
            markdown += "\n---\n\n"
        }
        
        return markdown
    }
}
```

---

## SwiftUI Tips

### Preview с разными состояниями

```swift
#Preview("Timer - Idle") {
    TimerView()
}

#Preview("Timer - Running") {
    let viewModel = TimerViewModel()
    viewModel.startTimer()
    return TimerView(viewModel: viewModel)
}

#Preview("Light Mode") {
    HistoryView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    HistoryView()
        .preferredColorScheme(.dark)
}
```

### Custom ViewModifier

```swift
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// Usage
Text("Hello")
    .cardStyle()
```

### Loading State

```swift
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading...")
                .foregroundStyle(.secondary)
        }
    }
}

// Usage
if viewModel.isLoading {
    LoadingView()
} else {
    ContentView()
}
```

---

## Performance Optimization

### LazyVStack для длинных списков

```swift
ScrollView {
    LazyVStack(spacing: 12) {
        ForEach(viewModel.meditations) { meditation in
            MeditationCard(meditation: meditation)
        }
    }
}
```

### Debouncing для поиска

```swift
class HistoryViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var filteredMeditations: [Meditation] = []
    
    private var searchTask: Task<Void, Never>?
    
    init() {
        $searchText
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                self?.performSearch(text)
            }
            .store(in: &cancellables)
    }
}
```

### Image Caching (если будут аватары)

```swift
// Use AsyncImage for remote images
AsyncImage(url: imageURL) { image in
    image.resizable()
} placeholder: {
    ProgressView()
}
.frame(width: 50, height: 50)
.clipShape(Circle())
```

---

## Testing Helpers

### Mock Data

```swift
extension Meditation {
    static var sampleData: Meditation {
        Meditation(
            id: UUID(),
            userId: "test-user",
            startTime: Date().addingTimeInterval(-1200),
            endTime: Date(),
            pose: .burmese,
            place: .home,
            note: "Sample meditation",
            createdAt: Date()
        )
    }
    
    static var sampleList: [Meditation] {
        (0..<10).map { index in
            Meditation(
                id: UUID(),
                userId: "test-user",
                startTime: Date().addingTimeInterval(TimeInterval(-index * 86400)),
                endTime: Date().addingTimeInterval(TimeInterval(-index * 86400 + 900)),
                pose: index % 2 == 0 ? .burmese : .walking,
                place: index % 3 == 0 ? .home : .work,
                note: index % 2 == 0 ? "Sample note \(index)" : nil,
                createdAt: Date()
            )
        }
    }
}
```

### Mock Services

```swift
class MockSupabaseService: MeditationServiceProtocol {
    var savedMeditations: [Meditation] = []
    var shouldFail = false
    
    func fetchMeditations(for userId: String) async throws -> [Meditation] {
        if shouldFail {
            throw SupabaseError.networkFailure
        }
        return Meditation.sampleList
    }
    
    func insertMeditation(_ meditation: Meditation) async throws {
        if shouldFail {
            throw SupabaseError.networkFailure
        }
        savedMeditations.append(meditation)
    }
}
```

---

## Common Pitfalls

### ❌ Force unwrapping

```swift
// BAD
let user = appState.currentUser!  // Crash if nil

// GOOD
if let user = appState.currentUser {
    // Use user safely
}

// or with guard
guard let user = appState.currentUser else { return }
```

### ❌ Blocking main thread

```swift
// BAD
func fetchData() {
    let data = try! await service.fetch()  // Blocks UI!
}

// GOOD
func fetchData() async {
    isLoading = true
    defer { isLoading = false }
    
    do {
        meditations = try await service.fetch()
    } catch {
        errorMessage = error.localizedDescription
    }
}
```

### ❌ Retain cycles

```swift
// BAD
timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    self.updateTimer()  // Strong reference to self
}

// GOOD
timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
    self?.updateTimer()
}
```

---

## Debugging Tips

### Print with context

```swift
func fetchMeditations() async {
    print("🔵 [HistoryVM] Fetching meditations for user: \(userId)")
    
    do {
        let result = try await service.fetch()
        print("✅ [HistoryVM] Fetched \(result.count) meditations")
    } catch {
        print("❌ [HistoryVM] Error: \(error)")
    }
}
```

### Xcode Breakpoints

- **Symbolic Breakpoint** на `objc_exception_throw` (ловит все exceptions)
- **Conditional Breakpoint** с условием
- **Action Breakpoint** с auto-continue для логирования

### View Debug Hierarchy

`Debug → View Debugging → Capture View Hierarchy`

---

## Useful Extensions

### String

```swift
extension String {
    var isNotEmpty: Bool {
        !isEmpty
    }
    
    func truncated(to length: Int) -> String {
        if count <= length {
            return self
        }
        return prefix(length) + "..."
    }
}
```

### Collection

```swift
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// Usage
let item = array[safe: 10]  // Returns nil if out of bounds
```

---

## Future Features Preparation

### v1.1 - Statistics

```swift
// Подготовка: храним все нужные данные
struct MeditationStats {
    let totalCount: Int
    let totalDuration: TimeInterval
    let averageDuration: TimeInterval
    let currentStreak: Int
    let longestStreak: Int
}

// Можно вычислить из существующих Meditation записей
```

### v2.0 - AI Analysis

```swift
// Подготовка: markdown формат
// В будущем отправляем на GPT-4/Claude:
func analyzePatterns(_ meditations: [Meditation]) async -> String {
    let markdown = Meditation.exportAsMarkdown(meditations)
    let prompt = """
    Analyze these meditation records and provide insights:
    \(markdown)
    """
    
    // Call OpenAI/Claude API
    return analysis
}
```

---

**Keep these notes updated as you develop!**

