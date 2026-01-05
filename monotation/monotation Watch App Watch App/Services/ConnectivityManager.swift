//
//  ConnectivityManager.swift
//  monotation Watch App
//
//  Manages Watch Connectivity for sending meditation data to iPhone
//

import Foundation
import WatchConnectivity

@MainActor
class ConnectivityManager: NSObject, ObservableObject {
    static let shared = ConnectivityManager()
    
    @Published var isPhoneReachable: Bool = false
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - Send to iPhone
    
    func sendMeditationToPhone(
        duration: TimeInterval,
        averageHeartRate: Double,
        startTime: Date
    ) async throws {
        guard WCSession.default.isReachable else {
            print("⌚️ Watch: iPhone not reachable, will try later")
            // TODO: Store locally and retry later
            throw ConnectivityError.phoneNotReachable
        }
        
        let message: [String: Any] = [
            "type": "saveMeditation",
            "duration": duration,
            "averageHeartRate": averageHeartRate,
            "startTime": startTime.timeIntervalSince1970
        ]
        
        print("⌚️ Watch: Sending meditation to iPhone...")
        print("   Duration: \(Int(duration))s, HR: \(Int(averageHeartRate)) bpm")
        
        return try await withCheckedThrowingContinuation { continuation in
            WCSession.default.sendMessage(message, replyHandler: { reply in
                print("✅ Watch: iPhone confirmed receipt")
                if let status = reply["status"] as? String, status == "success" {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: ConnectivityError.saveFailed)
                }
            }, errorHandler: { error in
                print("❌ Watch: Failed to send to iPhone: \(error)")
                continuation.resume(throwing: error)
            })
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
                print("❌ Watch: WCSession activation failed: \(error)")
                return
            }
            
            print("✅ Watch: WCSession activated")
            isPhoneReachable = session.isReachable
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isPhoneReachable = session.isReachable
            print("⌚️ Watch: iPhone reachability changed: \(session.isReachable)")
        }
    }
}

// MARK: - Errors

enum ConnectivityError: LocalizedError {
    case phoneNotReachable
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .phoneNotReachable:
            return "iPhone недоступен"
        case .saveFailed:
            return "Не удалось сохранить"
        }
    }
}

