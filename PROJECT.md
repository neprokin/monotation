# monotation

> Минималистичный iOS трекер медитаций с фокусом на осознанности и простоте

---

## 🎯 Концепция

**monotation** - это нативное iOS приложение для отслеживания практики медитации. Название происходит от **mono** (один, фокус) + **notation** (запись), отражая философию простоты и осознанного ведения записей о медитациях.

### Философия проекта
- **Минимализм** - только необходимое, ничего лишнего
- **Нативность** - полное использование возможностей iOS
- **Готовность к AI** - структура данных позволяет в будущем добавить интеллектуальный анализ
- **Приватность** - данные пользователя хранятся безопасно

---

## 📱 MVP Функционал

### 1. 🕐 Таймер медитации
- Выбор времени перед началом (5, 10, 15, 20, 30 минут или custom)
- Обратный отсчет с визуальной индикацией
- Звук/вибрация по окончании медитации
- Работа в фоновом режиме (если приложение свернуто)

### 2. 💾 Сохранение медитаций
После завершения медитации пользователь заполняет:
- **Дата и время начала** _(автоматически)_
- **Дата и время окончания** _(автоматически)_
- **Длительность** _(вычисляется автоматически)_
- **Поза** _(выбор из списка)_:
  - Бирманская поза
  - Ходьба
- **Место** _(выбор из списка + свой вариант)_:
  - Дом
  - Работа
  - Свой вариант _(текстовое поле)_
- **Заметка** _(опционально, текстовое поле)_

### 3. 📚 История медитаций
- Хронологический список всех медитаций
- Группировка по датам
- Отображение ключевой информации (время, длительность, место)
- Возможность просмотра деталей каждой медитации

### 4. 🔐 Аутентификация
- Apple Sign In (Sign in with Apple)
- Простой и быстрый вход
- Приватность и безопасность из коробки

---

## 🛠 Технический стек

### iOS Application
```
Language:     Swift 5.9+
Framework:    SwiftUI
Target:       iOS 17.0+
Architecture: MVVM (Model-View-ViewModel)
```

### Backend
```
Service:      Supabase
Database:     PostgreSQL
Auth:         Supabase Auth (с Apple Sign In)
API:          REST API через Supabase Swift SDK
```

### Зависимости
```
Swift Package Manager:
├── supabase-swift (официальный SDK)
└── (другие по необходимости)
```

### Инструменты разработки
```
IDE:          Xcode 15+
Version:      Git
Linter:       SwiftLint (опционально)
```

---

## 🏗 Архитектура приложения

### MVVM Pattern

```
App Layer
├── monotationApp.swift          # App entry point
└── AppState                     # Global state management

Views Layer (SwiftUI)
├── AuthView                     # Apple Sign In screen
├── TimerView                    # Main meditation timer
├── MeditationFormView           # Save meditation form
├── HistoryView                  # List of past meditations
└── Components/
    ├── TimerCircle              # Visual timer component
    ├── MeditationCard           # History list item
    └── CustomPicker             # Reusable picker

ViewModels Layer
├── AuthViewModel                # Auth state & logic
├── TimerViewModel               # Timer logic & state
├── MeditationFormViewModel      # Form validation & submission
└── HistoryViewModel             # Fetch & display history

Services Layer
├── SupabaseService              # Database CRUD operations
├── AuthService                  # Apple Sign In integration
└── TimerService                 # Timer logic (optional)

Models Layer
├── Meditation                   # Main data model
├── MeditationPose               # Enum for poses
└── MeditationPlace              # Enum for places
```

### Navigation Flow
```
App Start
    ↓
[Auth Check]
    ↓
Not Authenticated → AuthView (Apple Sign In)
    ↓                       ↓
    ↓                   [Sign In]
    ↓                       ↓
    └──── Authenticated ────┘
            ↓
        TimerView (Main Screen)
            ├── [Start Meditation] → Timer Running
            │                           ↓
            │                      [Complete]
            │                           ↓
            │                   MeditationFormView
            │                           ↓
            │                      [Save] → Back to TimerView
            │
            └── [View History] → HistoryView
                                    ↓
                                [Tap Item] → Detail View
```

---

## 📊 Модель данных

### Meditation Model (Swift)
```swift
struct Meditation: Codable, Identifiable {
    let id: UUID
    let userId: String
    let startTime: Date
    let endTime: Date
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    let pose: MeditationPose
    let place: MeditationPlace
    let note: String?
    let createdAt: Date
}

enum MeditationPose: String, Codable, CaseIterable {
    case burmese = "Бирманская поза"
    case walking = "Ходьба"
}

enum MeditationPlace: Codable, Equatable {
    case home
    case work
    case custom(String)
    
    var displayName: String {
        switch self {
        case .home: return "Дом"
        case .work: return "Работа"
        case .custom(let name): return name
        }
    }
}
```

### Database Schema (Supabase/PostgreSQL)
```sql
CREATE TABLE meditations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  duration INTERVAL NOT NULL,
  pose TEXT NOT NULL,
  place TEXT NOT NULL,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Индекс для быстрого поиска по user_id
CREATE INDEX idx_meditations_user_id ON meditations(user_id);

-- Индекс для сортировки по дате
CREATE INDEX idx_meditations_start_time ON meditations(start_time DESC);

-- Row Level Security (RLS)
ALTER TABLE meditations ENABLE ROW LEVEL SECURITY;

-- Policy: пользователи видят только свои медитации
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

### Markdown Format (для заметок)
Заметки сохраняются как обычный текст, но с учетом будущего AI-анализа в структурированном markdown:

```markdown
# Медитация 28.12.2025 15:30

- **Длительность**: 20 минут
- **Поза**: Бирманская поза
- **Место**: Дом
- **Состояние**: Спокойное
- **Заметка**: Хорошая концентрация на дыхании. Мысли приходили, но легко отпускались.
```

---

## 🎨 UI/UX Принципы

### Дизайн-система
- **Нативные iOS компоненты** - List, NavigationStack, Picker, Button
- **SF Symbols** - системные иконки Apple
- **SF Pro** - системный шрифт
- **Стандартные паддинги и отступы** iOS

### Цветовая схема
- **Автоматическая поддержка** Light/Dark mode
- **Системные цвета** - .primary, .secondary, .accent
- **Минималистичная палитра** - без лишних цветов

### Анимации
- **Нативные переходы** SwiftUI
- **Haptic Feedback** для важных действий (старт/стоп таймера, сохранение)

### Accessibility
- **VoiceOver** support
- **Dynamic Type** (масштабирование шрифтов)
- **High Contrast** mode support
- **Reduce Motion** support

---

## 🔐 Backend Setup (Supabase)

### Шаги настройки

#### 1. Создание проекта
```bash
1. Зайти на supabase.com
2. Создать новый проект "monotation"
3. Выбрать регион (ближайший к целевой аудитории)
4. Сохранить API URL и Anon Key
```

#### 2. Настройка аутентификации
```bash
# В Supabase Dashboard:
Authentication → Providers → Apple
1. Включить Apple provider
2. Настроить Apple Developer консоль
3. Добавить Service ID и Key ID
4. Загрузить Private Key
```

#### 3. Создание таблиц
```sql
-- Выполнить SQL из раздела "Database Schema" выше
-- В Supabase: SQL Editor → New query
```

#### 4. Тестирование
```bash
# Проверить:
- Auth работает (регистрация/вход)
- RLS policies работают (пользователь видит только свои данные)
- CRUD операции работают
```

### Переменные окружения (iOS)

Создать `Config.swift` (добавить в .gitignore):
```swift
enum Config {
    static let supabaseURL = "https://your-project.supabase.co"
    static let supabaseAnonKey = "your-anon-key"
}
```

---

## 🗺 Roadmap

### ✅ v1.0 - MVP (Текущий фокус)
- [x] Таймер медитации с выбором времени
- [x] Сохранение медитаций (дата, время, поза, место, заметка)
- [x] История медитаций (хронологический список)
- [x] Apple Sign In аутентификация
- [x] Supabase backend интеграция

### 📋 v1.1 - Базовая аналитика
- [ ] Статистика (общее время медитаций)
- [ ] Количество медитаций за период
- [ ] Стрики (дни подряд)
- [ ] Визуализация прогресса (графики)

### 📋 v1.2 - Улучшения UX
- [ ] Редактирование медитаций из истории
- [ ] Удаление медитаций
- [ ] Фильтры в истории (по дате, месту, позе)
- [ ] Поиск в истории

### 🚀 v2.0 - AI-анализ
- [ ] Анализ паттернов медитаций (время дня, частота)
- [ ] Инсайты на основе заметок (NLP анализ)
- [ ] Рекомендации по практике
- [ ] Недельные/месячные отчеты
- [ ] Интеграция с GPT-4/Claude для анализа

### 🎯 v2.1 - Дополнительные фичи
- [ ] Guided медитации (аудио)
- [ ] Фоновые звуки/музыка
- [ ] Напоминания о медитации
- [ ] Экспорт данных (PDF, CSV)
- [ ] Синхронизация с Apple Health

---

## 🚀 Development Setup

### Требования
```
macOS:        14.0+ (Sonoma)
Xcode:        15.0+
iOS Target:   17.0+
Swift:        5.9+
```

### Установка

#### 1. Клонирование проекта
```bash
git clone <repository-url>
cd monotation
```

#### 2. Настройка Supabase
```bash
# Создать Config.swift с вашими ключами
cp Config.example.swift Config.swift
# Отредактировать Config.swift, добавив URL и Anon Key
```

#### 3. Установка зависимостей
```bash
# Открыть проект в Xcode
open monotation.xcodeproj

# Swift Package Manager установит зависимости автоматически
# Или: File → Add Package Dependencies → supabase-swift
```

#### 4. Настройка Signing
```bash
# В Xcode:
Target → Signing & Capabilities
1. Выбрать Team
2. Изменить Bundle Identifier (com.yourname.monotation)
3. Добавить "Sign in with Apple" capability
```

#### 5. Запуск
```bash
# Выбрать симулятор или устройство
# ⌘ + R для запуска
```

---

## 📚 Документация

### Ключевые технологии
- [Swift Documentation](https://docs.swift.org/swift-book/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Supabase Swift SDK](https://supabase.com/docs/reference/swift/introduction)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)

### Статьи и ресурсы
- [SwiftUI MVVM Pattern](https://www.swiftbysundell.com)
- [Sign in with Apple](https://developer.apple.com/sign-in-with-apple/)
- [Supabase Auth Guide](https://supabase.com/docs/guides/auth)

---

## 🔒 Безопасность и Приватность

### Данные пользователя
- Все данные хранятся в Supabase с Row Level Security
- Пользователь видит только свои медитации
- Токены хранятся в iOS Keychain

### Apple Sign In
- Приватность из коробки
- Опция скрытия email (Hide My Email)
- Минимум собираемых данных

### API Keys
- Хранение в Config.swift (не в git)
- .gitignore для всех секретов
- Environment variables для CI/CD

---

## 🧪 Тестирование

### Unit Tests (будущее)
```swift
// ViewModels должны быть тестируемы
// Моки для Services
// XCTest framework
```

### UI Tests (будущее)
```swift
// Критические flow:
// - Регистрация/вход
// - Создание медитации
// - Просмотр истории
```

---

## 📝 Git Workflow

### Branches
```
main       - production ready код
develop    - текущая разработка
feature/*  - новые фичи
bugfix/*   - исправление багов
```

### Commit Convention
```
feat:     новая функциональность
fix:      исправление бага
docs:     изменения в документации
style:    форматирование кода
refactor: рефакторинг
test:     добавление тестов
chore:    обновление зависимостей

Пример: feat: add timer screen with countdown
```

---

## 👥 Contributing

### Code Style
- Следовать Swift API Design Guidelines
- SwiftLint для консистентности
- Комментарии для сложной логики
- Preview для каждого View

### Pull Request Process
1. Создать feature branch
2. Реализовать функционал
3. Написать описание изменений
4. Создать PR в develop

---

## 📄 License

TBD (определить позже)

---

## 📧 Contact

TBD (добавить контакты)

---

**Последнее обновление**: 28 декабря 2025  
**Версия**: 1.0.0-MVP  
**Статус**: 🚧 В разработке

