//
//  monotation_Watch_AppApp.swift
//  monotation Watch App
//
//  Main Watch App entry point
//

import SwiftUI
import UserNotifications

@main
struct monotation_Watch_App: App {
    @StateObject private var workoutManager = WorkoutManager()
    @StateObject private var connectivityManager = ConnectivityManager.shared
    @StateObject private var runtimeManager = ExtendedRuntimeManager()  // NEW: один экземпляр на все приложение
    
    init() {
        // Request notification permission for meditation completion alerts
        // This is needed because Local Notifications work even in Always On Display (AOD) mode
        requestNotificationPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(workoutManager)
                .environmentObject(connectivityManager)
                .environmentObject(runtimeManager)  // NEW: передаем runtimeManager
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ [App] Notification permission granted")
            } else if let error = error {
                print("❌ [App] Notification permission error: \(error)")
            } else {
                print("⚠️ [App] Notification permission denied")
            }
        }
    }
}
