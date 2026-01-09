# 🏗️ Архитектура проекта

## 📋 Цель документа

Этот документ описывает **полную архитектуру проекта monotation**, включая:
- Общую архитектуру (MVVM, структура проекта, iOS App, Watch App)
- Smart Alarm решение для Apple Watch (детальное описание)
- CloudKit конфигурацию и синхронизацию данных

**Статус**: ✅ Все описанные компоненты реализованы в v2.0

---

## 📐 Общая архитектура проекта

### Архитектурный паттерн: MVVM

**iOS App**:
```
Views (SwiftUI) → ViewModels (ObservableObject) → Services → CloudKit (SwiftData)
```

**Watch App**:
```
Views (SwiftUI) → Services (MeditationAlarmController, WorkoutManager) → HealthKit/WatchConnectivity
```

### Структура проекта

```
monotation/
├── monotation/                    # iOS App
│   ├── App/                       # Entry point
│   │   └── monotationApp.swift    # @main
│   ├── Views/                     # SwiftUI UI
│   │   ├── Timer/
│   │   ├── Meditation/
│   │   └── History/
│   ├── ViewModels/                # Business logic
│   │   ├── TimerViewModel.swift
│   │   ├── MeditationFormViewModel.swift
│   │   └── HistoryViewModel.swift
│   ├── Models/                    # Data models
│   │   ├── MeditationModel.swift  # SwiftData @Model для CloudKit
│   │   ├── Meditation.swift       # Struct (для обратной совместимости)
│   │   ├── MeditationPose.swift
│   │   └── MeditationPlace.swift
│   ├── Services/                  # Backend & System
│   │   ├── CloudKitService.swift  # CRUD с CloudKit (SwiftData)
│   │   ├── AuthService.swift      # Упрощённый (CloudKit использует iCloud автоматически)
│   │   ├── ObsidianService.swift  # Интеграция с Obsidian (Markdown файлы)
│   │   ├── NotificationService.swift  # Time-sensitive уведомления
│   │   └── ConnectivityManager.swift  # Watch ↔ iPhone sync
│   └── App/                       # App configuration
│       └── ModelContainer.swift   # SwiftData ModelContainer для CloudKit
│
└── monotation Watch App Watch App/  # watchOS App
    ├── Views/
    │   ├── MainView.swift         # Главный экран + countdown
    │   ├── ActiveMeditationView.swift  # Активная медитация
    │   ├── CompletionView.swift   # Экран завершения
    │   └── WatchSettingsView.swift
    ├── Services/
    │   ├── MeditationAlarmController.swift  # Smart Alarm (WKExtendedRuntimeSession)
    │   ├── WorkoutManager.swift   # HKWorkoutSession для HR tracking
    │   └── ConnectivityManager.swift  # Watch ↔ iPhone sync
    └── Info.plist
```

### Data Flow

**iOS App (MVVM)**:
```
User Action → View → ViewModel → CloudKitService → SwiftData/CloudKit
                ↑         ↓
            @Published  Update
```

**Watch App**:
```
User Action → View → Service (AlarmController/WorkoutManager) → HealthKit/WatchConnectivity
```

### Ключевые компоненты

**iOS App**:
- **Views**: SwiftUI декларативный UI
  - `TimerView` - главный экран с таймером
  - `MeditationFormView` - форма сохранения медитации
  - `HistoryView` - история медитаций
- **ViewModels**: ObservableObject с @Published properties, бизнес-логика для UI
  - `TimerViewModel` - логика таймера, background tasks
  - `MeditationFormViewModel` - валидация и сохранение
  - `HistoryViewModel` - загрузка истории из CloudKit
- **Services**: Actor/Class для backend и system интеграции
  - `CloudKitService` - CRUD операции с CloudKit через SwiftData
  - `AuthService` - Упрощённый (CloudKit использует iCloud автоматически)
  - `ObsidianService` - Интеграция с Obsidian (автоматическое добавление медитаций в Markdown файл)
  - `NotificationService` - Time-sensitive уведомления (fallback)
  - `ConnectivityManager` - синхронизация с Watch App
- **Models**: SwiftData @Model для CloudKit + Swift structs для обратной совместимости
  - `MeditationModel` - SwiftData @Model для CloudKit синхронизации
  - `Meditation` - Swift struct (для обратной совместимости)
  - `MeditationPose`, `MeditationPlace` - enums

**Watch App**:
- **Views**: SwiftUI декларативный UI
  - `MainView` - главный экран + countdown
  - `ActiveMeditationView` - активная медитация с таймером
  - `CompletionView` - экран завершения
  - `WatchSettingsView` - настройки
- **Services**: 
  - `MeditationAlarmController` - Smart Alarm управление (WKExtendedRuntimeSession)
  - `WorkoutManager` - HKWorkoutSession для HR tracking и Extended Runtime
  - `ConnectivityManager` - синхронизация с iPhone App

### Синхронизация Watch ↔ iPhone

**WatchConnectivity (WCSession)**:
- Watch App отправляет данные медитации в iPhone App
- iPhone App сохраняет в CloudKit (через SwiftData) и HealthKit
- Работает только на реальных устройствах (не в симуляторе)

**Поток синхронизации**:
```
Watch App (CompletionView)
    ↓
ConnectivityManager.sendMeditation()
    ↓
WCSession.sendMessage()
    ↓
iPhone App (ConnectivityManager.receiveMessage())
    ↓
CloudKitService.insertMeditation()
    ↓
SwiftData/CloudKit (автоматическая синхронизация через iCloud)
    ↓
HealthKit сохранение
```

### Backend и хранение данных

**Текущее решение**:
- ✅ **CloudKit** (SwiftData) - основное хранилище данных
  - Автоматическая синхронизация через iCloud
  - Встроенная авторизация через iCloud аккаунт
  - Оффлайн-первый (работает без интернета)
  - Данные синхронизируются между iPhone/Watch/iPad автоматически
- **HealthKit** - для Mindful Minutes и Workout данных
- **UserDefaults** - для persisted Smart Alarm (endDate)

**CloudKit настройка**:
- Container ID: `iCloud.com.neprokin.monotation`
- Database: Private Database (автоматически)
- Zone: `com.apple.coredata.cloudkit.zone` (SwiftData автоматически)
- Record Type: `CD_MeditationModel` (префикс `CD_` добавляется SwiftData)

**Проверка данных в CloudKit Dashboard**:
1. [icloud.developer.apple.com](https://icloud.developer.apple.com)
2. Container: `iCloud.com.neprokin.monotation`
3. Data → Records
4. Выбрать: **Private Database** + **`com.apple.coredata.cloudkit.zone`**
5. Использовать: **"Fetch Changes"** (не "Query Records")

### Интеграция с Obsidian

**Назначение**: Автоматическое добавление медитаций в Markdown файл для анализа в Obsidian.

**Реализация**:
- `ObsidianService` - сервис для работы с Markdown файлами
- Автоматическая синхронизация после сохранения медитации в CloudKit
- Дедупликация по дате и времени
- Поддержка iCloud Drive файлов через security-scoped bookmarks

**Настройка**:
- Путь к файлу настраивается в Settings → "Интеграция с Obsidian"
- Используется нативный `.fileImporter()` для выбора файла из iCloud Drive
- Файл должен быть в формате Markdown (`sessions.md`)

**Формат записи**:
```markdown
### DD Month
- **HH:MM** — X минут
- **Поза**: [Поза]
- **Место**: [Место]
- **Заметки**:
  - [Заметка 1]
  - [Заметка 2]
```

**Особенности**:
- Автоматическое создание заголовков месяца и дня, если их нет
- Вставка записей в правильное место (хронологический порядок)
- Дедупликация предотвращает дублирование записей
- Работает с файлами в iCloud Drive

---

## 🎯 Smart Alarm архитектура (Watch App)

### Три контура гарантии

```
┌─────────────────────────────────────────────────────────────────┐
│ КОНТУР 1 (ЕДИНСТВЕННАЯ ГАРАНТИЯ): Smart Alarm (Watch)          │
│ - WKExtendedRuntimeSession с WKBackgroundModes = alarm          │
│ - Планируется ДО workout session (когда app активна)            │
│ - notifyUser(hapticType:repeatHandler:) для повторяющегося     │
│   haptic каждые 2 секунды                                       │
│ - Системный UI с кнопками "Открыть" и "Остановить"              │
│ - Работает в AOD/wrist-down режиме                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ КОНТУР 2 (FALLBACK): Time-Sensitive Notification (iPhone)       │
│ - Одно уведомление на endDate                                   │
│ - interruptionLevel = .timeSensitive                           │
│ - Резерв на случай если Watch недоступен                       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ КОНТУР 3 (ВИЗУАЛЬНЫЙ): Timer для UI (Watch)                     │
│ - Timer каждую секунду для отображения обратного отсчёта        │
│ - RunLoop.main.add(timer, forMode: .common)                     │
│ - НЕ для гарантии уведомления — только для UX!                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📁 Ключевые компоненты

### 1. MeditationAlarmController

**Файл**: `MeditationAlarmController.swift`

**Роль**: Управление Smart Alarm session

**Ключевые методы**:
- `scheduleAlarm(at: Date)` - планирует Smart Alarm на конкретное время
- `cancelAlarm()` - отменяет Smart Alarm
- `rescheduleAlarm(at: Date)` - перепланирует Smart Alarm (для pause/resume)
- `checkForPersistedAlarm()` - проверяет persisted alarm при запуске (очищает, т.к. медитация не активна)

**Состояние**:
- `@Published var isAlarmActive: Bool` - активен ли alarm
- `@Published var scheduledEndDate: Date?` - запланированное время завершения
- `@Published var wasStoppedBySystem: Bool` - был ли остановлен через системный UI

**WKExtendedRuntimeSessionDelegate**:
- `extendedRuntimeSessionDidStart(_:)` - вызывается в `endDate`, запускает `notifyUser(...repeat...)`
- `extendedRuntimeSessionWillExpire(_:)` - предупреждение об истечении сессии
- `extendedRuntimeSession(_:didInvalidateWith:error:)` - обработка инвалидации, определение `wasStoppedBySystem`

**Критически важно**:
- Smart Alarm планируется в `MainView.startCountdown()` **ДО** workout session
- При инвалидации с `reason == .none` → `wasStoppedBySystem = true`
- `notifyUser` возвращает `2.0` секунды для повторения haptic

---

### 2. WorkoutManager

**Файл**: `WorkoutManager.swift`

**Роль**: Управление HKWorkoutSession для Extended Runtime Session

**Ключевые методы**:
- `startWorkout() async throws` - запускает workout session
- `endWorkout()` - завершает workout session
- `finishWorkout() async` - сохраняет workout в HealthKit

**Важно**:
- `HKWorkoutSession` автоматически активирует Extended Runtime Session
- Это **единственный надёжный способ** получить Extended Runtime Session на watchOS
- Используется для HR tracking и для активации background execution

**Конфигурация**:
- `activityType = .mindAndBody`
- `locationType = .indoor`
- Авторизация для `HKCategoryType(.mindfulSession)`

---

### 3. MainView

**Файл**: `MainView.swift`

**Роль**: Главный экран и countdown

**Ключевая логика**:

1. **startCountdown()**:
   ```swift
   // 1. Планируем Smart Alarm ДО workout session (критично!)
   let endDate = Date() + countdownDuration (4s) + meditationDuration
   alarmController.scheduleAlarm(at: endDate)
   
   // 2. Запускаем workout session (активирует Extended Runtime)
   try await workoutManager.startWorkout()
   
   // 3. Запускаем countdown timer
   startCountdownTimer()
   ```

2. **startCountdownTimer()**:
   - Создаёт `Timer(timeInterval: 1.0, repeats: true)`
   - Добавляет в `RunLoop.main.add(timer, forMode: .common)`
   - Обновляет `countdownPhase` каждую секунду (0 → 1 → 2 → 3)
   - После фазы 3 → `navigateToMeditation = true`

3. **Countdown phases**:
   - Phase 0: 🧘 (emoji, size 60)
   - Phase 1: "3" (size 80, light, rounded)
   - Phase 2: "2"
   - Phase 3: "1"
   - После phase 3: переход к `ActiveMeditationView`

**Анимации**:
- `withAnimation { countdownPhase = newValue }`
- `.id(countdownPhase)` для плавной смены
- `.transition(.scale.combined(with: .opacity))`

---

### 4. ActiveMeditationView

**Файл**: `ActiveMeditationView.swift`

**Роль**: Экран активной медитации

**Ключевая логика**:

1. **startTimer()**:
   ```swift
   // 1. Haptic feedback при старте
   WKInterfaceDevice.current().play(.start)
   
   // 2. Проверяем, не запланирован ли уже Smart Alarm
   if !alarmController.isAlarmActive {
       alarmController.scheduleAlarm(at: endDate) // fallback
   }
   
   // 3. Запускаем визуальный Timer (только для UI)
   let timer = Timer(timeInterval: 1.0, repeats: true) { _ in
       // Обновляем timeRemaining каждую секунду
   }
   RunLoop.main.add(timer, forMode: .common)
   ```

2. **pauseTimer()**:
   - Останавливает визуальный Timer
   - Отменяет Smart Alarm: `alarmController.cancelAlarm()`

3. **resumeTimer()**:
   - Пересчитывает `newEndDate = Date() + timeRemaining`
   - Перепланирует Smart Alarm: `alarmController.scheduleAlarm(at: newEndDate)`
   - Перезапускает визуальный Timer

4. **stopTimer()**:
   - Останавливает визуальный Timer
   - Отменяет Smart Alarm: `alarmController.cancelAlarm()`
   - Если медитация > 3 сек → показывает `CompletionView`
   - Иначе → возврат к `MainView`

5. **timerCompleted()**:
   - Останавливает визуальный Timer
   - Завершает workout: `workoutManager.endWorkout()`
   - **НЕ отменяет Smart Alarm!** (он должен сработать)
   - Устанавливает `isWaitingForAcknowledgment = true`

6. **acknowledgeMeditationCompletion()**:
   - Отменяет Smart Alarm: `alarmController.cancelAlarm()`
   - Показывает `CompletionView`

7. **checkAndHandleSystemStop()** (Вариант A):
   - Проверяет `alarmController.wasStoppedBySystem`
   - Если `true` → автоматически показывает `CompletionView`
   - Вызывается в `onAppear` и через `onChange(of: wasStoppedBySystem)`

**Состояния**:
- Активная медитация: таймер работает, кнопки Pause/Stop
- Пауза: таймер остановлен, кнопка Play
- Ожидание подтверждения: таймер завершён, кнопка "Завершить"
- Завершение: показывается `CompletionView`

---

### 5. CompletionView

**Файл**: `CompletionView.swift`

**Роль**: Экран завершения медитации

**Функциональность**:
- Показывает статистику (длительность, пульс, время)
- Синхронизирует данные с iPhone через `ConnectivityManager`
- Показывает статус синхронизации (синхронизация/ошибка/успех)
- Кнопка "Готово" для возврата к `MainView`

---

## 🔄 Потоки данных

### Поток 1: Планирование Smart Alarm

```
MainView.startCountdown()
    ↓
alarmController.scheduleAlarm(at: endDate)
    ↓
WKExtendedRuntimeSession.start(at: endDate)
    ↓
Система сохраняет scheduled session
    ↓
(медитация работает...)
    ↓
endDate наступает
    ↓
extendedRuntimeSessionDidStart()
    ↓
session.notifyUser(hapticType: .notification) { repeatHandler }
    ↓
Повторяющийся haptic каждые 2 секунды
```

### Поток 2: Остановка через системный UI (Вариант A)

```
Пользователь нажимает "Остановить" на системном UI
    ↓
extendedRuntimeSession(_:didInvalidateWith:reason:.none)
    ↓
wasStoppedBySystem = true
    ↓
Приложение открывается (через "Открыть" или автоматически)
    ↓
ActiveMeditationView.onAppear
    ↓
checkAndHandleSystemStop()
    ↓
if wasStoppedBySystem → showCompletion = true
    ↓
CompletionView показывается автоматически
```

### Поток 3: Пауза и возобновление

```
pauseTimer()
    ↓
timer.invalidate()
    ↓
alarmController.cancelAlarm()
    ↓
(пользователь ждёт...)
    ↓
resumeTimer()
    ↓
newEndDate = Date() + timeRemaining
    ↓
alarmController.scheduleAlarm(at: newEndDate)
    ↓
Новый Timer запускается
```

---

## 🔧 Технические детали

### Info.plist (Watch)

```xml
<key>WKBackgroundModes</key>
<array>
    <string>alarm</string>
</array>
<key>CFBundleDisplayName</key>
<string>Медитация</string>
```

**Критически важно**:
- Только `alarm`, не `mindfulness` (конфликтуют)
- `CFBundleDisplayName` для кастомизации названия на системном UI

### Timer с RunLoop

```swift
let timer = Timer(timeInterval: 1.0, repeats: true) { _ in
    Task { @MainActor in
        // Обновление UI
    }
}
RunLoop.main.add(timer, forMode: .common)
```

**Почему `.common` mode**:
- Работает даже когда экран заблокирован
- Работает в background режиме (когда Extended Runtime Session активна)

### Smart Alarm notifyUser

```swift
session.notifyUser(hapticType: .notification) { nextHaptic in
    nextHaptic.pointee = .notification
    return 2.0  // Повторять каждые 2 секунды
}
```

**Поведение**:
- Первый haptic сразу при `extendedRuntimeSessionDidStart`
- Затем повторяется каждые 2 секунды
- Продолжается до инвалидации сессии (пользователь нажал "Остановить")

---

## ⚠️ Критически важные моменты

### 1. Планирование Smart Alarm ДО workout session

**Проблема**: Smart Alarm требует, чтобы приложение было активным (foreground) при планировании.

**Решение**: Планируем в `MainView.startCountdown()` синхронно, **ДО** `Task { @MainActor in }` с workout session.

```swift
// ✅ ПРАВИЛЬНО
func startCountdown() {
    let endDate = Date() + countdownDuration + meditationDuration
    alarmController.scheduleAlarm(at: endDate)  // Синхронно, ДО Task
    
    Task { @MainActor in
        try await workoutManager.startWorkout()
        startCountdownTimer()
    }
}

// ❌ НЕПРАВИЛЬНО
func startCountdown() {
    Task { @MainActor in
        try await workoutManager.startWorkout()
        alarmController.scheduleAlarm(at: endDate)  // Может быть слишком поздно!
    }
}
```

### 2. Persisted alarm при запуске

**Проблема**: При запуске приложения медитация не активна, но persisted alarm может остаться.

**Решение**: Очищаем persisted alarm при запуске в `checkForPersistedAlarm()`.

```swift
func checkForPersistedAlarm() {
    // Всегда очищаем при запуске - медитация не активна
    UserDefaults.standard.removeObject(forKey: endDateKey)
    scheduledEndDate = nil
}
```

### 3. Определение остановки пользователем

**Проблема**: Нужно определить, нажал ли пользователь "Остановить" на системном UI.

**Решение**: Проверяем `reason == .none` (не `.resignedFrontmost`, т.к. это может быть при открытии приложения).

```swift
if reason == .none {
    wasStoppedBySystem = true  // Пользователь нажал "Остановить"
}
```

### 4. Вариант A: Автоматический показ CompletionView

**Проблема**: После нажатия "Остановить" пользователь попадает в приложение, но нужно ещё нажать "Завершить".

**Решение**: Отслеживаем `wasStoppedBySystem` и автоматически показываем `CompletionView`.

```swift
.onAppear {
    checkAndHandleSystemStop()  // Проверяем при появлении
}
.onChange(of: alarmController.wasStoppedBySystem) { oldValue, newValue in
    if newValue {
        checkAndHandleSystemStop()  // И при изменении флага
    }
}
```

---

## 📊 State Machine

### MainView

```
Idle (countdownPhase == -1)
    ↓ [Play button]
Countdown (countdownPhase >= 0)
    ↓ [4 секунды]
ActiveMeditationView (fullScreenCover)
```

### ActiveMeditationView

```
Active (!isPaused && !isWaitingForAcknowledgment)
    ↓ [Pause]          ↓ [Timer completed]
Paused (isPaused)      Waiting (isWaitingForAcknowledgment)
    ↓ [Resume]              ↓ [Завершить] или [Smart Alarm Stop]
Active                  CompletionView
    ↓ [Stop]
CompletionView (if > 3 сек) или MainView
```

### Smart Alarm

```
Scheduled (isAlarmActive == true)
    ↓ [endDate наступает]
Active (extendedRuntimeSessionDidStart)
    ↓ [notifyUser запущен]
Repeating Haptic (каждые 2 сек)
    ↓ [Пользователь нажимает "Остановить"]
Invalidated (wasStoppedBySystem == true)
    ↓
CompletionView (автоматически)
```

---

## 🔍 Логирование

### Ключевые логи для отладки

**MeditationAlarmController**:
- `🔔 [Alarm] Scheduling alarm for ...`
- `✅ [Alarm] Alarm scheduled for ...`
- `🎯 [Alarm] Session STARTED - meditation time is up!`
- `📳 [Alarm] Playing haptic, next in 2.0s`
- `👆 [Alarm] Session invalidated - reason: X, userStopped: true/false`
- `✅ [Alarm] User stopped alarm via system UI 'Stop' button`

**MainView**:
- `🎬 COUNTDOWN START - Function called`
- `📅 [MainView] Smart Alarm scheduled for ... (BEFORE workout session)`
- `⏱️ COUNTDOWN PHASE X SET`
- `✅ COUNTDOWN COMPLETED - Starting meditation`

**ActiveMeditationView**:
- `🎯 [ActiveMeditation] Starting meditation timer`
- `📅 [ActiveMeditation] Smart Alarm already scheduled (from MainView)`
- `⏰ [ActiveMeditation] Timer COMPLETED`
- `🔍 [ActiveMeditation] Checking wasStoppedBySystem: true/false`
- `✅ [ActiveMeditation] User stopped via system UI - showing completion immediately`

---

## ✅ Чеклист для переписывания

При переписывании с нуля необходимо сохранить:

### Архитектура
- [ ] Три контура гарантии (Smart Alarm, iPhone fallback, UI Timer)
- [ ] Планирование Smart Alarm ДО workout session
- [ ] Workout Session для активации Extended Runtime
- [ ] Timer с RunLoop.main.add(..., forMode: .common)
- [ ] notifyUser с repeatHandler (2 секунды)
- [ ] Вариант A: автоматический показ CompletionView

### Компоненты
- [ ] MeditationAlarmController с wasStoppedBySystem
- [ ] WorkoutManager с async startWorkout()
- [ ] MainView с countdown логикой
- [ ] ActiveMeditationView с pause/resume/stop
- [ ] CompletionView с синхронизацией

### Логика
- [ ] Countdown: 4 фазы (🧘, 3, 2, 1)
- [ ] Smart Alarm планирование в MainView.startCountdown()
- [ ] Определение остановки через reason == .none
- [ ] Очистка persisted alarm при запуске
- [ ] Перепланирование при pause/resume

### Info.plist
- [ ] WKBackgroundModes: только `alarm`
- [ ] CFBundleDisplayName: "Медитация"

---

## 📝 Примечания

1. **ExtendedRuntimeManager** (legacy): больше не используется напрямую, т.к. `HKWorkoutSession` автоматически активирует Extended Runtime Session.

2. **NotificationDelegate**: не используется на Watch (только на iPhone для fallback).

3. **Local Notifications на Watch**: НЕ используются (конфликтуют с Smart Alarm).

4. **Timer vs Smart Alarm**: Timer только для UI, Smart Alarm для гарантии уведомления.

5. **Вариант A**: улучшает UX, но требует отслеживания `wasStoppedBySystem` через `onAppear` и `onChange`.

---

---

## 📚 См. также

- [README.md](../README.md) - Главная документация проекта
- [PRODUCTION_RELEASE.md](PRODUCTION_RELEASE.md) - Подготовка к релизу в TestFlight и App Store

---

**Дата создания**: 2026-01-08  
**Последнее обновление**: 2026-01-09  
**Версия**: 2.1  
**Статус**: ✅ Полная документация архитектуры проекта (общая + Smart Alarm + CloudKit + Obsidian интеграция)
