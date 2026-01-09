# monotation

> Минималистичный iOS трекер медитаций

[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0+-green.svg)](https://developer.apple.com/xcode/swiftui/)

---

## 📱 О проекте

**monotation** - это нативное iOS приложение для отслеживания практики медитации с фокусом на минимализме и простоте использования.

Название происходит от **mono** (один, фокус) + **notation** (запись), отражая философию осознанного ведения записей о медитациях.

---

## ✨ Функционал

### 📱 iOS App (✅ протестировано)
- 🕐 **Таймер медитации** - выбор времени с обратным отсчетом
- 💾 **Сохранение записей** - дата, время, длительность, поза, место, заметка
- 📚 **История медитаций** - хронологический список всех практик
- ☁️ **CloudKit синхронизация** - автоматическая через iCloud (не требуется Apple Sign In)

### ⌚️ watchOS App (✅ протестировано на реальных устройствах)
- 🕐 **Таймер медитации** - выбор длительности, обратный отсчет
- ❤️ **Мониторинг пульса** - в реальном времени (HKWorkoutSession)
- 💾 **Сохранение в HealthKit** - Mindful Minutes + Workout
- 📊 **Экран завершения** - итоги сессии (длительность, средний пульс)
- 🔄 **Watch Connectivity** - синхронизация с iPhone ✅ **работает!**

### 🎉 Протестировано на реальных устройствах
- ✅ iPhone + Apple Watch (спаренные)
- ✅ Watch Connectivity: синхронизация работает
- ✅ Медитации с Watch появляются в истории iPhone
- ✅ Данные сохраняются в HealthKit + CloudKit (автоматическая синхронизация через iCloud)
- ✅ Пульс отслеживается и передается

### ⚠️ Известные ограничения
- **Watch Connectivity не работает в симуляторе** (только на реальных устройствах)

---

## 🛠 Технический стек

- **Platforms**: iOS 17.0+ • watchOS 10.0+
- **Language**: Swift 5.9+
- **UI**: SwiftUI
- **Backend**: CloudKit (SwiftData) - автоматическая синхронизация через iCloud
- **Health**: HealthKit (Mindful Minutes, Heart Rate, Workouts)
- **Connectivity**: WatchConnectivity (iPhone ↔ Watch sync)
- **Architecture**: MVVM
- **Concurrency**: async/await, Combine

---

## 🚀 Быстрый старт

### Требования

- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- Apple Developer Account ($99/год) - для CloudKit и TestFlight

### Установка

1. **Клонируй репозиторий:**
   ```bash
   git clone https://github.com/[username]/monotation.git
   cd monotation
   ```

2. **Открой проект в Xcode:**
   ```bash
   open monotation.xcodeproj
   ```

3. **Настрой CloudKit:**
   - CloudKit настроен автоматически через iCloud Capability
   - Container ID: `iCloud.com.neprokin.monotation`
   - Данные синхронизируются автоматически через iCloud
   - 📖 **Детали**: [docs/ARCHITECTURE_CURRENT.md](docs/ARCHITECTURE_CURRENT.md#cloudkit-текущая-конфигурация)

4. **Настрой Signing:**
   - В Xcode: Target → Signing & Capabilities
   - Выбери свой Team
   - Добавь capability "iCloud" (CloudKit настроится автоматически)
   - ⚠️ **Apple Sign In не требуется** - CloudKit использует iCloud аккаунт автоматически

5. **Запусти:**
   - `⌘ + R` для запуска на симуляторе

---

## 📂 Структура проекта (MVVM)

```
monotation/
├── monotation/                    # iOS App
│   ├── App/                       # Entry point
│   ├── Views/                     # SwiftUI UI
│   │   ├── Timer/
│   │   ├── Meditation/
│   │   └── History/
│   ├── ViewModels/                # Business logic
│   ├── Models/                    # Data models
│   │   ├── MeditationModel.swift  # SwiftData @Model для CloudKit
│   │   ├── Meditation.swift       # Struct (для обратной совместимости)
│   │   ├── MeditationPose.swift
│   │   └── MeditationPlace.swift
│   ├── Services/                  # Backend & System
│   │   ├── CloudKitService.swift  # CRUD с CloudKit (SwiftData)
│   │   ├── AuthService.swift      # Упрощённый (CloudKit использует iCloud автоматически)
│   │   ├── NotificationService.swift
│   │   └── ConnectivityManager.swift
│   └── App/                       # App configuration
│       └── ModelContainer.swift   # SwiftData ModelContainer для CloudKit
│
└── monotation Watch App Watch App/  # watchOS App
    ├── Views/
    │   ├── MainView.swift
    │   ├── ActiveMeditationView.swift
    │   ├── CompletionView.swift
    │   └── WatchSettingsView.swift
    ├── Services/
    │   ├── MeditationAlarmController.swift  # Smart Alarm
    │   ├── WorkoutManager.swift             # HealthKit
    │   └── ConnectivityManager.swift        # Watch ↔ iPhone
    └── Info.plist
```

📖 **Детальная архитектура**: [docs/ARCHITECTURE_CURRENT.md](docs/ARCHITECTURE_CURRENT.md)

---

## 🏗 Архитектура

### MVVM Pattern
- **Models**: Простые Swift structs (Codable, Identifiable)
- **Views**: SwiftUI views (декларативный UI)
- **ViewModels**: ObservableObject (@Published properties, business logic)
- **Services**: Actor/Class для backend и system интеграции

### Data Flow (iOS App)
```
User Action → View → ViewModel → CloudKitService → SwiftData/CloudKit
                ↑         ↓
            @Published  Update
```

📖 **Детальная архитектура проекта**: [docs/ARCHITECTURE_CURRENT.md](docs/ARCHITECTURE_CURRENT.md)

---

## 🔧 Разработка

### Workflow: Cursor + Xcode

**Hybrid Approach**: Cursor для написания кода + Xcode для тестирования

**Роли инструментов:**

**Cursor (AI Assistant):**
- ✅ Создаю новые `.swift` файлы
- ✅ Пишу SwiftUI Views, ViewModels, Models, Services
- ✅ Рефакторю код, исправляю ошибки
- ✅ Редактирую `Info.plist`, `Config.swift`

**Xcode (Твои действия):**
- ✅ **Build & Run** (`⌘+R`) - запуск приложения
- ✅ **SwiftUI Previews** - живой просмотр компонентов
- ✅ **Debugging** - брейкпоинты, консоль
- ✅ **Signing & Capabilities** - настройка сертификатов

**Типичный цикл:**
1. AI создает код в Cursor
2. Ты тестируешь в Xcode (`⌘+R`)
3. Фидбек → исправления → проверка
4. Git commit после каждой работающей фичи

### Git workflow

```bash
# Новая фича
git checkout -b feature/timer-screen
# ... разработка ...
git add .
git commit -m "feat: add timer screen with countdown"
git push origin feature/timer-screen
# Create Pull Request
```

### Commit Convention

Используем [Conventional Commits](https://www.conventionalcommits.org/):

```
feat:     новая функциональность
fix:      исправление бага
docs:     изменения в документации
style:    форматирование кода (не влияет на функциональность)
refactor: рефакторинг кода
test:     добавление тестов
chore:    обновление зависимостей, конфигурации
perf:     улучшение производительности
```

**Примеры:**
```bash
git commit -m "feat: add meditation timer with countdown"
git commit -m "fix: resolve PostgreSQL INTERVAL decoding issue"
git commit -m "docs: update README with setup instructions"
git commit -m "refactor: extract MeditationDetailView to separate file"
```

### Горячие клавиши Xcode

```
⌘ + R          Build & Run
⌘ + .          Stop
⌘ + B          Build only
⌘ + Shift + K  Clean Build Folder
⌘ + Shift + Y  Show/Hide Console
⌘ + Shift + O  Open Quickly (найти файл)
```

### Troubleshooting

**Xcode не видит новые файлы:**
- Перетащи файл в Xcode Project Navigator вручную
- Или: File → Add Files to "monotation"

**Preview не работает:**
- ⌘ + Option + P (Resume Preview)
- Product → Clean Build Folder (⌘ + Shift + K)

**Build ошибка:**
- Прочитай ошибку в Issue Navigator (⌘ + 5)
- Скопируй ошибку в Cursor для исправления

---

## 📖 Документация

### Основная документация
- [docs/ARCHITECTURE_CURRENT.md](docs/ARCHITECTURE_CURRENT.md) - Полная архитектура проекта (MVVM, iOS App, Watch App, Smart Alarm)
- [docs/HAPTIC_COMPLETION_ISSUE.md](docs/HAPTIC_COMPLETION_ISSUE.md) - История решения проблемы haptic (архив)

### Настройка и разработка
- [docs/PRODUCTION_RELEASE.md](docs/PRODUCTION_RELEASE.md) - Подготовка к релизу в TestFlight и App Store

### Референс
- [docs/reference/REFERENCE_APPLE_HEALTH_ADA.md](docs/reference/REFERENCE_APPLE_HEALTH_ADA.md) - Референс Apple Health и ADA критерии

📚 **Полный индекс документации**: [docs/README.md](docs/README.md)

---

## 🗺 Roadmap

### ✅ v1.0 - MVP - Завершено
- [x] iOS App: Таймер, сохранение, история
- [x] Монохромный дизайн
- [x] Тестирование всех функций

### ✅ v2.0 - Smart Alarm + CloudKit Migration - Завершено
- [x] Watch App с Smart Alarm архитектурой
- [x] Гарантированные haptic уведомления в AOD режиме
- [x] Мониторинг пульса (HKWorkoutSession)
- [x] Синхронизация Watch ↔ iPhone
- [x] Fallback уведомления на iPhone
- [x] Миграция с Supabase на CloudKit
- [x] SwiftData модели для CloudKit
- [x] Автоматическая синхронизация через iCloud
- [x] Полная документация архитектуры

### 📋 v2.1 - Polish & Release
**Цель**: Подготовка к App Store
- [ ] TestFlight Internal Testing
- [ ] App Store Connect setup
- [ ] TestFlight бета-тестирование
- [ ] App Store Review

### 📋 v3.0 - Улучшения UX
**Цель**: Расширенная функциональность
- [ ] Редактирование/удаление медитаций
- [ ] Базовая статистика (стрики, графики)
- [ ] Фильтры и поиск в истории
- [ ] Настройки (Settings screen)
- [ ] iPad support

### 🚀 v4.0 - AI Integration
**Цель**: Интеллектуальный анализ
- [ ] AI-анализ паттернов медитации (markdown → insights)
- [ ] Персональные рекомендации
- [ ] Еженедельные/месячные отчеты
- [ ] Экспорт данных (CSV, PDF)

---

## 🎯 Текущий статус проекта

**Фаза**: v2.0 - CloudKit Migration ✅ Complete

**Что работает:**
- ✅ **Watch App**: Полностью переписан с Smart Alarm архитектурой
- ✅ **iPhone App**: Очищен от legacy кода, все функции работают
- ✅ **Smart Alarm**: Гарантированные haptic уведомления в AOD режиме
- ✅ **Вариант A**: Автоматический CompletionView при системном "Остановить"
- ✅ **Countdown**: Работает на обоих платформах (4 секунды: 🧘 → 3 → 2 → 1)
- ✅ **Синхронизация**: Watch ↔ iPhone через WatchConnectivity
- ✅ **CloudKit**: Миграция завершена, данные синхронизируются через iCloud
- ✅ **Fallback уведомления**: Time-sensitive на iPhone
- ✅ **Background execution**: Работает на обоих платформах

**Технические детали:**
- ✅ Smart Alarm планируется ДО workout session (критично!)
- ✅ WKBackgroundModes: только `alarm` (не `mindfulness`)
- ✅ Timer с RunLoop.main.add(..., forMode: .common)
- ✅ CloudKit с SwiftData для автоматической синхронизации
- ✅ Полная документация архитектуры и UX/UI

**Следующие шаги:**
1. TestFlight Internal Testing
2. Подготовка к релизу в App Store
3. App Store Review

📖 **План релиза**: [docs/PRODUCTION_RELEASE.md](docs/PRODUCTION_RELEASE.md)

---

## 🤝 Contributing

Contributions welcome! Пожалуйста:
1. Fork проект
2. Создай feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit изменения (`git commit -m 'feat: add amazing feature'`)
4. Push в branch (`git push origin feature/AmazingFeature`)
5. Открой Pull Request

---

## 📄 License

MIT License - см. [LICENSE](LICENSE) для деталей.

---

## 🙏 Acknowledgments

- [Cursor](https://cursor.com) - AI-powered IDE
- [CloudKit](https://developer.apple.com/documentation/cloudkit) - Backend platform
- [SwiftUI](https://developer.apple.com/xcode/swiftui/) - UI framework

---

**Последнее обновление**: 9 января 2026  
**Версия**: 2.0 (CloudKit Migration Complete)  
**GitHub**: [github.com/neprokin/monotation](https://github.com/neprokin/monotation)

