//
//  ConnectivityManager.swift
//  monotation
//
//  Manages Watch Connectivity for syncing meditation data from Apple Watch
//

import Foundation
import WatchConnectivity
import Combine

@MainActor
class ConnectivityManager: NSObject, ObservableObject {
    static let shared = ConnectivityManager()
    
    @Published var isWatchAppInstalled: Bool = false
    @Published var isWatchReachable: Bool = false
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - Receive from Watch
    
    private func handleMeditationData(_ data: [String: Any]) async {
        print("📱 iOS: Received meditation data from Watch")
        
        guard let duration = data["duration"] as? TimeInterval,
              let averageHeartRate = data["averageHeartRate"] as? Double,
              let startTimeInterval = data["startTime"] as? TimeInterval else {
            print("❌ iOS: Invalid meditation data format")
            return
        }
        
        let startTime = Date(timeIntervalSince1970: startTimeInterval)
        let endTime = startTime.addingTimeInterval(duration)
        
        // Get pose from data (default to lotus if not provided)
        let poseString = data["pose"] as? String ?? "Лотос"
        let pose = MeditationPose(rawValue: poseString) ?? .lotus
        
        // Get user ID
        let userId = AuthService.shared.currentUserId ?? "temp-user-id"
        
        // Create meditation object
        let meditation = Meditation(
            id: UUID(),
            userId: userId,
            startTime: startTime,
            endTime: endTime,
            pose: pose,
            place: .home,   // Default for Watch meditations
            note: "От Apple Watch ⌚️\nСредний пульс: \(Int(averageHeartRate)) уд/мин",
            createdAt: Date()
        )
        
        // Save to Supabase
        do {
            try await SupabaseService.shared.insertMeditation(meditation)
            print("✅ iOS: Meditation from Watch saved to Supabase")
            print("   Duration: \(Int(duration))s, HR: \(Int(averageHeartRate)) bpm")
            
            // Notify other parts of the app to refresh (if needed)
            NotificationCenter.default.post(name: .meditationAdded, object: nil)
            
        } catch {
            print("❌ iOS: Failed to save Watch meditation to Supabase: \(error)")
            print("⚠️ iOS: Data is still saved in HealthKit on Watch")
            
            // TODO: Store in local queue for retry later
            // For now, meditation is safe in HealthKit on Watch
        }
    }
}

// MARK: - WCSessionDelegate

extension ConnectivityManager: WCSessionDelegate {
    
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            if let error = error {
                print("❌ iOS: WCSession activation failed: \(error)")
                return
            }
            
            print("✅ iOS: WCSession activated")
            isWatchAppInstalled = session.isWatchAppInstalled
            isWatchReachable = session.isReachable
        }
    }
    
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        print("⚠️ iOS: WCSession became inactive")
    }
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        print("⚠️ iOS: WCSession deactivated, reactivating...")
        session.activate()
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isWatchReachable = session.isReachable
            print("📱 iOS: Watch reachability changed: \(session.isReachable)")
        }
    }
    
    // MARK: - Receive Messages
    
    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String : Any],
        replyHandler: @escaping ([String : Any]) -> Void
    ) {
        Task { @MainActor in
            print("📱 iOS: Received message from Watch")
            
            if let messageType = message["type"] as? String {
                switch messageType {
                case "saveMeditation":
                    await handleMeditationData(message)
                    replyHandler(["status": "success"])
                    
                default:
                    print("⚠️ iOS: Unknown message type: \(messageType)")
                    replyHandler(["status": "unknown_type"])
                }
            } else {
                replyHandler(["status": "error", "message": "Missing type"])
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let meditationAdded = Notification.Name("meditationAdded")
}

