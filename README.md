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

## ✨ Функционал (MVP v1.0)

### 📱 iOS App (✅ протестировано)
- 🕐 **Таймер медитации** - выбор времени с обратным отсчетом
- 💾 **Сохранение записей** - дата, время, длительность, поза, место, заметка
- 📚 **История медитаций** - хронологический список всех практик
- 🔐 **Apple Sign In** - безопасная аутентификация

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
- ✅ Данные сохраняются в HealthKit + Supabase
- ✅ Пульс отслеживается и передается

### ⚠️ Известные ограничения
- **Watch Connectivity не работает в симуляторе** (только на реальных устройствах)
- **Supabase Free**: автопауза через 7 дней неактивности
  - Решение: CloudKit миграция (после активации Apple Developer Account)

---

## 🛠 Технический стек

- **Platforms**: iOS 17.0+ • watchOS 10.0+
- **Language**: Swift 5.9+
- **UI**: SwiftUI
- **Backend**: Supabase (PostgreSQL + Auth) → CloudKit (планируется)
- **Health**: HealthKit (Mindful Minutes, Heart Rate, Workouts)
- **Connectivity**: WatchConnectivity (iPhone ↔ Watch sync)
- **Architecture**: MVVM
- **Concurrency**: async/await, Combine

---

## 🚀 Быстрый старт

### Требования

- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- Apple Developer Account (для Sign in with Apple)
- Supabase Account (бесплатный tier)

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

3. **Настрой Supabase:**
   - 📖 **Подробная инструкция**: [SUPABASE_SETUP.md](SUPABASE_SETUP.md)
   - Кратко:
     - Создай проект на [supabase.com](https://supabase.com)
     - В Xcode: создай `Config.swift` в папке `Config/` со следующим содержимым:
       ```swift
       import Foundation
       enum SupabaseConfig {
           static let url = "YOUR_SUPABASE_URL_HERE"
           static let anonKey = "YOUR_SUPABASE_ANON_KEY_HERE"
       }
       ```
     - Замени `YOUR_SUPABASE_URL_HERE` и `YOUR_SUPABASE_ANON_KEY_HERE` на реальные ключи
     - Выполни SQL из `SUPABASE_SETUP.md` для создания таблицы

4. **Настрой Signing:**
   - В Xcode: Target → Signing & Capabilities
   - Выбери свой Team
   - Добавь capability "Sign in with Apple"

5. **Запусти:**
   - `⌘ + R` для запуска на симуляторе

---

## 📂 Структура проекта (MVVM)

```
monotation/
├── App/                           # Entry point
│   └── monotationApp.swift        # @main
├── Views/                         # SwiftUI UI
│   ├── Timer/TimerView.swift      # Главный экран с таймером
│   ├── Meditation/MeditationFormView.swift  # Форма сохранения
│   └── History/                   # История медитаций
│       ├── HistoryView.swift
│       ├── MeditationCard.swift
│       └── MeditationDetailView.swift
├── ViewModels/                    # Business logic
│   ├── TimerViewModel.swift
│   ├── MeditationFormViewModel.swift
│   └── HistoryViewModel.swift
├── Models/                        # Data models
│   ├── Meditation.swift
│   ├── MeditationPose.swift
│   └── MeditationPlace.swift
├── Services/                      # Backend & System
│   ├── SupabaseService.swift      # CRUD с Supabase
│   ├── AuthService.swift          # Apple Sign In (заготовка)
│   └── NotificationService.swift  # Локальные уведомления
├── Extensions/                    # Swift extensions
│   ├── Date+Extensions.swift
│   └── TimeInterval+Extensions.swift
├── Config/                        # Configuration (в .gitignore)
│   └── Config.swift               # Supabase ключи
└── Resources/                     # Assets, colors
    └── Assets.xcassets
```

---

## 🏗 Архитектура

### MVVM Pattern
- **Models**: Простые Swift structs (Codable, Identifiable)
- **Views**: SwiftUI views (декларативный UI)
- **ViewModels**: ObservableObject (@Published properties, business logic)
- **Services**: Actor/Class для backend и system интеграции

### Data Flow
```
User Action → View → ViewModel → Service → Supabase
                ↑         ↓
            @Published  Update
```

---

## 🔧 Разработка

### Workflow: Cursor + Xcode

1. **AI (Cursor)** пишет код и создает файлы
2. **Разработчик (Xcode)** компилирует и тестирует (⌘+R)
3. **Итерация**: фидбек → исправления → проверка
4. **Git commit** после каждой работающей фичи

Подробнее в [WORKFLOW.md](WORKFLOW.md)

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

---

## 📖 Документация

- [WORKFLOW.md](WORKFLOW.md) - Development workflow (Cursor + Xcode)
- [SUPABASE_SETUP.md](SUPABASE_SETUP.md) - Настройка Supabase backend
- [.cursor/notepads/](.cursor/notepads/) - Техническая документация для AI

---

## 🗺 Roadmap

### ✅ v1.0 - MVP (Current) - 95% завершено

**Завершено:**
- [x] Документация и настройка
- [x] Xcode проект с MVVM
- [x] Supabase SDK интегрирован
- [x] Models (Meditation, MeditationPose, MeditationPlace)
- [x] Таймер медитации (выбор длительности, обратный отсчет, фоновый режим)
- [x] Сохранение записей (форма с валидацией)
- [x] История медитаций (группировка по датам, статистика, детальный просмотр)
- [x] Supabase backend (SupabaseService, AuthService, NotificationService)
- [x] Интеграция сохранения/загрузки с Supabase
- [x] Монохромный дизайн (Light/Dark mode)
- [x] Тестирование всех функций

**Опционально:**
- [ ] Apple Sign In (AuthView) - для продакшена

### 📋 v1.1 - Polish & Release
**Цель**: Подготовка к App Store
- [ ] Apple Sign In (AuthView)
- [ ] Production Supabase setup (RLS policies)
- [ ] App Store Connect setup
- [ ] TestFlight бета-тестирование

### 📋 v1.2 - Улучшения UX
**Цель**: Расширенная функциональность
- [ ] Редактирование/удаление медитаций
- [ ] Базовая статистика (стрики, графики)
- [ ] Фильтры и поиск в истории
- [ ] Настройки (Settings screen)
- [ ] iPad support

### 🚀 v2.0 - AI Integration
**Цель**: Интеллектуальный анализ
- [ ] AI-анализ паттернов медитации (markdown → insights)
- [ ] Персональные рекомендации
- [ ] Еженедельные/месячные отчеты
- [ ] Экспорт данных (CSV, PDF)

---

## 🎯 Текущий статус проекта

**Фаза**: MVP v1.0 (95% Complete) ✅

**Что работает:**
- ✅ Таймер медитации (с выбором времени, обратным отсчетом)
- ✅ Форма сохранения (поза, место, заметка)
- ✅ История медитаций (группировка по датам, статистика)
- ✅ Детальный просмотр медитации
- ✅ Supabase backend (сохранение/загрузка данных)
- ✅ Локальные уведомления
- ✅ Монохромный дизайн (Light/Dark mode)

**В режиме разработки:**
- ⚠️ Используется `temp-user-id` (для тестирования без авторизации)
- ⚠️ Загружаются все медитации (без фильтра по userId)
- ⚠️ Временные RLS policies в Supabase

**Следующие шаги:**
1. Добавить Apple Sign In (опционально для v1.0)
2. Настроить production Supabase
3. Подготовить к релизу

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
- [Supabase](https://supabase.com) - Backend platform
- [SwiftUI](https://developer.apple.com/xcode/swiftui/) - UI framework

---

**Последнее обновление**: 29 декабря 2025  
**GitHub**: [github.com/neprokin/monotation](https://github.com/neprokin/monotation)

