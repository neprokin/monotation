# Supabase Setup Guide

> Пошаговая инструкция по настройке Supabase для monotation

---

## 📋 Шаг 1: Создание проекта Supabase

1. Перейдите на [supabase.com](https://supabase.com)
2. Войдите или зарегистрируйтесь
3. Нажмите **"New Project"**
4. Заполните:
   - **Name**: `monotation` (или любое другое)
   - **Database Password**: создайте надежный пароль (сохраните его!)
   - **Region**: выберите ближайший регион
5. Нажмите **"Create new project"**
6. Дождитесь создания проекта (2-3 минуты)

---

## 📋 Шаг 2: Получение API ключей

1. В Supabase Dashboard откройте ваш проект
2. Перейдите в **Settings** → **API**
3. Найдите секцию **"Project API keys"**
4. Скопируйте:
   - **Project URL** (например: `https://xxxxx.supabase.co`)
   - **anon public** key (длинная строка, начинается с `eyJ...`)

⚠️ **Важно**: Используйте только **anon public** key, не **service_role** key!

---

## 📋 Шаг 3: Создание и настройка Config.swift

1. **Создайте файл в Xcode:**
   - File → New → File → Swift File
   - Название: `Config.swift`
   - Сохранить в: `monotation/monotation/Config/`

2. **Вставьте следующий код:**
   ```swift
   import Foundation

   enum SupabaseConfig {
       static let url = "YOUR_SUPABASE_URL_HERE"
       static let anonKey = "YOUR_SUPABASE_ANON_KEY_HERE"
   }
   ```

3. **Замените placeholder значения:**
   - `YOUR_SUPABASE_URL_HERE` → ваш Project URL
   - `YOUR_SUPABASE_ANON_KEY_HERE` → ваш anon public key

**Пример:**
```swift
enum SupabaseConfig {
    static let url = "https://abcdefghijklmnop.supabase.co"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprbG1ub3AiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYxNjIzOTAyMiwiZXhwIjoxOTMxODE1MDIyfQ.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}
```

4. Сохраните файл (⌘+S)

---

## 📋 Шаг 4: Создание таблицы meditations

1. В Supabase Dashboard перейдите в **SQL Editor**
2. Нажмите **"New query"**
3. Скопируйте и вставьте следующий SQL:

```sql
-- Create meditations table
CREATE TABLE meditations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  duration INTERVAL NOT NULL,
  pose TEXT NOT NULL,
  place TEXT NOT NULL,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_meditations_user_id ON meditations(user_id);
CREATE INDEX idx_meditations_start_time ON meditations(start_time DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE meditations ENABLE ROW LEVEL SECURITY;

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

4. Нажмите **"Run"** (или ⌘+Enter)
5. Должно появиться сообщение "Success. No rows returned"

### ⚠️ Для разработки (временные policies без авторизации)

Если вы хотите тестировать сохранение медитаций **без настройки авторизации**, выполните дополнительный SQL:

```sql
-- Временные policies для разработки (разрешают вставку и чтение без авторизации)
-- ⚠️ ВНИМАНИЕ: Это только для разработки! Удалите перед продакшеном!
CREATE POLICY "Allow insert for development"
  ON meditations FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Allow select for development"
  ON meditations FOR SELECT
  USING (true);
```

**Важно**: Эти policies разрешают вставку и чтение любому пользователю. Используйте только для разработки и тестирования. Перед продакшеном удалите эти policies и настройте правильную авторизацию.

### ⚠️ Для разработки (удаление foreign key constraint)

Если вы получаете ошибку `"violates foreign key constraint meditations_user_id_fkey"` при сохранении медитаций без авторизации, выполните:

```sql
-- Убрать foreign key constraint для разработки
-- ⚠️ ВНИМАНИЕ: Это только для разработки! Восстановите перед продакшеном!
ALTER TABLE meditations 
DROP CONSTRAINT IF EXISTS meditations_user_id_fkey;
```

**Важно**: Это позволит вставлять медитации с любым UUID в `user_id` без проверки существования пользователя в `auth.users`. Используйте только для разработки. Перед продакшеном восстановите constraint и настройте авторизацию.

### 📝 Примечание о режиме разработки

В текущей реализации приложение работает в **режиме разработки**:
- Используется фиксированный UUID (`00000000-0000-0000-0000-000000000001`) для `"temp-user-id"`
- При загрузке медитаций загружаются **все медитации** без фильтра по userId (для удобства тестирования)
- Это позволяет видеть все тестовые данные, созданные вручную в Supabase

**Для продакшена**:
- Настройте авторизацию (Apple Sign In)
- Удалите временные policies
- Восстановите foreign key constraint
- Используйте реальные user IDs из `AuthService`

---

## 📋 Шаг 5: Настройка Apple Sign In в Supabase

1. В Supabase Dashboard перейдите в **Authentication** → **Providers**
2. Найдите **Apple** в списке провайдеров
3. Включите Apple provider (toggle switch)
4. Настройте Apple Developer консоль:
   - Создайте Service ID в [developer.apple.com](https://developer.apple.com)
   - Создайте Key для Sign in with Apple
   - Загрузите Private Key
5. Добавьте в Supabase:
   - **Service ID**
   - **Key ID**
   - **Team ID**
   - **Private Key** (содержимое .p8 файла)

📖 **Подробная инструкция**: [Supabase Apple Sign In Guide](https://supabase.com/docs/guides/auth/social-login/auth-apple)

---

## 📋 Шаг 6: Проверка настройки

1. Откройте проект в Xcode
2. Убедитесь, что `Config.swift` содержит реальные ключи (не `YOUR_SUPABASE_URL_HERE`)
3. Запустите приложение (⌘+R)
4. Проверьте консоль Xcode (⌘+Shift+Y):
   - ✅ Если видите `"✅ SupabaseService: Fetched X meditations"` - всё работает
   - ✅ Если видите `"✅ Meditation saved to Supabase"` - сохранение работает
   - ⚠️ Если видите `"⚠️ SupabaseService: Config not set up"` - проверьте Config.swift
5. Протестируйте:
   - Создайте медитацию через приложение
   - Проверьте в Supabase Dashboard → Table Editor → meditations - должна появиться запись
   - Откройте History в приложении - медитация должна появиться

---

## 🔒 Безопасность

### ✅ Что правильно:
- `Config.swift` в `.gitignore` - не коммитится в git
- Используется только **anon public** key (безопасный для клиента)
- Row Level Security (RLS) включен - пользователи видят только свои данные

### ❌ Что НЕ делать:
- ❌ Не коммитить `Config.swift` в git
- ❌ Не использовать **service_role** key в клиентском приложении
- ❌ Не отключать RLS без необходимости

---

## 🐛 Troubleshooting

### Проблема: "Config not set up"
**Решение**: Проверьте, что в `Config.swift` реальные ключи, а не placeholder значения.

### Проблема: "Network error" при запросах
**Решение**: 
- Проверьте интернет-соединение
- Убедитесь, что Project URL правильный
- Проверьте, что проект Supabase активен (не приостановлен)

### Проблема: "RLS policy violation"
**Решение**: 
- Убедитесь, что пользователь авторизован
- Проверьте, что RLS policies созданы (Шаг 4)
- Проверьте, что `user_id` в запросе совпадает с `auth.uid()`

### Проблема: "Table does not exist"
**Решение**: 
- Убедитесь, что таблица `meditations` создана (Шаг 4)
- Проверьте, что вы в правильном проекте Supabase

### Проблема: "violates foreign key constraint meditations_user_id_fkey"
**Решение**: 
- Это происходит при сохранении медитаций без авторизации
- Выполните SQL для удаления foreign key constraint (см. Шаг 4, раздел "Для разработки")
- Или создайте тестового пользователя в Supabase Auth и используйте его UUID

### Проблема: "Expected to decode Double but found a string instead" (duration)
**Решение**: 
- Это нормально - PostgreSQL INTERVAL возвращается как строка (например, "00:00:03")
- Код автоматически декодирует строку в TimeInterval
- Если ошибка сохраняется, проверьте, что используется последняя версия кода с кастомным декодингом

### Проблема: Медитации сохраняются, но не появляются в History
**Решение**: 
- Проверьте, что выполнены временные policies для SELECT (Шаг 4)
- Проверьте консоль Xcode - должны быть сообщения `"✅ SupabaseService: Fetched X meditations"`
- В режиме разработки приложение загружает все медитации без фильтра по userId

---

## 📚 Полезные ссылки

- [Supabase Dashboard](https://supabase.com/dashboard)
- [Supabase Swift SDK Docs](https://supabase.com/docs/reference/swift/introduction)
- [Supabase Auth Guide](https://supabase.com/docs/guides/auth)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)

---

## ✅ Checklist

Перед использованием приложения убедитесь:

- [ ] Supabase проект создан
- [ ] API ключи скопированы в `Config.swift`
- [ ] Таблица `meditations` создана
- [ ] RLS policies созданы
- [ ] Временные policies для разработки созданы (если тестируете без авторизации)
- [ ] Foreign key constraint удален (если тестируете без авторизации)
- [ ] Приложение запускается без ошибок
- [ ] Медитации сохраняются в Supabase (проверьте Table Editor)
- [ ] Медитации загружаются в History (проверьте консоль Xcode)
- [ ] Apple Sign In настроен (опционально для MVP, можно отложить)

---

**Готово!** Теперь приложение может сохранять медитации в Supabase. 🎉

