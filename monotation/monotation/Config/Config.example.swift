//
//  Config.example.swift
//  monotation
//
//  Configuration template for Supabase
//
//  ⚠️ ВАЖНО: Этот файл - шаблон!
//  Скопируйте его как Config.swift и добавьте реальные ключи
//

import Foundation

enum SupabaseConfig {
    // ⚠️ TODO: Замените на URL вашего Supabase проекта
    // Получите из: https://supabase.com/dashboard/project/YOUR_PROJECT/settings/api
    // Пример: "https://abcdefghijklmnop.supabase.co"
    static let url = "YOUR_SUPABASE_URL_HERE"
    
    // ⚠️ TODO: Замените на anon public key
    // Получите из: https://supabase.com/dashboard/project/YOUR_PROJECT/settings/api
    // Это длинная строка, начинается с "eyJ..."
    static let anonKey = "YOUR_SUPABASE_ANON_KEY_HERE"
}

// 📋 ИНСТРУКЦИЯ ПО НАСТРОЙКЕ:
//
// 1. В Xcode: File → New → File → Swift File
//    Название: Config.swift
//    Сохранить в: monotation/monotation/Config/
//
// 2. Скопируйте содержимое этого файла в Config.swift
//
// 3. Получите ключи из Supabase:
//    - Откройте https://supabase.com/dashboard
//    - Выберите ваш проект
//    - Settings → API
//    - Скопируйте "Project URL" и "anon public" key
//
// 4. Замените в Config.swift:
//    - YOUR_SUPABASE_URL_HERE → ваш Project URL
//    - YOUR_SUPABASE_ANON_KEY_HERE → ваш anon public key
//
// 5. Сохраните файл
//
// ✅ Config.swift уже в .gitignore, не будет закоммичен
//
// 📖 Подробная инструкция: см. SUPABASE_SETUP.md в корне проекта

