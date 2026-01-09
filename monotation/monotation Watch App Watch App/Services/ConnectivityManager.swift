//
//  ConnectivityManager.swift
//  monotation Watch App
//
//  Manages Watch Connectivity for sending meditation data to iPhone
//

import Foundation
import WatchConnectivity
import Combine
import CoreLocation

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
        
        print("⌚️ Watch: Waiting for WCSession activation...")
        
        // Wait up to 5 seconds for activation
        for i in 0..<50 {
            if WCSession.default.activationState == .activated {
                print("✅ Watch: WCSession activated after \(i * 100)ms")
                return
            }
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
        
        print("❌ Watch: WCSession activation timeout after 5s")
        throw ConnectivityError.activationTimeout
    }
    
    // MARK: - Send to iPhone
    
    func sendMeditationToPhone(
        duration: TimeInterval,
        averageHeartRate: Double,
        startTime: Date,
        pose: MeditationPose
    ) async throws {
        // Wait for session activation
        try await waitForActivation()
        
        guard WCSession.default.isReachable else {
            print("⌚️ Watch: iPhone not reachable, will try later")
            // TODO: Store locally and retry later
            throw ConnectivityError.phoneNotReachable
        }
        
        // Get location if available
        var latitude: Double? = nil
        var longitude: Double? = nil
        var locationName: String? = nil
        
        let locationService = LocationService.shared
        if locationService.authorizationStatus == .authorizedWhenInUse || 
           locationService.authorizationStatus == .authorizedAlways {
            do {
                let locationResult = try await locationService.getCurrentLocation()
                latitude = locationResult.latitude
                longitude = locationResult.longitude
                locationName = locationResult.address
            } catch {
                print("⚠️ Watch: Failed to get location: \(error.localizedDescription)")
            }
        }
        
        var message: [String: Any] = [
            "type": "saveMeditation",
            "duration": duration,
            "averageHeartRate": averageHeartRate,
            "startTime": startTime.timeIntervalSince1970,
            "pose": pose.rawValue
        ]
        
        // Add location data if available
        if let lat = latitude, let lon = longitude {
            message["latitude"] = lat
            message["longitude"] = lon
            if let name = locationName {
                message["locationName"] = name
            }
        }
        
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

