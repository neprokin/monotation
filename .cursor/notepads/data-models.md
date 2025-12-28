# Data Models

> Определение всех моделей данных для monotation

---

## Core Models

### Meditation

**Основная модель** - представляет одну сессию медитации.

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
    
    /// Computed property - длительность в секундах
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    /// Formatted duration for display (e.g., "20 мин")
    var formattedDuration: String {
        let minutes = Int(duration / 60)
        return "\(minutes) мин"
    }
    
    /// Formatted start time for display (e.g., "15:30")
    var formattedStartTime: String {
        startTime.formatted(date: .omitted, time: .shortened)
    }
    
    /// Date for grouping in history (e.g., "Сегодня", "Вчера", "28 декабря")
    var dateGrouping: String {
        if Calendar.current.isDateInToday(startTime) {
            return "Сегодня"
        } else if Calendar.current.isDateInYesterday(startTime) {
            return "Вчера"
        } else {
            return startTime.formatted(date: .abbreviated, time: .omitted)
        }
    }
    
    /// Markdown representation (for future AI analysis)
    var asMarkdown: String {
        """
        # Медитация \(startTime.formatted())
        
        - **Длительность**: \(formattedDuration)
        - **Поза**: \(pose.rawValue)
        - **Место**: \(place.displayName)
        
        \(note ?? "")
        """
    }
}

// MARK: - Sample Data
extension Meditation {
    static let sampleData = Meditation(
        id: UUID(),
        userId: "sample-user-id",
        startTime: Date().addingTimeInterval(-1200), // 20 min ago
        endTime: Date(),
        pose: .burmese,
        place: .home,
        note: "Хорошая концентрация на дыхании",
        createdAt: Date()
    )
    
    static let sampleList: [Meditation] = [
        Meditation(
            id: UUID(),
            userId: "sample",
            startTime: Date().addingTimeInterval(-3600),
            endTime: Date().addingTimeInterval(-3000),
            pose: .burmese,
            place: .home,
            note: "Утренняя медитация",
            createdAt: Date()
        ),
        Meditation(
            id: UUID(),
            userId: "sample",
            startTime: Date().addingTimeInterval(-90000),
            endTime: Date().addingTimeInterval(-89100),
            pose: .walking,
            place: .custom("Парк"),
            note: nil,
            createdAt: Date()
        )
    ]
}
```

---

### MeditationPose

**Enum** для типов медитационных поз.

```swift
enum MeditationPose: String, Codable, CaseIterable {
    case burmese = "Бирманская поза"
    case walking = "Ходьба"
    
    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .burmese: return "figure.mind.and.body"
        case .walking: return "figure.walk"
        }
    }
    
    /// Локализованное название для UI
    var displayName: String {
        self.rawValue
    }
}
```

**Использование:**
```swift
// В Picker
Picker("Поза", selection: $selectedPose) {
    ForEach(MeditationPose.allCases, id: \.self) { pose in
        Label(pose.displayName, systemImage: pose.iconName)
    }
}
```

---

### MeditationPlace

**Enum** для мест медитации (с поддержкой custom значения).

```swift
enum MeditationPlace: Codable, Equatable, Hashable {
    case home
    case work
    case custom(String)
    
    /// Локализованное название для UI
    var displayName: String {
        switch self {
        case .home: return "Дом"
        case .work: return "Работа"
        case .custom(let name): return name
        }
    }
    
    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .work: return "building.2.fill"
        case .custom: return "location.fill"
        }
    }
    
    /// Для сохранения в Supabase (строка)
    var storedValue: String {
        switch self {
        case .home: return "home"
        case .work: return "work"
        case .custom(let name): return name
        }
    }
    
    /// Восстановление из строки (из Supabase)
    static func from(_ string: String) -> MeditationPlace {
        switch string {
        case "home": return .home
        case "work": return .work
        default: return .custom(string)
        }
    }
}
```

**Codable implementation:**
```swift
extension MeditationPlace {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self = MeditationPlace.from(string)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(storedValue)
    }
}
```

**Использование:**
```swift
// Predefined places
let places: [MeditationPlace] = [.home, .work]

// Custom place
let customPlace = MeditationPlace.custom("Парк")
```

---

## Supporting Models

### MeditationFormData

**ViewModel data structure** для формы создания медитации.

```swift
struct MeditationFormData {
    var pose: MeditationPose = .burmese
    var place: MeditationPlace = .home
    var customPlace: String = ""
    var note: String = ""
    
    /// Validation
    var isValid: Bool {
        // Note должна быть не слишком длинной
        note.count <= 500
    }
    
    /// Создать Meditation объект
    func toMeditation(
        userId: String,
        startTime: Date,
        endTime: Date
    ) -> Meditation {
        let actualPlace: MeditationPlace
        if case .custom = place {
            actualPlace = .custom(customPlace)
        } else {
            actualPlace = place
        }
        
        return Meditation(
            id: UUID(),
            userId: userId,
            startTime: startTime,
            endTime: endTime,
            pose: pose,
            place: actualPlace,
            note: note.isEmpty ? nil : note,
            createdAt: Date()
        )
    }
}
```

---

### TimerState

**Enum** для состояния таймера.

```swift
enum TimerState: Equatable {
    case idle
    case selecting(duration: TimeInterval)
    case running(remainingTime: TimeInterval)
    case paused(remainingTime: TimeInterval)
    case completed
    
    var isRunning: Bool {
        if case .running = self { return true }
        return false
    }
    
    var isPaused: Bool {
        if case .paused = self { return true }
        return false
    }
}
```

---

## Database Schema (Supabase)

### meditations table

```sql
CREATE TABLE meditations (
  -- Primary key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Foreign key to auth.users
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  
  -- Meditation data
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  duration INTERVAL NOT NULL,
  pose TEXT NOT NULL,
  place TEXT NOT NULL,
  note TEXT,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  
  -- Constraints
  CONSTRAINT valid_duration CHECK (end_time > start_time),
  CONSTRAINT valid_pose CHECK (pose IN ('burmese', 'walking')),
  CONSTRAINT note_length CHECK (LENGTH(note) <= 500)
);

-- Indexes для performance
CREATE INDEX idx_meditations_user_id ON meditations(user_id);
CREATE INDEX idx_meditations_start_time ON meditations(start_time DESC);
CREATE INDEX idx_meditations_user_start ON meditations(user_id, start_time DESC);

-- Row Level Security (RLS)
ALTER TABLE meditations ENABLE ROW LEVEL SECURITY;

-- Policies: пользователь видит только свои медитации
CREATE POLICY "Users can view own meditations"
  ON meditations FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own meditations"
  ON meditations FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own meditations"
  ON meditations FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own meditations"
  ON meditations FOR DELETE
  USING (auth.uid() = user_id);
```

---

## JSON Representation

### Meditation JSON (Supabase)

```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "user_id": "987e6543-e21b-12d3-a456-426614174999",
  "start_time": "2025-12-28T15:30:00Z",
  "end_time": "2025-12-28T15:50:00Z",
  "duration": "00:20:00",
  "pose": "burmese",
  "place": "home",
  "note": "Хорошая концентрация",
  "created_at": "2025-12-28T15:51:00Z"
}
```

---

## Codable Configuration

### Date Encoding/Decoding

```swift
extension JSONEncoder {
    static var iso8601: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var iso8601: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
```

**Использование:**
```swift
// Encoding
let data = try JSONEncoder.iso8601.encode(meditation)

// Decoding
let meditation = try JSONDecoder.iso8601.decode(Meditation.self, from: data)
```

---

## Future Models (v1.1+)

### Statistics (будущее)

```swift
struct MeditationStats: Codable {
    let totalMeditations: Int
    let totalDuration: TimeInterval
    let currentStreak: Int
    let longestStreak: Int
    let averageDuration: TimeInterval
    let mostCommonPose: MeditationPose
    let mostCommonPlace: MeditationPlace
    
    // Вычислится на backend
}
```

### UserPreferences (будущее)

```swift
struct UserPreferences: Codable {
    var defaultDuration: TimeInterval = 600 // 10 min
    var soundEnabled: Bool = true
    var hapticEnabled: Bool = true
    var notificationsEnabled: Bool = false
}
```

---

## Validation Rules

### Meditation
- `startTime` < `endTime` (всегда)
- `duration` >= 60 seconds (минимум 1 минута)
- `duration` <= 7200 seconds (максимум 2 часа)
- `note` <= 500 characters
- `pose` должна быть валидная (enum)
- `place` не пустая строка

### Validation в ViewModel
```swift
func validateMeditation(_ data: MeditationFormData) -> Result<Void, ValidationError> {
    if data.note.count > 500 {
        return .failure(.noteTooLong)
    }
    
    if case .custom(let name) = data.place, name.isEmpty {
        return .failure(.emptyCustomPlace)
    }
    
    return .success(())
}

enum ValidationError: LocalizedError {
    case noteTooLong
    case emptyCustomPlace
    case invalidDuration
    
    var errorDescription: String? {
        switch self {
        case .noteTooLong: return "Заметка слишком длинная (макс. 500 символов)"
        case .emptyCustomPlace: return "Укажите место"
        case .invalidDuration: return "Некорректная длительность"
        }
    }
}
```

---

## Helper Extensions

### Date Extensions

```swift
extension Date {
    /// Начало дня
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// Конец дня
    var endOfDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
            .addingTimeInterval(-1)
    }
    
    /// Относительный формат (Сегодня, Вчера, дата)
    var relativeDateString: String {
        if Calendar.current.isDateInToday(self) {
            return "Сегодня"
        } else if Calendar.current.isDateInYesterday(self) {
            return "Вчера"
        } else {
            return formatted(date: .abbreviated, time: .omitted)
        }
    }
}
```

### TimeInterval Extensions

```swift
extension TimeInterval {
    /// Formatted as "MM:SS"
    var asMinutesSeconds: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Formatted as "20 мин"
    var asMinutes: String {
        let minutes = Int(self / 60)
        return "\(minutes) мин"
    }
}
```

---

**Use these models consistently throughout the app!**

