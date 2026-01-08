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
    @StateObject private var alarmController = MeditationAlarmController()
    
    init() {
        // Request notification permission (for iPhone fallback only)
        requestNotificationPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(workoutManager)
                .environmentObject(connectivityManager)
                .environmentObject(alarmController)
                .onAppear {
                    // Check for persisted alarm (crash recovery)
                    alarmController.checkForPersistedAlarm()
                }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { granted, error in
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
