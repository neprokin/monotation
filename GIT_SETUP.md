# Git & GitHub Setup

> Инструкции по настройке Git и первому коммиту для monotation

---

## 🎯 Цель

Настроить Git репозиторий и GitHub для отслеживания изменений проекта monotation.

---

## ✅ Pre-requisites

- Git установлен (проверь: `git --version`)
- GitHub аккаунт создан
- SSH ключи настроены (или HTTPS токен)

---

## 📋 Шаг 1: Инициализация локального репозитория

### В терминале (в папке проекта):

```bash
cd "/Users/neprokin/Library/Mobile Documents/iCloud~md~obsidian/Documents/Vibe Coding/meditation app"

# Инициализация git
git init

# Проверка что .gitignore есть
ls -la .gitignore

# Добавление всех файлов
git add .

# Первый коммит
git commit -m "chore: initial project setup with documentation and cursor configuration"
```

**Что добавится в первый коммит:**
- ✅ PROJECT.md (документация проекта)
- ✅ WORKFLOW.md (workflow разработки)
- ✅ README.md (GitHub readme)
- ✅ .cursor/ (настройки Cursor)
- ✅ .gitignore (исключения)
- ✅ .cursorignore (исключения Cursor)
- ✅ _cursor_setup_guide/ (архив гайда)

**Что НЕ добавится** (благодаря .gitignore):
- ❌ Config.swift (секреты)
- ❌ .DS_Store (macOS)
- ❌ Xcode user data

---

## 📋 Шаг 2: Создание GitHub репозитория

### Вариант A: Через веб-интерфейс (рекомендуется)

1. Зайди на [github.com](https://github.com)
2. Нажми **New repository** (зеленая кнопка)
3. Заполни:
   ```
   Repository name: monotation
   Description: Минималистичный iOS трекер медитаций
   Visibility: Private (или Public)
   
   ❌ НЕ инициализируй:
   - Add a README file (у нас уже есть!)
   - Add .gitignore (у нас уже есть!)
   - Choose a license (добавим позже)
   ```
4. Нажми **Create repository**

### Вариант B: Через GitHub CLI (если установлен)

```bash
gh repo create monotation --private --source=. --remote=origin
```

---

## 📋 Шаг 3: Подключение к GitHub

### После создания репозитория на GitHub:

```bash
# Добавь remote (замени [username] на твой GitHub username)
git remote add origin git@github.com:[username]/monotation.git

# Или через HTTPS:
git remote add origin https://github.com:[username]/monotation.git

# Проверь что remote добавлен
git remote -v

# Переименуй ветку в main (если нужно)
git branch -M main

# Первый push
git push -u origin main
```

**Результат:** Все файлы загружены на GitHub! 🎉

---

## 📋 Шаг 4: Проверка на GitHub

Зайди на `https://github.com/[username]/monotation`

**Должно быть видно:**
- ✅ README.md отображается красиво
- ✅ Все папки и файлы на месте
- ✅ 1 commit
- ✅ Зеленый "main" branch

---

## 📋 Шаг 5: Настройка .gitignore для Config.swift

### Создание примера конфига (после создания Xcode проекта):

```bash
# Создать Config.example.swift (шаблон для других разработчиков)
cat > monotation/Config/Config.example.swift << 'EOF'
// Config.example.swift
// Скопируй этот файл как Config.swift и добавь свои ключи

enum SupabaseConfig {
    static let url = "YOUR_SUPABASE_URL_HERE"
    static let anonKey = "YOUR_SUPABASE_ANON_KEY_HERE"
}
EOF

# Добавить в git (пример файла - можно коммитить)
git add monotation/Config/Config.example.swift
git commit -m "docs: add config example template"
git push
```

**Config.swift** (реальный с секретами) НЕ попадет в Git благодаря .gitignore!

---

## 🔧 Ежедневная работа с Git

### Основной workflow:

```bash
# 1. Проверка статуса
git status

# 2. Добавление изменений
git add .
# или конкретные файлы:
git add Views/TimerView.swift ViewModels/TimerViewModel.swift

# 3. Коммит
git commit -m "feat: add timer screen with countdown"

# 4. Push на GitHub
git push

# 5. Проверка истории
git log --oneline
```

### Работа с ветками (для фич):

```bash
# Создать новую ветку для фичи
git checkout -b feature/timer-screen

# ... работа над фичей ...

git add .
git commit -m "feat: implement timer screen"
git push -u origin feature/timer-screen

# На GitHub: создать Pull Request
# После merge: переключиться обратно
git checkout main
git pull
```

---

## 📝 Commit Messages Convention

### Формат:

```
<type>: <subject>

[optional body]
[optional footer]
```

### Types:

```
feat:     новая функциональность
fix:      исправление бага
docs:     изменения в документации
style:    форматирование кода (не влияет на логику)
refactor: рефакторинг (не добавляет функционал, не фиксит баг)
test:     добавление тестов
chore:    обновление зависимостей, конфигурации
```

### Примеры хороших коммитов:

```bash
git commit -m "feat: add timer view with countdown animation"
git commit -m "fix: resolve timer not stopping when app goes to background"
git commit -m "docs: update README with installation instructions"
git commit -m "refactor: extract timer logic into separate service"
git commit -m "style: format code according to SwiftLint rules"
git commit -m "chore: update supabase-swift to v2.0"
```

### Примеры плохих коммитов (избегать):

```bash
# ❌ Слишком общее
git commit -m "update"
git commit -m "fix bug"
git commit -m "changes"

# ❌ Слишком длинное в subject
git commit -m "add timer view with countdown and also fix the bug where timer doesn't stop and refactor the code"

# ✅ Лучше разбить на несколько коммитов
git commit -m "feat: add timer view with countdown"
git commit -m "fix: resolve timer not stopping issue"
git commit -m "refactor: extract timer logic to service"
```

---

## 🔐 GitHub Settings (рекомендуется)

### После push первого коммита:

1. **Защита main ветки:**
   ```
   Settings → Branches → Add rule
   Branch name pattern: main
   ☑ Require a pull request before merging
   ☑ Require status checks to pass
   ```

2. **Добавить Description и Topics:**
   ```
   Settings → General
   Description: Минималистичный iOS трекер медитаций
   Topics: ios, swift, swiftui, meditation, supabase, mvvm
   ```

3. **Настроить README preview:**
   - GitHub автоматически покажет README.md на главной странице

---

## 🚨 Важные правила

### ✅ Всегда коммитить:
- Исходный код (.swift файлы)
- Проектные файлы (.xcodeproj/project.pbxproj)
- Документацию (.md файлы)
- Конфигурационные файлы (без секретов!)
- Assets (изображения, но не слишком большие)

### ❌ Никогда не коммитить:
- Секреты (API keys, токены, пароли)
- Config.swift с реальными ключами
- Xcode user data (xcuserdata/)
- Build artifacts (DerivedData/, build/)
- .DS_Store и другие временные файлы
- Большие бинарные файлы (>50MB)

### ⚠️ Если случайно закоммитил секрет:

```bash
# 1. Удали файл из git (но оставь локально)
git rm --cached monotation/Config/Config.swift

# 2. Коммит
git commit -m "fix: remove config file with secrets from git"

# 3. Push
git push

# 4. ВАЖНО: Измени секреты на новые (старые скомпрометированы!)
# - Сгенерируй новый Supabase anon key
# - Обнови Config.swift локально
```

---

## 🎯 Checklist для первой настройки ✅ ЗАВЕРШЕНО

```
☑ Git инициализирован (git init) ✅
☑ Первый коммит создан (git commit) ✅
☑ GitHub репозиторий создан (github.com/neprokin/monotation) ✅
☑ Remote добавлен (git remote add origin) ✅
☑ Код загружен на GitHub (git push) ✅
☑ README.md отображается на GitHub ✅
☑ .gitignore работает (Config.swift не в git) ✅
☑ Config.example.swift создан и закоммичен ✅
```

**Всего коммитов**: 4
**Последний коммит**: docs: add next steps guide and update workflow (044c0ed)

---

## 📊 Мониторинг репозитория

### Полезные команды:

```bash
# Статистика коммитов
git log --oneline --graph --decorate --all

# Кто что изменял
git blame Views/TimerView.swift

# История изменений файла
git log -p Views/TimerView.swift

# Размер репозитория
git count-objects -vH

# Все branches
git branch -a
```

---

## 🔄 Синхронизация (если работаешь с нескольких машин)

```bash
# Перед началом работы: забрать изменения
git pull

# После работы: отправить изменения
git push

# Если есть конфликты:
git pull --rebase
# Разрешить конфликты вручную
git add .
git rebase --continue
git push
```

---

## 🆘 Troubleshooting

### Проблема: `remote origin already exists`

```bash
# Удали старый remote
git remote remove origin

# Добавь новый
git remote add origin git@github.com:[username]/monotation.git
```

### Проблема: `failed to push some refs`

```bash
# Забери изменения с сервера
git pull --rebase origin main

# Разреши конфликты (если есть)
git add .
git rebase --continue

# Push снова
git push
```

### Проблема: Случайно закоммитил большой файл

```bash
# Удали из последнего коммита
git rm --cached path/to/large/file
git commit --amend

# Если уже запушил:
# Используй git filter-branch или BFG Repo-Cleaner
# (сложнее, лучше избегать)
```

---

## ✅ Готово! НАСТРОЙКА ЗАВЕРШЕНА

После выполнения всех шагов:
- ✅ Git настроен
- ✅ GitHub репозиторий создан: [github.com/neprokin/monotation](https://github.com/neprokin/monotation)
- ✅ 4 коммита загружены на GitHub
- ✅ Xcode проект настроен и закоммичен
- ✅ MVVM структура организована
- ✅ Готово к разработке!

**Следующий шаг:** Открой [NEXT_STEPS.md](NEXT_STEPS.md) для продолжения разработки! 🚀

**Текущий статус:** [STATUS.md](STATUS.md)

