//
//  Config.example.swift
//  monotation
//
//  Configuration template for Supabase
//  Copy this file as Config.swift and add your actual keys
//

import Foundation

enum SupabaseConfig {
    // Replace with your Supabase project URL
    static let url = "YOUR_SUPABASE_URL_HERE"
    
    // Replace with your Supabase anon/public key
    static let anonKey = "YOUR_SUPABASE_ANON_KEY_HERE"
}

// INSTRUCTIONS:
// 1. Copy this file: cp Config.example.swift Config.swift
// 2. Get your keys from: https://supabase.com/dashboard/project/YOUR_PROJECT/settings/api
// 3. Replace YOUR_SUPABASE_URL_HERE with your project URL
// 4. Replace YOUR_SUPABASE_ANON_KEY_HERE with your anon key
// 5. Config.swift is in .gitignore and won't be committed to git

