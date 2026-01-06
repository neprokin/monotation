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
    private var session: WKExtendedRuntimeSession?
    
    func start() {
        // Avoid starting multiple sessions
        guard session == nil else {
            print("⚠️ Extended runtime session already active")
            return
        }
        
        session = WKExtendedRuntimeSession()
        session?.delegate = self
        session?.start()
        print("✅ Extended runtime session started")
    }
    
    func stop() {
        session?.invalidate()
        session = nil
        print("⏹️ Extended runtime session stopped")
    }
    
    // MARK: - WKExtendedRuntimeSessionDelegate
    
    nonisolated func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        Task { @MainActor in
            print("✅ Extended runtime session started successfully")
        }
    }
    
    nonisolated func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        Task { @MainActor in
            print("⚠️ Extended runtime session will expire")
        }
    }
    
    nonisolated func extendedRuntimeSession(
        _ extendedRuntimeSession: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
        error: Error?
    ) {
        Task { @MainActor in
            print("❌ Extended runtime session invalidated: \(reason.rawValue)")
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}

