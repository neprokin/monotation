//
//  ConnectivityManager.swift
//  monotation Watch App
//
//  Manages Watch Connectivity for sending meditation data to iPhone
//

import Foundation
import WatchConnectivity
import Combine

@MainActor
class ConnectivityManager: NSObject, ObservableObject {
    static let shared = ConnectivityManager()
    
    @Published var isPhoneReachable: Bool = false
    @Published var isActivated: Bool = false
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - Wait for Activation
    
    private func waitForActivation() async throws {
        // If already activated, return immediately
        if isActivated && WCSession.default.activationState == .activated {
            return
        }
        
        // Wait up to 3 seconds for activation
        for _ in 0..<30 {
            if WCSession.default.activationState == .activated {
                return
            }
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
        
        throw ConnectivityError.activationTimeout
    }
    
    // MARK: - Send to iPhone
    
    func sendMeditationToPhone(
        duration: TimeInterval,
        averageHeartRate: Double,
        startTime: Date
    ) async throws {
        // Wait for session activation
        try await waitForActivation()
        
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
                isActivated = false
                return
            }
            
            isActivated = (activationState == .activated)
            isPhoneReachable = session.isReachable
            
            print("✅ Watch: WCSession activated (state: \(activationState.rawValue))")
            print("⌚️ Watch: iPhone reachable: \(session.isReachable)")
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
    case activationTimeout
    
    var errorDescription: String? {
        switch self {
        case .phoneNotReachable:
            return "iPhone недоступен"
        case .saveFailed:
            return "Не удалось сохранить"
        case .activationTimeout:
            return "Таймаут активации"
        }
    }
}

