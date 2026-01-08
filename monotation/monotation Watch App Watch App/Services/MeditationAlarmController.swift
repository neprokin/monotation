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
import Combine

/// Controller for Smart Alarm session - guarantees user notification at meditation end
/// This is the "iron" guarantee - unlike Timer + WKInterfaceDevice.play() which are best-effort
@MainActor
final class MeditationAlarmController: NSObject, ObservableObject {
    
    // MARK: - Published State
    
    /// Is alarm session currently scheduled/active
    @Published private(set) var isAlarmActive: Bool = false
    
    /// End date for the current meditation (for display/persistence)
    @Published private(set) var scheduledEndDate: Date?
    
    /// Was alarm stopped by user via system UI "Stop" button?
    /// If true, user already acknowledged completion via system UI (Вариант A)
    @Published private(set) var wasStoppedBySystem: Bool = false
    
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
        
        isAlarmActive = true
        print("✅ [Alarm] Alarm scheduled for \(endDate)")
    }
    
    /// Cancel alarm (user stopped meditation early or acknowledged completion)
    func cancelAlarm() {
        print("🚫 [Alarm] Cancelling alarm")
        
        alarmSession?.invalidate()
        alarmSession = nil
        
        // Clear persisted endDate
        UserDefaults.standard.removeObject(forKey: endDateKey)
        scheduledEndDate = nil
        isAlarmActive = false
        wasStoppedBySystem = false  // Reset flag when manually cancelled
        
        print("✅ [Alarm] Alarm cancelled")
    }
    
    /// Reset the wasStoppedBySystem flag (called when completion is shown)
    func resetStoppedBySystemFlag() {
        wasStoppedBySystem = false
    }
    
    /// Check for persisted alarm on app launch (crash recovery)
    /// NOTE: On app launch, meditation is not active, so persisted alarm is not needed.
    /// Clear it to avoid conflicts with active sessions (e.g., HKWorkoutSession).
    func checkForPersistedAlarm() {
        guard let endDate = UserDefaults.standard.object(forKey: endDateKey) as? Date else {
            print("📋 [Alarm] No persisted alarm found")
            return
        }
        
        let now = Date()
        let timeUntilAlarm = endDate.timeIntervalSince(now)
        
        // On app launch, meditation is not active, so persisted alarm is stale
        // Clear it to avoid "only single session allowed" conflicts
        if timeUntilAlarm <= 0 {
            print("⏰ [Alarm] Persisted alarm was in the past - clearing")
        } else {
            print("⚠️ [Alarm] Found persisted alarm for \(endDate) (in \(Int(timeUntilAlarm))s), but app just launched - clearing stale alarm")
        }
        
        // Always clear persisted alarm on app launch
        // It will be rescheduled when user starts a new meditation
        UserDefaults.standard.removeObject(forKey: endDateKey)
        scheduledEndDate = nil
        print("✅ [Alarm] Cleared persisted alarm - will be rescheduled when meditation starts")
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
            print("   → No specific reason (user stopped)")
        case .sessionInProgress:
            print("   → Another session already in progress")
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
                self.isAlarmActive = false
                
                // Check if user stopped alarm via system UI "Stop" button
                // .none usually means user explicitly stopped (most common when user taps "Stop")
                // Other reasons are system-initiated (not user action)
                let userStopped = (reason == .none)
                print("👆 [Alarm] Session invalidated - reason: \(reason.rawValue), userStopped: \(userStopped)")
                
                if userStopped {
                    print("✅ [Alarm] User stopped alarm via system UI 'Stop' button")
                    self.wasStoppedBySystem = true
                } else {
                    print("ℹ️ [Alarm] Alarm stopped for other reason (not user action)")
                    self.wasStoppedBySystem = false
                }
            }
        }
    }
}
