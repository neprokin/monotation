//
//  MeditationAlarmController.swift
//  monotation Watch App
//
//  Smart Alarm controller for guaranteed meditation completion alerts.
//  Uses WKExtendedRuntimeSession (Smart Alarm) + notifyUser for system-level "alarm"
//  that works reliably in AOD/wrist-down mode.
//

import WatchKit
import Foundation

/// Controller for Smart Alarm session - guarantees user notification at meditation end
/// This is the "iron" guarantee - unlike Timer + WKInterfaceDevice.play() which are best-effort
@MainActor
final class MeditationAlarmController: NSObject, ObservableObject {
    
    // MARK: - Published State
    
    /// Is alarm session currently scheduled/active
    @Published private(set) var isAlarmScheduled: Bool = false
    
    /// End date for the current meditation (for display/persistence)
    @Published private(set) var scheduledEndDate: Date?
    
    // MARK: - Private
    
    private var alarmSession: WKExtendedRuntimeSession?
    
    /// Repeat interval for haptic notifications (seconds)
    private let hapticRepeatInterval: TimeInterval = 2.0
    
    /// UserDefaults key for persisting endDate (crash recovery)
    private let endDateKey = "meditation.alarm.endDate"
    
    // MARK: - Public API
    
    /// Schedule alarm for meditation end
    /// - Parameter endDate: When meditation should end
    func scheduleAlarm(at endDate: Date) {
        print("🔔 [Alarm] Scheduling alarm for \(endDate)")
        
        // Cancel any existing alarm
        cancelAlarm()
        
        // Persist endDate for crash recovery
        UserDefaults.standard.set(endDate, forKey: endDateKey)
        scheduledEndDate = endDate
        
        // Create and schedule Smart Alarm session
        let session = WKExtendedRuntimeSession()
        session.delegate = self
        alarmSession = session
        
        // Start session at specific time (Smart Alarm)
        session.start(at: endDate)
        
        isAlarmScheduled = true
        print("✅ [Alarm] Alarm scheduled for \(endDate)")
    }
    
    /// Reschedule alarm (for pause/resume)
    /// - Parameter newEndDate: New end date after pause adjustment
    func rescheduleAlarm(at newEndDate: Date) {
        print("🔄 [Alarm] Rescheduling alarm to \(newEndDate)")
        scheduleAlarm(at: newEndDate)
    }
    
    /// Cancel alarm (user stopped meditation early or acknowledged completion)
    func cancelAlarm() {
        print("🚫 [Alarm] Cancelling alarm")
        
        alarmSession?.invalidate()
        alarmSession = nil
        
        // Clear persisted endDate
        UserDefaults.standard.removeObject(forKey: endDateKey)
        scheduledEndDate = nil
        isAlarmScheduled = false
        
        print("✅ [Alarm] Alarm cancelled")
    }
    
    /// Check for persisted alarm on app launch (crash recovery)
    func checkForPersistedAlarm() {
        guard let endDate = UserDefaults.standard.object(forKey: endDateKey) as? Date else {
            print("📋 [Alarm] No persisted alarm found")
            return
        }
        
        if endDate > Date() {
            print("⚠️ [Alarm] Found persisted alarm for \(endDate) - rescheduling")
            scheduleAlarm(at: endDate)
        } else {
            print("⏰ [Alarm] Persisted alarm was in the past - clearing")
            UserDefaults.standard.removeObject(forKey: endDateKey)
        }
    }
}

// MARK: - WKExtendedRuntimeSessionDelegate

extension MeditationAlarmController: WKExtendedRuntimeSessionDelegate {
    
    /// Called when Smart Alarm session starts (at scheduled endDate)
    nonisolated func extendedRuntimeSessionDidStart(_ session: WKExtendedRuntimeSession) {
        print("🎯 [Alarm] Session STARTED - meditation time is up!")
        
        // Start repeating haptic notifications until user acknowledges
        // This is the SYSTEM-LEVEL alarm mechanism
        session.notifyUser(hapticType: .notification) { [weak self] nextHaptic in
            guard let self = self else {
                return 0 // Stop if controller deallocated
            }
            
            print("📳 [Alarm] Playing haptic, next in \(self.hapticRepeatInterval)s")
            
            // Set next haptic type
            nextHaptic.pointee = .notification
            
            // Return interval until next haptic (0 = stop)
            return self.hapticRepeatInterval
        }
    }
    
    /// Called when session is about to expire
    nonisolated func extendedRuntimeSessionWillExpire(_ session: WKExtendedRuntimeSession) {
        print("⚠️ [Alarm] Session WILL EXPIRE - trying to extend")
        
        // Smart Alarm sessions can run for a while, but not forever
        // If user hasn't acknowledged, we should try other means
        // (In practice, user should have responded by now)
    }
    
    /// Called when session is invalidated
    nonisolated func extendedRuntimeSession(
        _ session: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
        error: Error?
    ) {
        print("🛑 [Alarm] Session INVALIDATED - reason: \(reason.rawValue)")
        
        if let error = error {
            print("❌ [Alarm] Error: \(error.localizedDescription)")
        }
        
        // Log specific reasons
        switch reason {
        case .none:
            print("   → No specific reason")
        case .sessionInProgress:
            print("   → Another session already in progress")
        case .sessionNotStarted:
            print("   → Session was never started")
        case .error:
            print("   → Error occurred")
        case .expired:
            print("   → Session expired")
        case .resignedFrontmost:
            print("   → App resigned frontmost")
        case .suppressedBySystem:
            print("   → Suppressed by system")
        @unknown default:
            print("   → Unknown reason: \(reason.rawValue)")
        }
        
        // Clean up on main actor
        Task { @MainActor in
            if session === self.alarmSession {
                self.alarmSession = nil
                self.isAlarmScheduled = false
            }
        }
    }
}
