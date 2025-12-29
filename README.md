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

- 🕐 **Таймер медитации** - выбор времени с обратным отсчетом
- 💾 **Сохранение записей** - дата, время, длительность, поза, место, заметка
- 📚 **История медитаций** - хронологический список всех практик
- 🔐 **Apple Sign In** - безопасная аутентификация

---

## 🛠 Технический стек

- **iOS**: Swift 5.9+ • SwiftUI
- **Backend**: Supabase (PostgreSQL + Auth)
- **Architecture**: MVVM
- **Минимальная версия**: iOS 17.0+

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

## 📂 Структура проекта

```
monotation/
├── App/                    # Entry point, global state
├── Views/                  # SwiftUI views (Auth, Timer, History)
├── ViewModels/             # Business logic для views
├── Models/                 # Data models (Meditation, Pose, Place)
├── Services/               # Backend interaction (Supabase, Auth)
├── Config/                 # Configuration (не в git!)
├── Extensions/             # Swift extensions
└── Resources/              # Assets, localization
```

---

## 🔧 Разработка

### Основной workflow

1. **AI (Cursor)** пишет код и создает файлы
2. **Разработчик (Xcode)** тестирует и проверяет
3. **Итерация**: фидбек → исправления → проверка

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

- [PROJECT.md](PROJECT.md) - Полная спецификация проекта
- [STATUS.md](STATUS.md) - Текущий прогресс разработки
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

### 📋 v1.1 - Analytics
- [ ] Статистика (общее время, количество)
- [ ] Streak tracking
- [ ] Графики прогресса

### 📋 v1.2 - UX Improvements
- [ ] Редактирование/удаление медитаций
- [ ] Фильтры в истории
- [ ] Поиск

### 🚀 v2.0 - AI Integration
- [ ] Анализ паттернов медитаций
- [ ] NLP анализ заметок
- [ ] Персональные рекомендации
- [ ] Еженедельные AI-отчеты

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

## 📊 Project Status

🚧 **В разработке** - MVP фаза (70% завершено)

**Готово:** Models, Timer, Form, History  
**Осталось:** Services (Supabase), Auth Screen

**Текущий этап**: Настройка завершена, начинаем разработку Models  
**GitHub**: [github.com/neprokin/monotation](https://github.com/neprokin/monotation)  
**Коммитов**: 4  
**Последнее обновление**: 28 декабря 2025

**Подробный статус**: [STATUS.md](STATUS.md) | **Как продолжить**: [NEXT_STEPS.md](NEXT_STEPS.md)

