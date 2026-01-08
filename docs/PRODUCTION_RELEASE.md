# 🚀 Production & Release Guide

> Руководство по подготовке к релизу в App Store

**Статус**: Для будущего использования (когда будет готово к релизу)

---

## Timeline: 7-14 дней до App Store

**Prerequisites:**
- [ ] Apple Developer Account ($99/год)
- [ ] Реальное iOS устройство
- [ ] App Icon 1024x1024
- [ ] Privacy Policy URL

---

## Этап 1: Apple Sign In (4-6 часов)

**1.1 Apple Developer Setup**
- [ ] [developer.apple.com](https://developer.apple.com) → Certificates, IDs & Profiles
- [ ] Создать App ID с "Sign in with Apple"
- [ ] Создать Service ID для Supabase
- [ ] Создать Key для Sign in with Apple (скачать .p8 файл)

**1.2 Supabase Auth**
- [ ] Supabase Dashboard → Authentication → Providers → Apple
- [ ] Добавить Service ID, Key ID, Team ID, Private Key (.p8)

**1.3 Код: AuthView**
- [ ] Создать `Views/Auth/AuthView.swift`
- [ ] Добавить кнопку "Sign in with Apple"
- [ ] Интегрировать в `monotationApp.swift`

**1.4 Код: AuthService**
- [ ] Завершить `signInWithApple()` метод
- [ ] Убрать mock authentication
- [ ] Протестировать на устройстве

**1.5 Интеграция**
- [ ] Убрать "temp-user-id" из кода
- [ ] Везде использовать `authService.currentUserId`
- [ ] Протестировать: Sign In → Timer → Save → History → Sign Out

---

## 🎯 Этап 1.5: Миграция на CloudKit (РЕКОМЕНДУЕТСЯ, 4-6 часов)

> ⚠️ **НАПОМИНАНИЕ**: После активации Apple Developer Account перейти с Supabase на CloudKit!

**Почему CloudKit:**
- ✅ **Бесплатно** (включено в Apple Developer $99/год)
- ✅ **Без автопаузы** (Supabase Free паузится через 7 дней)
- ✅ **Нативная интеграция** с iOS/watchOS
- ✅ **Автосинхронизация** между iPhone/Watch/iPad через iCloud
- ✅ **Оффлайн-первый** (работает без интернета)
- ✅ **Приватность** (данные в iCloud пользователя)
- ✅ **Нет серверных затрат** ($0 вместо $25/мес Supabase Pro)

**Миграция включает:**
- [ ] Настроить CloudKit Container в Xcode
- [ ] Создать SwiftData модели вместо Supabase
- [ ] Включить iCloud Capability
- [ ] Заменить SupabaseService на CloudKitService
- [ ] Настроить автоматическую синхронизацию
- [ ] Протестировать синхронизацию iPhone ↔ Watch
- [ ] Убрать зависимость от Supabase

**Результат:**
- Приложение работает полностью оффлайн
- Данные синхронизируются автоматически через iCloud
- Нет проблем с паузой проекта
- Лучше UX (быстрее, надежнее)

**Когда делать:**
- ✅ После активации Apple Developer Account
- ✅ Перед релизом в App Store
- ⚠️ Supabase можно оставить для разработки до этого момента

---

## Этап 2: Production Supabase (1-2 часа)

> ⚠️ **Этот этап только если НЕ перешли на CloudKit**

**2.1 Удалить dev policies**
```sql
DROP POLICY IF EXISTS "Allow insert for development" ON meditations;
DROP POLICY IF EXISTS "Allow select for development" ON meditations;
```

**2.2 Создать production policies**
```sql
-- Users can only see/edit their own meditations
CREATE POLICY "Users can view own meditations"
  ON meditations FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own meditations"
  ON meditations FOR INSERT WITH CHECK (auth.uid() = user_id);
```

**2.3 Восстановить foreign key**
```sql
ALTER TABLE meditations
ADD CONSTRAINT meditations_user_id_fkey
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
```

**2.4 Убрать dev режим из кода**
- [ ] `SupabaseService.swift`: убрать загрузку всех медитаций
- [ ] Всегда фильтровать по реальному userId

---

## Этап 3: App Store Connect (2-3 часа)

**3.1 Создать App**
- [ ] [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → My Apps → New App
- [ ] Name: monotation
- [ ] Bundle ID: выбрать из списка
- [ ] Primary Language: Russian (или English)

**3.2 App Information**
- [ ] App Name & Subtitle
- [ ] Category: Health & Fitness
- [ ] Privacy Policy URL (генераторы: [app-privacy-policy-generator.firebaseapp.com](https://app-privacy-policy-generator.firebaseapp.com))

**3.3 Материалы**
- [ ] Screenshots: минимум 3 (Timer, Form, History)
  - iPhone 6.7" (Pro Max)
  - iPhone 6.5" (Plus)
- [ ] App Description (до 4000 символов)
- [ ] Keywords: meditation, timer, mindfulness, tracker
- [ ] App Icon: 1024x1024 PNG

**3.4 Build Upload**
- [ ] Xcode: Product → Archive
- [ ] Validate
- [ ] Distribute App → App Store Connect

---

## Этап 4: TestFlight (1-2 дня)

**4.1 Internal Testing**
- [ ] TestFlight tab → Internal Group
- [ ] Добавить тестеров (email)
- [ ] Собрать фидбек
- [ ] Исправить критичные баги

**4.2 External Testing (optional)**
- [ ] Beta App Review
- [ ] Пригласить external тестеров

---

## Этап 5: App Store Release (3-7 дней)

**5.1 Final Check**
- [ ] Все баги исправлены
- [ ] Тестирование на разных устройствах
- [ ] Screenshots актуальны

**5.2 Submit for Review**
- [ ] Version: 1.0
- [ ] Age Rating Quiz
- [ ] Submit for Review

**5.3 Ждём одобрения**
- "Waiting for Review" → 24-48 часов
- "In Review" → 1-2 дня
- "Ready for Sale" → 🎉 Релиз!

**5.4 Release**
- [ ] Publish в App Store
- [ ] Приложение доступно через несколько часов

---

**Последнее обновление**: 2026-01-08
