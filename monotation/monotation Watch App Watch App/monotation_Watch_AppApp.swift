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
    @StateObject private var runtimeManager = ExtendedRuntimeManager()
    
    /// Notification delegate - allows notifications to show even when app is active
    private let notificationDelegate = NotificationDelegate()
    
    init() {
        // Request notification permission for meditation completion alerts
        requestNotificationPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(workoutManager)
                .environmentObject(connectivityManager)
                .environmentObject(runtimeManager)
                .onAppear {
                    // Set delegate to allow notifications when app is in foreground
                    UNUserNotificationCenter.current().delegate = notificationDelegate
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

// MARK: - Notification Delegate
// This allows notifications to be shown even when the app is in foreground (active)
// Without this, Local Notifications are suppressed when the app is running

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    
    /// Called when notification is about to be presented while app is in foreground
    /// Return presentation options to show banner, play sound, and trigger haptic
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("📬 [NotificationDelegate] Will present notification: \(notification.request.identifier)")
        
        // CRITICAL: This allows the notification to be shown even when app is active
        // .sound triggers haptic on Apple Watch
        completionHandler([.banner, .sound])
    }
    
    /// Called when user interacts with notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("👆 [NotificationDelegate] User tapped notification: \(response.notification.request.identifier)")
        completionHandler()
    }
}
