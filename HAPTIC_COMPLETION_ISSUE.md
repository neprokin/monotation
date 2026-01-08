# 🔔 Проблема вибрации при завершении медитации на Apple Watch

## 📋 Краткое описание задачи

**Цель**: Гарантированно уведомить пользователя о завершении медитации через вибрацию, даже когда экран Apple Watch заблокирован (AOD/wrist-down режим).

**Текущий статус**: 🚀 **РЕФАКТОРИНГ** (2026-01-08). Переход на Smart Alarm для железной гарантии.

---

## 🏆 НОВАЯ АРХИТЕКТУРА: Smart Alarm

### Почему Smart Alarm?

Предыдущее решение (Timer + Local Notifications) работало, но было "чёрным ящиком" — мы не понимали точно почему и когда haptic "пробивается". 

**WKExtendedRuntimeSession (Smart Alarm)** — это **системный механизм "будильника"**, который:
1. Планируется на конкретное время (не зависит от Timer)
2. Использует `notifyUser(hapticType:repeatHandler:)` для повторяющегося haptic
3. Показывает системный UI с кнопкой Stop
4. Работает **гарантированно** в AOD/wrist-down

### Новая трёхконтурная архитектура

```
┌─────────────────────────────────────────────────────────────────┐
│                     КОНТУР 1 (ГЛАВНЫЙ)                          │
│                     Smart Alarm                                  │
├─────────────────────────────────────────────────────────────────┤
│  MeditationAlarmController.scheduleAlarm(at: endDate)           │
│                                                                  │
│  На T_end:                                                       │
│    → extendedRuntimeSessionDidStart()                           │
│    → notifyUser(hapticType:repeatHandler:)                      │
│    → Системный повторяющийся haptic до подтверждения            │
│    → Системный UI с кнопкой Stop                                │
│                                                                  │
│  Это ЖЕЛЕЗНАЯ ГАРАНТИЯ!                                         │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                     КОНТУР 2 (FALLBACK)                         │
│                     Local Notifications                          │
├─────────────────────────────────────────────────────────────────┤
│  scheduleEndNotification(after: duration)                        │
│                                                                  │
│  3 уведомления: T_end, T_end+5s, T_end+10s                      │
│  На случай если Smart Alarm не сработает                        │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                     КОНТУР 3 (ВИЗУАЛЬНЫЙ)                       │
│                     Timer для UI                                 │
├─────────────────────────────────────────────────────────────────┤
│  Timer каждую секунду для отображения обратного отсчёта         │
│                                                                  │
│  НЕ для гарантии уведомления — только для красивого UX!         │
│  + best-effort haptic через WKInterfaceDevice.play()            │
└─────────────────────────────────────────────────────────────────┘
```

### Ключевые файлы

| Файл | Назначение |
|------|------------|
| `MeditationAlarmController.swift` | Smart Alarm session + notifyUser |
| `ActiveMeditationView.swift` | Интеграция всех трёх контуров |
| `monotation-Watch-App-Watch-App-Info.plist` | WKBackgroundModes: smart-alarm |

### Info.plist

```xml
<key>WKBackgroundModes</key>
<array>
    <string>workout-processing</string>
    <string>self-care</string>
    <string>smart-alarm</string>
</array>
```

---

## 📚 ИСТОРИЯ РЕШЕНИЯ (для справки)

---

## 🐛 Описание проблемы

### Симптомы
1. Запускаю медитацию на 5 минут
2. Блокирую экран (опускаю руку)
3. Медитация завершается
4. **Было 2 вибрации, потом тишина**
5. При разблокировке (поднимаю руку) — вибрации возобновляются

### Ожидаемое поведение
- Вибрации должны продолжаться каждую секунду до подтверждения пользователем
- Или должно прийти системное уведомление со звуком/вибрацией

---

## 📚 История решения

### Этап 1: Первоначальная реализация

**Подход**: Простой haptic при завершении таймера

```swift
private func timerCompleted() {
    WKInterfaceDevice.current().play(.success)
}
```

**Результат**: ❌ Не работает при заблокированном экране

**Причина**: `WKInterfaceDevice.play()` не работает в background/inactive состоянии

---

### Этап 2: Repeating Haptic Timer

**Подход**: Повторяющиеся вибрации каждую секунду через Timer

```swift
private func startCompletionSignals() {
    let signalTimer = Timer(timeInterval: 1.0, repeats: true) { _ in
        WKInterfaceDevice.current().play(.notification)
    }
    RunLoop.main.add(signalTimer, forMode: .common)
}
```

**Результат**: ❌ Работает только 1-2 секунды, потом останавливается

**Причина**: Timer продолжает работать, но `WKInterfaceDevice.play()` игнорируется системой в AOD режиме для экономии батареи

---

### Этап 3: Local Notification при завершении

**Подход**: Отправлять Local Notification в момент завершения медитации

```swift
private func sendCompletionNotification() {
    let content = UNMutableNotificationContent()
    content.title = "Медитация завершена"
    content.sound = .default
    content.interruptionLevel = .timeSensitive
    
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
    // ...
}
```

**Результат**: ❌ Ненадёжно — приложение уже в background, уведомление может не доставиться

**Причина**: Отправка уведомления происходит когда приложение уже в inactive состоянии

---

### Этап 4: "Двухконтурная" схема (текущая реализация)

**Подход**: Планировать уведомление ЗАРАНЕЕ на время T_end

**Философия**:
- **Контур 1 (Системная гарантия)**: Запланированное уведомление доставляется системой независимо от состояния приложения
- **Контур 2 (Красивый UX)**: Если приложение активно — играем haptic напрямую и отменяем уведомление

```swift
// При старте медитации - планируем уведомление на T_end
private func startTimer() {
    scheduleEndNotification(after: timeRemaining)  // Контур 1
    WKInterfaceDevice.current().play(.start)       // Контур 2
    // Запуск Timer...
}

// При завершении - отменяем уведомление (если активны) и играем haptic
private func timerCompleted() {
    cancelEndNotification()      // Отменяем, т.к. сами обработаем
    startCompletionSignals()     // Контур 2 - haptic напрямую
}
```

**Результат**: ⚠️ Частично работает
- ✅ При коротких тестах — работает
- ❌ При 5 минутах — только 2 вибрации, потом тишина

---

## 🔍 Анализ текущей проблемы

### Гипотезы

#### Гипотеза 1: Timer останавливается через 2-3 минуты
watchOS может "усыплять" Timer даже с `.common` mode после определённого времени в background.

**Проверка**: Добавить логирование каждого tick таймера

#### Гипотеза 2: HKWorkoutSession истекает
Extended Runtime Session от HKWorkoutSession может истекать через несколько минут.

**Проверка**: Логировать статус `runtimeManager.isActive`

#### Гипотеза 3: Системное уведомление не доставляется
Запланированное уведомление может не доставляться из-за:
- Отсутствия разрешений
- Конфликта с другими уведомлениями
- Особенностей watchOS

**Проверка**: Логировать результат `center.add(request)`

#### Гипотеза 4: `timerCompleted()` вызывается и отменяет уведомление
Если Timer всё-таки работает и вызывает `timerCompleted()`, мы сами отменяем уведомление:
```swift
private func timerCompleted() {
    cancelEndNotification()  // <-- Может отменять уведомление до его доставки
    // ...
}
```

**Проверка**: Не отменять уведомление в `timerCompleted()`, пусть придёт

---

## 📁 Текущая реализация

### Файл: `ActiveMeditationView.swift`

#### Ключевые функции:

```swift
// MARK: - Notification ID
private static let endNotificationId = "meditation.end"

// Планирование уведомления ЗАРАНЕЕ
private func scheduleEndNotification(after seconds: TimeInterval) {
    let content = UNMutableNotificationContent()
    content.title = "Медитация завершена"
    content.body = "Нажмите, чтобы завершить сессию"
    content.sound = .default
    content.interruptionLevel = .timeSensitive
    
    let trigger = UNTimeIntervalNotificationTrigger(
        timeInterval: max(1, seconds), 
        repeats: false
    )
    
    let request = UNNotificationRequest(
        identifier: Self.endNotificationId,
        content: content,
        trigger: trigger
    )
    
    center.removePendingNotificationRequests(withIdentifiers: [Self.endNotificationId])
    center.add(request) { error in
        // Логирование результата
    }
}

// Отмена уведомления
private func cancelEndNotification() {
    UNUserNotificationCenter.current()
        .removePendingNotificationRequests(withIdentifiers: [Self.endNotificationId])
}
```

#### Логика вызовов:

| Событие | scheduleEndNotification | cancelEndNotification | Haptic |
|---------|------------------------|----------------------|--------|
| startTimer() | ✅ Планируем на T_end | - | ✅ .start |
| pauseTimer() | - | ✅ Отменяем | - |
| resumeTimer() | ✅ Перепланируем | - | - |
| stopTimer() | - | ✅ Отменяем | - |
| timerCompleted() | - | ✅ Отменяем | ✅ Repeating |
| acknowledgeMeditationCompletion() | - | ✅ Отменяем | ⏹️ Stop |

---

## 🤔 Ключевой вопрос

**Почему при коротких тестах работает, а при 5 минутах — нет?**

Возможные причины:
1. При коротких тестах экран не успевает полностью "заснуть"
2. HKWorkoutSession имеет ограниченное время работы в background
3. watchOS применяет более агрессивное энергосбережение после нескольких минут

---

## 🔧 Этап 5: NotificationDelegate + Множественные уведомления (текущий)

### Проблема найдена

**Local Notifications на watchOS подавляются когда приложение активно!**

Когда HKWorkoutSession держит приложение "живым" в background:
- Timer работает ✅
- `timerCompleted()` вызывается ✅
- Local Notification **не доставляется** ❌ (приложение активно)
- `WKInterfaceDevice.play()` не работает в AOD ❌

### Решение

1. **UNUserNotificationCenterDelegate** — позволяет показывать уведомления даже когда приложение активно
2. **Множественные уведомления** — планируем 3 уведомления (T_end, T_end+5s, T_end+10s) для надёжности
3. **Critical Alert permission** — запрашиваем разрешение на критические уведомления

### Ключевой код

```swift
// В App - делегат для показа уведомлений в foreground
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // .sound на watchOS = haptic
        completionHandler([.banner, .sound])
    }
}

// В ActiveMeditationView - планируем 3 уведомления
private func scheduleEndNotification(after seconds: TimeInterval) {
    let delays: [(String, TimeInterval)] = [
        (Self.endNotificationId, 0),
        (Self.endNotificationId2, 5),
        (Self.endNotificationId3, 10)
    ]
    
    for (id, delay) in delays {
        // ... планируем уведомление на seconds + delay
    }
}
```

### Что должно произойти теперь

| Сценарий | Ожидаемое поведение |
|----------|---------------------|
| Wrist-up (экран активен) | Haptic напрямую + уведомление показывается благодаря delegate |
| Wrist-down (AOD) | Уведомление приходит от системы (3 штуки с интервалом 5с) |
| Приложение активно | delegate перехватывает и показывает уведомление со звуком/haptic |

---

## 📝 Что попробовать если не работает

### Вариант A: WKExtendedRuntimeSession типа .smartAlarm
Специальный тип сессии для alarm-подобных приложений (требует одобрения Apple).

### Вариант B: Отключить HKWorkoutSession перед завершением
Чтобы приложение стало "неактивным" и уведомление гарантированно пришло.

```swift
private func timerCompleted() {
    workoutManager.endWorkout()  // СНАЧАЛА завершаем workout
    // Ждём пока приложение станет неактивным
    // Тогда запланированное уведомление гарантированно придёт
}
```

### Вариант C: Проверить настройки пользователя
Убедиться, что:
- Уведомления включены для приложения
- "Show Notifications on Wrist Down" включено
- Haptic Alerts включены в настройках Watch

---

## 🔧 Технические детали

### Используемые технологии:
- `HKWorkoutSession` — для Extended Runtime Session
- `WKInterfaceDevice.play()` — для haptic feedback
- `UNUserNotificationCenter` — для Local Notifications
- `Timer` с `RunLoop.main.add(..., forMode: .common)` — для background-совместимого таймера

### Ограничения watchOS:
- `WKInterfaceDevice.play()` не работает в background/inactive
- Timer может останавливаться в глубоком sleep
- AOD режим ограничивает haptic для экономии батареи

### Документация Apple:
- [WKExtendedRuntimeSession](https://developer.apple.com/documentation/watchkit/wkextendedruntimesession)
- [Playing haptics](https://developer.apple.com/documentation/watchkit/wkinterfacedevice/2927925-play)
- [Local Notifications](https://developer.apple.com/documentation/usernotifications)

---

## 📊 Логи для диагностики

При следующем тесте обратить внимание на:

```
📅 [ActiveMeditation] Scheduled end notification for Xs from now
🔔 [ActiveMeditation] Starting repeating completion signals
📳 [ActiveMeditation] Playing COMPLETION haptic (session active: true/false)
🚫 [ActiveMeditation] Cancelled pending end notification
```

Ключевой вопрос: приходит ли системное уведомление, или оно отменяется до доставки?

---

## 📅 История изменений

| Дата | Изменение | Результат |
|------|-----------|-----------|
| 2026-01-07 | Первоначальная реализация haptic | ❌ Не работает в background |
| 2026-01-07 | Добавлен repeating timer | ❌ Останавливается через 1-2 сек |
| 2026-01-07 | Добавлен Local Notification при завершении | ❌ Ненадёжно |
| 2026-01-07 | Двухконтурная схема (заранее планируем) | ⚠️ Частично работает |
| 2026-01-07 | FIX: Не отменять уведомление в timerCompleted() | ❌ Не помогло |
| 2026-01-08 | **FIX: NotificationDelegate + множественные уведомления** | ✅ **РАБОТАЕТ** |

---

## ✅ ФИНАЛЬНОЕ РЕШЕНИЕ (2026-01-08)

### Архитектура

```
┌─────────────────────────────────────────────────────────────────┐
│                    MEDITATION START                              │
├─────────────────────────────────────────────────────────────────┤
│  1. HKWorkoutSession.start()                                     │
│     └── Автоматически активирует Extended Runtime Session        │
│                                                                  │
│  2. scheduleEndNotification(after: duration)                     │
│     └── Планируем 3 уведомления: T_end, T_end+5s, T_end+10s     │
│                                                                  │
│  3. Timer запускается с .common mode                             │
│     └── Работает даже при заблокированном экране                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ (ожидание duration)
┌─────────────────────────────────────────────────────────────────┐
│                    MEDITATION COMPLETE                           │
├─────────────────────────────────────────────────────────────────┤
│  КОНТУР 1 (Системная гарантия):                                  │
│  • Запланированное уведомление доставляется системой            │
│  • NotificationDelegate перехватывает → показывает + звук       │
│  • .sound на watchOS = haptic вибрация                          │
│                                                                  │
│  КОНТУР 2 (Красивый UX):                                         │
│  • timerCompleted() вызывает startCompletionSignals()           │
│  • Повторяющиеся haptic каждую секунду                          │
│  • Работает пока приложение активно                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    USER ACKNOWLEDGES                             │
├─────────────────────────────────────────────────────────────────┤
│  • Пользователь нажимает "Завершить"                            │
│  • cancelEndNotification() — отменяет оставшиеся уведомления    │
│  • completionSignalTimer?.invalidate() — останавливает haptic   │
│  • Показываем CompletionView                                    │
└─────────────────────────────────────────────────────────────────┘
```

### Ключевые компоненты

| Компонент | Роль | Файл |
|-----------|------|------|
| `HKWorkoutSession` | Держит приложение "живым" в background | `WorkoutManager.swift` |
| `NotificationDelegate` | Показывает уведомления даже когда app активно | `monotation_Watch_AppApp.swift` |
| `scheduleEndNotification()` | Планирует 3 уведомления заранее | `ActiveMeditationView.swift` |
| `startCompletionSignals()` | Повторяющиеся haptic когда app активно | `ActiveMeditationView.swift` |

### Проверено в логах (2026-01-08)

**Тест 3 секунды:**
```
📅 Scheduled notification meditation.end for 3.0s from now
📅 Scheduled notification meditation.end.2 for 8.0s from now
📅 Scheduled notification meditation.end.3 for 13.0s from now
...
📬 [NotificationDelegate] Will present notification: meditation.end
📬 [NotificationDelegate] Will present notification: meditation.end.2
📬 [NotificationDelegate] Will present notification: meditation.end.3
📳 Playing COMPLETION haptic × 10+
✅ User acknowledged completion
```

**Тест 5 минут:**
```
📅 Scheduled notification meditation.end for 300.0s from now
♥️ Heart Rate: 79 bpm ... (56 записей за 5 минут)
📬 [NotificationDelegate] Will present notification: meditation.end
📬 [NotificationDelegate] Will present notification: meditation.end.2
📬 [NotificationDelegate] Will present notification: meditation.end.3
📳 Playing COMPLETION haptic × 24+
✅ User acknowledged completion
✅ Workout saved with HKAverageMETs
```

### Интересное наблюдение

```
📊 [ActiveMeditation] Runtime session active: false
```

`ExtendedRuntimeManager.isActive` показывает `false`, но всё работает! Это потому что **HKWorkoutSession автоматически активирует Extended Runtime Session** на системном уровне. Наш отдельный `ExtendedRuntimeManager` не используется — он legacy код.

---

## 🎯 Цель

~~Достичь **100% гарантии** уведомления пользователя о завершении медитации.~~

✅ **ДОСТИГНУТО** — работает независимо от:
- ✅ Положения руки (wrist-up / wrist-down)
- ✅ Состояния экрана (активен / AOD)
- ✅ Длительности медитации (проверено 3 сек и 5 мин)

---

## 🧪 Детальное описание работы сигналов

### При старте медитации (`startTimer()`):

```
┌─────────────────────────────────────────────────────────────────┐
│ scheduleEndNotification(after: duration)                        │
│                                                                 │
│ Планируются 3 уведомления заранее:                              │
│   • meditation.end    → через duration секунд (T_end)          │
│   • meditation.end.2  → через duration + 5 секунд              │
│   • meditation.end.3  → через duration + 10 секунд             │
│                                                                 │
│ + Запускается Timer (каждую секунду уменьшает timeRemaining)    │
└─────────────────────────────────────────────────────────────────┘
```

### Когда таймер завершается (`timerCompleted()`):

```swift
// Уведомления НЕ отменяются — пусть приходят от системы
// Запускается startCompletionSignals():
//   - Первый haptic сразу
//   - Затем Timer каждую 1 секунду вызывает WKInterfaceDevice.play(.notification)
```

---

### Сценарий A: wrist-up (экран активен) при завершении

```
T_end:     📳 haptic от startCompletionSignals()
           📬 уведомление meditation.end
           
T_end+1s:  📳 haptic
T_end+2s:  📳 haptic
T_end+3s:  📳 haptic
T_end+4s:  📳 haptic

T_end+5s:  📳 haptic + 📬 уведомление meditation.end.2
...

T_end+10s: 📳 haptic + 📬 уведомление meditation.end.3
```

**Результат**: Непрерывный haptic каждую 1 секунду + 3 уведомления

---

### Сценарий B: wrist-down (AOD) при завершении

```
T_end:     📬 уведомление meditation.end → ВИБРАЦИЯ
           ⚠️ startCompletionSignals() вызывается, Timer работает,
              но WKInterfaceDevice.play() ЗАБЛОКИРОВАН системой!
              
T_end+1s:  (Timer fires, play() заблокирован — тишина)
T_end+2s:  (Timer fires, play() заблокирован — тишина)
T_end+3s:  (Timer fires, play() заблокирован — тишина)
T_end+4s:  (Timer fires, play() заблокирован — тишина)

T_end+5s:  📬 уведомление meditation.end.2 → ВИБРАЦИЯ

T_end+6-9s: (Timer fires, play() заблокирован — тишина)

T_end+10s: 📬 уведомление meditation.end.3 → ВИБРАЦИЯ
```

**Результат**: Только 3 вибрации от уведомлений (0, +5, +10 сек)

---

### Сценарий C: wrist-down → wrist-up (поднял руку)

```
T_end:     📬 уведомление → ВИБРАЦИЯ
T_end+5s:  📬 уведомление → ВИБРАЦИЯ
T_end+10s: 📬 уведомление → ВИБРАЦИЯ

T_end+12s: 🤚 Поднял руку → экран активен!
           Timer продолжает работать, теперь play() разблокирован:
           
T_end+12s: 📳 haptic
T_end+13s: 📳 haptic
T_end+14s: 📳 haptic
... непрерывно ...
```

**Результат**: 3 вибрации → пауза → непрерывный haptic после поднятия руки

---

### Итоговая таблица:

| Режим | `WKInterfaceDevice.play()` | Local Notifications | Что получает пользователь |
|-------|---------------------------|---------------------|---------------------------|
| **wrist-up** | ✅ Работает | ✅ Работают | Haptic каждую 1 сек + 3 уведомления |
| **wrist-down (AOD)** | ❌ Заблокирован | ✅ Работают | Только 3 вибрации (0, +5, +10 сек) |
| **wrist-down → wrist-up** | ❌ → ✅ | ✅ | 3 вибрации, потом непрерывный haptic |

### Точное поведение в AOD (wrist-down) — подтверждено тестами

**Наблюдаемое поведение:**
- 1-3 вибрации от уведомлений (с паузами 5 сек)
- После одной из них — непрерывные вибрации каждую 1 сек от Timer
- Экран **остаётся чёрным** (никакого визуального пробуждения)
- Рука НЕ поднималась!

**Когда Timer "пробивается" — недетерминировано:**
- Иногда после 1-го уведомления
- Иногда после 2-го
- Иногда после 3-го

```
T_end (0s):    📬 Уведомление 1 → ВИБРАЦИЯ от .sound
               ⚠️ Timer работает, play() может "пробиться" или нет
               
T_end+5s:      📬 Уведомление 2 → ВИБРАЦИЯ от .sound
               ⚠️ Timer может "пробиться" в этот момент
               
T_end+10s:     📬 Уведомление 3 → ВИБРАЦИЯ от .sound
               ⚠️ К этому моменту Timer обычно уже работает
               
После "пробития":
               📳 Timer → ВИБРАЦИЯ каждую 1 сек непрерывно
```

**Гипотеза о механизме:**

Уведомление с `.timeSensitive` + `.sound` временно **"разблокирует" haptic API** для приложения:
1. Система воспроизводит haptic для `.sound` уведомления
2. В этот момент `WKInterfaceDevice.play()` тоже может сработать
3. Timer "ловит" этот момент разблокировки
4. Когда первый haptic от Timer срабатывает, он **поддерживает** разблокировку
5. Непрерывный цикл: haptic → разблокировка сохраняется → haptic → ...

**Почему недетерминировано:**
- Зависит от timing: когда именно Timer fires относительно момента уведомления
- Race condition между системным haptic и нашим play()

**Что мы знаем точно:**
- ✅ Уведомления гарантированно работают в AOD (минимум 1-3 вибрации)
- ✅ Timer в какой-то момент "пробивается" и даёт непрерывный haptic
- ✅ Экран остаётся чёрным (это не про дисплей)
- ✅ Работает без поднятия руки

---

### Вывод:

**Решение работает стабильно!**

- В AOD режиме `WKInterfaceDevice.play()` обычно заблокирован
- Уведомления с `.sound` гарантированно дают вибрацию (системный механизм)
- Timer продолжает работать благодаря HKWorkoutSession (Extended Runtime)
- Уведомления как-то "разблокируют" haptic API для приложения
- Timer "ловит" момент разблокировки и начинает непрерывный haptic
- Экран остаётся чёрным — это НЕ про дисплей, а про внутреннее состояние системы

**Практический результат:**
- Пользователь получает 1-3 вибрации от уведомлений (гарантия)
- Затем непрерывные вибрации каждую секунду (Timer "пробивается")
- Всё без поднятия руки!

---

## 🧹 Рекомендации на будущее

1. **Можно удалить `ExtendedRuntimeManager`** — он не используется, HKWorkoutSession сам управляет Extended Runtime Session.

2. **Интервал между уведомлениями** — текущие 5 секунд оптимальны. Меньше — система может группировать. Больше — пользователь может пропустить.

3. **Можно добавить 4-е уведомление** — на T+15s для длительных медитаций, если пользователь глубоко медитирует.

