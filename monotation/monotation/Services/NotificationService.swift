//
//  NotificationService.swift
//  monotation
//
//  Local notifications for meditation timer
//

import Foundation
import UserNotifications

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    private init() {
        requestAuthorization()
    }
    
    // MARK: - Request Authorization
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
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
    
    func scheduleTimerCompletionNotification(in seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Медитация завершена"
        content.body = "Время медитации истекло. Сохраните сессию."
        content.sound = .default
        content.categoryIdentifier = "MEDITATION_COMPLETE"
        
        // Schedule notification
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(
            identifier: "meditation_timer_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ NotificationService.scheduleTimerCompletionNotification error: \(error)")
            } else {
                print("✅ Timer completion notification scheduled for \(seconds) seconds")
            }
        }
    }
    
    // MARK: - Cancel Timer Notification
    
    func cancelTimerNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["meditation_timer"]
        )
        
        // Remove all meditation-related notifications
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let meditationRequests = requests.filter { $0.identifier.contains("meditation_timer") }
            let identifiers = meditationRequests.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }
    
    // MARK: - Cancel All Notifications
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}

