//
//  NotificationService.swift
//  monotation
//
//  Local notifications for meditation timer
//

import Foundation
import Combine
import UserNotifications

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    private init() {
        requestAuthorization()
    }
    
    // MARK: - Request Authorization
    
    func requestAuthorization() {
        // Request time-sensitive permission for fallback notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { granted, error in
            if granted {
                print("✅ Notification authorization granted")
            } else {
                print("⚠️ Notification authorization denied")
            }
            
            if let error = error {
                print("❌ Notification authorization error: \(error)")
            }
        }
    }
    
    // MARK: - Schedule Timer Completion Notification
    
    /// Schedule time-sensitive fallback notification for meditation completion
    /// This is a FALLBACK for iPhone when Watch Smart Alarm is unavailable
    /// (e.g., Watch is off, not on wrist, or force-quit)
    func scheduleTimerCompletionNotification(in seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Медитация завершена"
        content.body = "Время медитации истекло. Сохраните сессию."
        content.sound = .default
        content.categoryIdentifier = "MEDITATION_COMPLETE"
        
        // CRITICAL: Use timeSensitive interruption level for guaranteed delivery
        // This ensures notification is delivered even in Do Not Disturb mode
        content.interruptionLevel = .timeSensitive
        
        // Schedule notification
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(
            identifier: "meditation_timer_fallback",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ [NotificationService] Failed to schedule fallback notification: \(error)")
            } else {
                print("✅ [NotificationService] Fallback notification scheduled for \(seconds) seconds (iPhone)")
            }
        }
    }
    
    // MARK: - Cancel Timer Notification
    
    func cancelTimerNotification() {
        // Cancel fallback notification (iPhone)
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["meditation_timer_fallback"]
        )
        
        print("🚫 [NotificationService] Cancelled fallback notification (iPhone)")
    }
    
    // MARK: - Cancel All Notifications
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}

