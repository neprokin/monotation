# Production Roadmap - monotation

> Пошаговый план подготовки приложения к релизу в App Store

**Дата начала**: 29 декабря 2025  
**Предполагаемый релиз**: Январь 2026

---

## 🎯 Цель

Подготовить monotation к публикации в App Store:
- Полноценная авторизация (Apple Sign In)
- Production-ready backend (Supabase)
- App Store Connect setup
- Beta-тестирование (TestFlight)
- Релиз в App Store

---

## 📋 Этапы подготовки

### 🔐 Этап 1: Apple Sign In (4-6 часов)

#### 1.1 Настройка Apple Developer
**Что нужно:**
- [ ] Apple Developer Account (платный, $99/год)
- [ ] Войти в [developer.apple.com](https://developer.apple.com)

**Создать:**
- [ ] App ID для monotation
  - Bundle ID: `com.yourname.monotation` (или другой)
  - Включить capability "Sign in with Apple"
- [ ] Service ID для Supabase
  - Identifier: `com.yourname.monotation.service`
  - Return URLs: `https://[your-project].supabase.co/auth/v1/callback`
- [ ] Key для Sign in with Apple
  - Создать новый key
  - Включить "Sign in with Apple"
  - Скачать .p8 file (СОХРАНИТЬ!)
  - Запомнить Key ID

**Документация:**
- [Apple Sign In Setup Guide](https://developer.apple.com/sign-in-with-apple/get-started/)
- [Supabase Apple Auth Guide](https://supabase.com/docs/guides/auth/social-login/auth-apple)

#### 1.2 Настройка Supabase Auth
**В Supabase Dashboard:**
- [ ] Authentication → Providers → Apple
- [ ] Включить Apple provider
- [ ] Добавить данные из Apple Developer:
  - Service ID
  - Key ID  
  - Team ID
  - Private Key (содержимое .p8 файла)
- [ ] Сохранить изменения

#### 1.3 Код: AuthView
**Создать файлы:**
- [ ] `Views/Auth/AuthView.swift` - UI экрана входа
- [ ] Интегрировать в `monotationApp.swift` (показывать если не залогинен)

**UI элементы:**
- Логотип/название приложения
- Описание (кратко что делает приложение)
- Кнопка "Sign in with Apple"
- Privacy policy / Terms of Service (если нужно)

#### 1.4 Код: Завершить AuthService
**Обновить:**
- [ ] Завершить `signInWithApple()` метод
- [ ] Убрать `throw AuthError.notImplemented`
- [ ] Протестировать delegate methods
- [ ] Добавить обработку ошибок

#### 1.5 Интеграция и тестирование
- [ ] Убрать temp-user-id из ViewModels
- [ ] Использовать `authService.currentUserId` везде
- [ ] Протестировать весь flow: Sign In → Timer → Save → History
- [ ] Протестировать Sign Out
- [ ] Проверить на реальном устройстве

**Время:** 4-6 часов

---

### 🗄️ Этап 2: Production Supabase (1-2 часа)

#### 2.1 Удалить временные policies
**В Supabase SQL Editor:**
```sql
-- Удалить development policies
DROP POLICY IF EXISTS "Allow insert for development" ON meditations;
DROP POLICY IF EXISTS "Allow select for development" ON meditations;
```

#### 2.2 Проверить production policies
**Должны быть (из SUPABASE_SETUP.md):**
```sql
-- Policy: Users can view only their own meditations
CREATE POLICY "Users can view own meditations"
  ON meditations FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert only their own meditations
CREATE POLICY "Users can insert own meditations"
  ON meditations FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update only their own meditations
CREATE POLICY "Users can update own meditations"
  ON meditations FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Users can delete only their own meditations
CREATE POLICY "Users can delete own meditations"
  ON meditations FOR DELETE
  USING (auth.uid() = user_id);
```

#### 2.3 Восстановить foreign key constraint
```sql
-- Восстановить constraint для user_id
ALTER TABLE meditations
ADD CONSTRAINT meditations_user_id_fkey
FOREIGN KEY (user_id)
REFERENCES auth.users(id)
ON DELETE CASCADE;
```

#### 2.4 Убрать режим разработки из кода
**В SupabaseService.swift:**
- [ ] Убрать загрузку всех медитаций (если userId == "temp-user-id")
- [ ] Всегда фильтровать по userId
- [ ] Убрать фиксированный UUID для temp-user-id

#### 2.5 Тестирование
- [ ] Создать тестового пользователя через Apple Sign In
- [ ] Сохранить медитацию
- [ ] Проверить что она появляется только у этого пользователя
- [ ] Создать второго пользователя
- [ ] Проверить что данные разделены

**Время:** 1-2 часа

---

### 🍎 Этап 3: App Store Connect (2-3 часа)

#### 3.1 Создать App в App Store Connect
- [ ] Войти в [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
- [ ] My Apps → "+" → New App
- [ ] Выбрать:
  - Platform: iOS
  - Name: monotation (или другое имя)
  - Primary Language: Russian (или English)
  - Bundle ID: (выбрать созданный в Этапе 1)
  - SKU: monotation-ios (или другой уникальный)

#### 3.2 Заполнить App Information
**General Information:**
- [ ] App Name: monotation
- [ ] Subtitle: Минималистичный трекер медитаций
- [ ] Category: Health & Fitness (или Lifestyle)
- [ ] Secondary Category (optional): Health & Fitness

**Privacy Policy:**
- [ ] URL: (нужно создать privacy policy страницу)
- Можно использовать генераторы:
  - [App Privacy Policy Generator](https://app-privacy-policy-generator.firebaseapp.com/)
  - [PrivacyPolicies.com](https://www.privacypolicies.com/)

#### 3.3 Подготовить App Store материалы
**Screenshots (обязательно):**
- [ ] iPhone 6.7" (Pro Max) - минимум 3 скриншота
  - Таймер (главный экран)
  - Форма сохранения
  - История медитаций
- [ ] iPhone 6.5" (Plus) - минимум 3 скриншота

**Описание:**
- [ ] Написать App Description (4000 символов max)
- [ ] Keywords (100 символов): meditation, timer, mindfulness, tracker
- [ ] Promotional Text (170 символов)
- [ ] Support URL
- [ ] Marketing URL (optional)

**App Icon:**
- [ ] 1024x1024 PNG (без прозрачности, без скругления)

#### 3.4 App Store Review Information
- [ ] Contact Information (имя, телефон, email)
- [ ] Demo Account (если нужен для review)
- [ ] Notes для reviewer (если нужны)

#### 3.5 Build Upload
**В Xcode:**
- [ ] Archive приложения (Product → Archive)
- [ ] Validate (проверка перед отправкой)
- [ ] Distribute App → App Store Connect
- [ ] Upload

**Время:** 2-3 часа (включая создание скриншотов и текстов)

---

### 🧪 Этап 4: TestFlight Beta (1-2 дня)

#### 4.1 Настроить TestFlight
**В App Store Connect:**
- [ ] TestFlight tab → Internal Testing
- [ ] Создать Internal Group
- [ ] Добавить тестеров (email адреса)
- [ ] Включить Automatic Distribution

#### 4.2 Beta Testing
- [ ] Отправить приглашения тестерам
- [ ] Дождаться установки
- [ ] Собрать фидбек:
  - Баги
  - UX проблемы
  - Предложения
- [ ] Исправить критичные баги
- [ ] Загрузить новый build (если нужно)

#### 4.3 Подготовка к External Testing
- [ ] Заполнить Beta App Review Information
- [ ] Отправить на review (Apple проверит перед external beta)
- [ ] Дождаться одобрения (1-2 дня)
- [ ] Добавить external тестеров

**Время:** 1-2 дня (зависит от количества багов)

---

### 🚀 Этап 5: App Store Release (3-7 дней)

#### 5.1 Финальная проверка
- [ ] Все баги из TestFlight исправлены
- [ ] Приложение протестировано на разных устройствах
- [ ] Все тексты проверены на орфографию
- [ ] Screenshots актуальны
- [ ] Privacy Policy актуальна

#### 5.2 Submission
**В App Store Connect:**
- [ ] Выбрать build для release
- [ ] Version: 1.0
- [ ] Release:
  - Manual release (после одобрения)
  - Automatic release (сразу после одобрения)
  - Scheduled release (выбрать дату)
- [ ] Age Rating Quiz (заполнить)
- [ ] Submit for Review

#### 5.3 App Review
- [ ] Дождаться статуса "In Review" (~24-48 часов)
- [ ] Review длится 1-2 дня
- [ ] Возможные статусы:
  - ✅ Approved → Ready for Sale
  - ⚠️ Metadata Rejected → исправить и resubmit
  - ❌ Rejected → исправить проблемы и resubmit

#### 5.4 Release
- [ ] Если одобрено → Release
- [ ] Приложение появится в App Store через несколько часов
- [ ] Проверить что оно доступно для скачивания
- [ ] Поделиться ссылкой!

**Время:** 3-7 дней (зависит от Apple Review)

---

## 📊 Общий Timeline

| Этап | Время | Когда |
|------|-------|-------|
| 1. Apple Sign In | 4-6 часов | Сегодня-завтра |
| 2. Production Supabase | 1-2 часа | Завтра |
| 3. App Store Connect | 2-3 часа | 2-3 дня |
| 4. TestFlight Beta | 1-2 дня | 3-5 дней |
| 5. App Store Release | 3-7 дней | 7-14 дней |

**Итого:** 7-14 дней от начала до релиза в App Store

---

## ✅ Prerequisites Checklist

Перед началом убедись что есть:
- [ ] Apple Developer Account ($99/год)
- [ ] Реальное iOS устройство для тестирования
- [ ] Email для App Store Connect
- [ ] Идея для App Icon (1024x1024)
- [ ] Готовность к написанию описания и текстов
- [ ] Privacy Policy URL (можно сгенерировать)

---

## 🎯 Следующий шаг

**Начинаем с Этапа 1: Apple Sign In**

1. Проверяем Apple Developer Account
2. Создаём App ID и Service ID
3. Настраиваем Supabase Auth
4. Создаём AuthView
5. Завершаем AuthService
6. Тестируем

**Готов начать?** Скажи и начнём с первого пункта! 🚀

---

**Последнее обновление**: 29 декабря 2025

