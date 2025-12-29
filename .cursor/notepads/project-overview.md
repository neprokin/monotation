# monotation - Project Overview

## Vision
Создать минималистичное iOS приложение для отслеживания практики медитации с фокусом на простоте использования и готовностью к интеллектуальному анализу в будущем.

---

## MVP Scope

### Core Features (v1.0)

#### 1. 🕐 Meditation Timer
**Описание**: Простой таймер с предустановленным выбором времени
- Выбор длительности: 5, 10, 15, 20, 30 минут или custom
- Обратный отсчет с визуальной индикацией (круг/прогресс бар)
- Звук и вибрация по окончании
- Работа в фоновом режиме (когда приложение свернуто)
- Local notification при завершении

#### 2. 💾 Save Meditation Form
**Описание**: Форма для сохранения деталей медитации после завершения
- **Автоматические поля**:
  - Дата и время начала (captured at start)
  - Дата и время окончания (captured at completion)
  - Длительность (calculated)
- **Выбор из списка**:
  - Поза: Бирманская поза | Ходьба
  - Место: Дом | Работа | Свой вариант (text input)
- **Опциональное поле**:
  - Заметка (text field, multiline)

#### 3. 📚 Meditation History
**Описание**: Хронологический список всех медитаций
- Группировка по датам (Сегодня, Вчера, дата)
- Карточка медитации показывает:
  - Время начала
  - Длительность
  - Поза (иконка)
  - Место
- Тап на карточку → детальный просмотр
- Scroll to load (pagination в будущем)

#### 4. 🔐 Authentication
**Описание**: Простой вход через Apple Sign In
- Apple Sign In только (Sign in with Apple)
- Один экран авторизации
- Автоматический вход при повторном запуске
- Logout опция (в будущем в Settings)

---

## Technologies

### iOS App
```
Language:     Swift 5.9+
UI Framework: SwiftUI
Min Target:   iOS 17.0+
Architecture: MVVM
```

### Backend
```
Service:  Supabase
Database: PostgreSQL
Auth:     Supabase Auth (Apple provider)
API:      REST via supabase-swift SDK
```

### Key Dependencies
```
- supabase-swift (official SDK)
```

---

## Design Philosophy

### Minimalism
- **Только необходимое** - никаких лишних экранов или кнопок
- **Нативные компоненты** - используем стандартные iOS UI elements
- **Чистота** - много white space, простые формы
- **Фокус** - одна задача на экране

### iOS Native
- SwiftUI компоненты (List, NavigationStack, Button, etc.)
- SF Symbols для иконок
- SF Pro шрифт (system font)
- Automatic Light/Dark mode support
- Accessibility built-in (VoiceOver, Dynamic Type)

### Simplicity Over Features
- В MVP нет: статистики, графиков, guided медитаций, звуков
- Фокус на core flow: Timer → Meditate → Save → History
- Расширение функционала в будущих версиях

---

## User Flow (MVP)

```
App Launch
    ↓
[Check Auth]
    ↓
┌───────────────┬──────────────────┐
│ Not Logged In │    Logged In     │
└───────────────┴──────────────────┘
        ↓                 ↓
   [AuthView]       [TimerView]
  Apple Sign In    (Main Screen)
        ↓                 ↓
        └─────────────────┘
                ↓
          [TimerView]
          Main Screen
                ↓
        ┌───────┴────────┐
        │                │
   [Start Timer]   [View History]
        │                │
        ↓                └──→ [HistoryView]
 [Timer Running]              │
   (countdown)                │
        │                     │
        ↓                     │
  [Complete] ←────────────────┘
        ↓
 [MeditationFormView]
   (Fill details)
        ↓
     [Save]
        ↓
   Back to [TimerView]
```

---

## Target Audience

### Primary Users
- **Начинающие медитирующие** - нужен простой способ отслеживать практику
- **Опытные практики** - хотят вести детальные записи
- **Осознанные пользователи** - ценят минимализм и приватность

### Device Support
- **iPhone only** (MVP)
  - iPhone 12 and newer (iOS 17+)
  - Portrait orientation only
- **iPad support** - planned for v1.1
- **Apple Watch** - planned for v2.0

---

## Non-Goals (Not in MVP)

### Что НЕ входит в MVP:
- ❌ Guided медитации (аудио)
- ❌ Фоновые звуки/музыка
- ❌ Статистика и графики
- ❌ Напоминания/уведомления
- ❌ Социальные функции
- ❌ Экспорт данных
- ❌ Интеграция с Apple Health
- ❌ Настройки (Settings screen)
- ❌ Редактирование/удаление медитаций
- ❌ Поиск в истории
- ❌ AI-анализ (v2.0)

---

## Roadmap

### ✅ Phase 1 - MVP (Completed)
**Timeline**: 2-3 weeks ✅
**Goal**: Working app with core functionality ✅
- ✅ Timer with countdown
- ✅ Save meditation (form)
- ✅ History list
- ⏳ Apple Sign In (optional for v1.0)
- ✅ Supabase backend

### 📋 Phase 2 - Polish (v1.1)
**Timeline**: 1 week after MVP
**Goal**: Improve UX and add basic analytics
- Edit/delete meditations
- Basic statistics (total time, count)
- Streak tracking
- Settings screen
- Onboarding flow

### 📋 Phase 3 - Enhance (v1.2)
**Timeline**: 2 weeks
**Goal**: Better user engagement
- Notifications/reminders
- Filters in history
- Search functionality
- iPad support
- Export data (CSV/PDF)

### 🚀 Phase 4 - AI Integration (v2.0)
**Timeline**: 1-2 months
**Goal**: Intelligent insights
- Pattern analysis (time of day, frequency)
- NLP analysis of notes
- Recommendations
- Weekly/monthly reports
- GPT-4/Claude integration

### 🎯 Phase 5 - Premium (v2.1+)
**Timeline**: Ongoing
**Goal**: Monetization & advanced features
- Guided meditations
- Background sounds
- Apple Watch app
- Apple Health sync
- Premium subscription

---

## Success Metrics

### MVP Success (внутренние метрики)
- ✅ App builds and runs without crashes
- ✅ All core flows работают (Timer → Save → History)
- ✅ Auth работает (Sign in/out)
- ✅ Data syncs с Supabase
- ✅ UI responsive на всех размерах iPhone

### User Success (после релиза)
- Active users (DAU/MAU)
- Meditations logged per user
- Retention rate (Day 1, Day 7, Day 30)
- Session length
- Crash-free rate >99%

---

## Technical Constraints

### Requirements
- macOS 14+ (Sonoma)
- Xcode 15+
- iOS device or simulator (iOS 17+)
- Supabase account (free tier OK for MVP)
- Apple Developer account (для Sign in with Apple и TestFlight)

### Performance Targets
- App launch < 1 second
- Timer UI updates 60 FPS
- History load < 500ms
- Auth flow < 3 seconds
- Battery efficient (timer uses minimal resources)

---

## Data & Privacy

### What We Store
- User ID (from Apple Sign In)
- Meditation records:
  - Timestamps (start, end)
  - Duration (calculated)
  - Pose (enum)
  - Place (string)
  - Note (text, optional)
- App preferences (future)

### What We DON'T Store
- Personal information (minimal via Apple Sign In)
- Location data (place is user-entered text)
- Health data (no Apple Health integration yet)
- Usage analytics (optional in future)

### Privacy Principles
- Data stored in Supabase with Row Level Security
- Users see only their own data
- Auth tokens in iOS Keychain
- No third-party analytics in MVP
- Comply with Apple's App Privacy requirements

---

## Markdown Format (for AI future)

### Note Structure
Когда пользователь сохраняет заметку, мы сохраняем как обычный String, но с учетом будущего парсинга:

```markdown
# Медитация 28.12.2025 15:30

- **Длительность**: 20 минут
- **Поза**: Бирманская поза
- **Место**: Дом
- **Состояние до**: -
- **Состояние после**: -
- **Заметка**: Хорошая концентрация на дыхании. Мысли приходили, но легко отпускались.
```

Это позволит в v2.0:
- Легко парсить структурированные данные
- Анализировать через NLP
- Искать паттерны в заметках
- Генерировать инсайты

---

## Communication

### Development
- GitHub Issues для задач
- Pull Requests для code review
- Conventional Commits для истории

### Documentation
- PROJECT.md - главная документация
- .cursor/notepads/ - рабочие заметки
- README.md - для пользователей (в будущем)
- Inline comments - для сложной логики

---

## Questions & Decisions

### Open Questions (to be decided)
- [ ] Звук окончания медитации - какой? (system sound vs custom)
- [ ] Максимальная длина заметки - 500 символов? 1000?
- [ ] Нужен ли tutorial при первом запуске?
- [ ] Onboarding flow - сразу в таймер или объяснение?

### Decisions Made
- ✅ MVP без AI-анализа (v2.0)
- ✅ Только Apple Sign In (без email/password)
- ✅ Нативные компоненты (без custom UI library)
- ✅ Supabase для backend (не Firebase)
- ✅ SwiftUI only (не UIKit)
- ✅ Минимализм (не feature-rich app)

---

## Contact & Resources

### Links
- Project Repo: (TBD)
- Figma Designs: (TBD)
- Supabase Dashboard: (TBD)
- TestFlight: (TBD)

### Documentation
- PROJECT.md - полная спецификация
- ARCHITECTURE.md - детали архитектуры (будет создан позже)
- SETUP.md - инструкции по разработке (будет создан позже)

---

**Use this overview as reference when:**
- Starting a new feature
- Making architecture decisions
- Discussing scope with team
- Writing documentation
- Debugging issues (check if it's in MVP scope)

**Remember**: Это MVP. Focus на core functionality, polish later!

