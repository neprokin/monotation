//
//  WorkoutManager.swift
//  monotation Watch App
//
//  Manages HealthKit workout sessions and heart rate tracking
//

import Foundation
import HealthKit
import SwiftUI
import Combine

@MainActor
class WorkoutManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var heartRate: Double = 0
    @Published var averageHeartRate: Double = 0
    @Published var isSessionActive: Bool = false
    
    // MARK: - Private Properties
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    
    private var heartRateValues: [Double] = []
    private var sessionStartDate: Date?
    private var sessionEndDate: Date?
    
    // MARK: - Initialization
    override init() {
        super.init()
    }
    
    // MARK: - Request Authorization
    func requestAuthorization() async throws {
        let typesToShare: Set = [
            HKQuantityType.workoutType(),
            HKCategoryType(.mindfulSession)
        ]
        
        let typesToRead: Set = [
            HKQuantityType(.heartRate),
            HKQuantityType(.heartRateVariabilitySDNN),
            HKCategoryType(.mindfulSession)
        ]
        
        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
    }
    
    // MARK: - Start Workout Session
    func startWorkout() {
        Task {
            do {
                // Request authorization if needed
                try await requestAuthorization()
                
                // Configure workout
                let configuration = HKWorkoutConfiguration()
                configuration.activityType = .mindAndBody
                configuration.locationType = .indoor
                
                // Create session
                session = try HKWorkoutSession(
                    healthStore: healthStore,
                    configuration: configuration
                )
                
                builder = session?.associatedWorkoutBuilder()
                
                // Set data source
                builder?.dataSource = HKLiveWorkoutDataSource(
                    healthStore: healthStore,
                    workoutConfiguration: configuration
                )
                
                // Set delegates
                session?.delegate = self
                builder?.delegate = self
                
                // Start session
                sessionStartDate = Date()
                session?.startActivity(with: sessionStartDate)
                
                // Begin collection
                try await builder?.beginCollection(at: sessionStartDate!)
                
                isSessionActive = true
                
                print("✅ Workout session started")
            } catch {
                print("❌ Failed to start workout: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - End Workout Session
    func endWorkout() {
        Task {
            sessionEndDate = Date()
            session?.end()
            
            isSessionActive = false
            
            print("✅ Workout session ended")
        }
    }
    
    // MARK: - Finish and Save Workout
    func finishWorkout() async {
        guard let builder = builder, let session = session else { return }
        
        do {
            // End builder collection
            try await builder.endCollection(at: sessionEndDate ?? Date())
            
            // Finish workout
            let workout = try await builder.finishWorkout()
            
            // Save mindful session
            try await saveMindfulSession()
            
            print("✅ Workout saved: \(workout)")
            
            // Reset
            resetSession()
        } catch {
            print("❌ Failed to finish workout: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Save Mindful Session
    private func saveMindfulSession() async throws {
        guard let start = sessionStartDate, let end = sessionEndDate else { return }
        
        let mindfulSession = HKCategorySample(
            type: HKCategoryType(.mindfulSession),
            value: 0,
            start: start,
            end: end
        )
        
        try await healthStore.save(mindfulSession)
        
        print("✅ Mindful session saved to HealthKit")
    }
    
    // MARK: - Reset Session
    private func resetSession() {
        session = nil
        builder = nil
        heartRateValues = []
        sessionStartDate = nil
        sessionEndDate = nil
        heartRate = 0
        averageHeartRate = 0
    }
    
    // MARK: - Calculate Average Heart Rate
    private func calculateAverageHeartRate() {
        guard !heartRateValues.isEmpty else { return }
        let sum = heartRateValues.reduce(0, +)
        averageHeartRate = sum / Double(heartRateValues.count)
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        Task { @MainActor in
            switch toState {
            case .running:
                print("✅ Workout session running")
            case .ended:
                print("✅ Workout session ended")
                await finishWorkout()
            default:
                break
            }
        }
    }
    
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        print("❌ Workout session failed: \(error.localizedDescription)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        Task { @MainActor in
            // Get heart rate
            if collectedTypes.contains(HKQuantityType(.heartRate)) {
                if let heartRateQuantity = workoutBuilder.statistics(for: HKQuantityType(.heartRate))?.mostRecentQuantity() {
                    let heartRateValue = heartRateQuantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                    
                    heartRate = heartRateValue
                    heartRateValues.append(heartRateValue)
                    calculateAverageHeartRate()
                    
                    print("♥️ Heart Rate: \(Int(heartRateValue)) bpm")
                }
            }
        }
    }
    
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle workout events if needed
    }
}

