//
//  ExtendedRuntimeManager.swift
//  monotation Watch App
//
//  Manages WKExtendedRuntimeSession for background operation
//

import Foundation
import WatchKit
import Combine

@MainActor
class ExtendedRuntimeManager: NSObject, ObservableObject, WKExtendedRuntimeSessionDelegate {
    @Published var isActive: Bool = false  // NEW: Track session status
    private var session: WKExtendedRuntimeSession?
    
    func start() {
        // Avoid starting multiple sessions
        guard session == nil else {
            print("⚠️ [ExtendedRuntime] Session already active")
            return
        }
        
        print("🚀 [ExtendedRuntime] Starting session...")
        session = WKExtendedRuntimeSession()
        session?.delegate = self
        session?.start()
    }
    
    func stop() {
        guard session != nil else {
            print("⚠️ [ExtendedRuntime] No session to stop")
            return
        }
        
        print("⏹️ [ExtendedRuntime] Stopping session...")
        session?.invalidate()
        session = nil
        isActive = false
    }
    
    // MARK: - WKExtendedRuntimeSessionDelegate
    
    nonisolated func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        Task { @MainActor in
            self.isActive = true
            print("✅ [ExtendedRuntime] Session ACTIVE - background operation enabled")
        }
    }
    
    nonisolated func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        Task { @MainActor in
            print("⚠️ [ExtendedRuntime] Session will expire soon")
        }
    }
    
    nonisolated func extendedRuntimeSession(
        _ extendedRuntimeSession: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
        error: Error?
    ) {
        Task { @MainActor in
            self.isActive = false
            
            let reasonText: String
            switch reason {
            case .expired:
                reasonText = "expired (time limit reached)"
            case .error:
                reasonText = "error occurred"
            @unknown default:
                reasonText = "unknown reason (\(reason.rawValue))"
            }
            
            print("❌ [ExtendedRuntime] Session INVALIDATED - \(reasonText)")
            if let error = error {
                print("   Error details: \(error.localizedDescription)")
            }
        }
    }
}

