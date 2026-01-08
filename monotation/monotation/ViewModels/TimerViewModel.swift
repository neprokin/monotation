//
//  TimerViewModel.swift
//  monotation
//
//  Timer logic and state management
//

import Foundation
import Combine
import SwiftUI
import UIKit

@MainActor
class TimerViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var timerState: TimerState = .idle
    @Published var selectedDuration: TimeInterval = 600 // 10 minutes default
    @Published var remainingTime: TimeInterval = 600 // Initialize with default duration
    @Published var showMeditationForm = false
    
    // MARK: - Private Properties
    
    private var timer: AnyCancellable?
    private var completionSignalTimer: AnyCancellable?  // For repeating completion signals
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid  // For background execution
    private var startTime: Date?
    private var endTime: Date?
    private var backgroundEnteredDate: Date?
    private let notificationService = NotificationService.shared
    private let hapticFeedback = HapticFeedback.shared  // For haptic feedback
    
    // MARK: - Initialization
    
    init() {
        setupNotificationObservers()
    }
    
    deinit {
        timer?.cancel()
        completionSignalTimer?.cancel()
        
        // Cleanup background task (directly call UIApplication, not MainActor method)
        let taskID = backgroundTaskID
        if taskID != .invalid {
            Task { @MainActor in
                UIApplication.shared.endBackgroundTask(taskID)
            }
        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Timer Control
    
    func selectDuration(_ duration: TimeInterval) {
        selectedDuration = duration
        remainingTime = duration
        // Stay in idle state when selecting, so controls remain visible
        timerState = .idle
    }
    
    func startTimerAfterCountdown() {
        startTime = Date()
        remainingTime = selectedDuration
        timerState = .running(remainingTime: selectedDuration)
        
        // Haptic + sound confirmation of start
        hapticFeedback.playMeditationStart()
        
        // Start background task to keep running in background
        beginBackgroundTask()
        
        // Schedule notification for timer completion
        scheduleTimerNotification()
        
        // Start countdown
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }
    }
    
    func pauseTimer() {
        timer?.cancel()
        timer = nil
        timerState = .paused(remainingTime: remainingTime)
    }
    
    func resumeTimer() {
        guard case .paused = timerState else { return }
        
        // Adjust startTime to account for pause
        let pausedDuration = selectedDuration - remainingTime
        startTime = Date().addingTimeInterval(-pausedDuration)
        
        timerState = .running(remainingTime: remainingTime)
        
        // Resume countdown
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }
    }
    
    func stopTimer() {
        timer?.cancel()
        timer = nil
        completionSignalTimer?.cancel()
        completionSignalTimer = nil
        
        // End background task
        endBackgroundTask()
        
        // Cancel notification
        cancelTimerNotification()
        
        // If timer was running, save the session and show form
        if startTime != nil {
            endTime = Date()
            timerState = .completed
            showMeditationForm = true
        } else {
            // If timer wasn't started, just reset
            timerState = .idle
            remainingTime = selectedDuration
            startTime = nil
            endTime = nil
        }
    }
    
    private func updateTimer() {
        guard startTime != nil else { return }
        
        let elapsed = Date().timeIntervalSince(startTime!)
        remainingTime = max(0, selectedDuration - elapsed)
        
        if remainingTime <= 0 {
            completeTimer()
        }
    }
    
    private func completeTimer() {
        timer?.cancel()
        timer = nil
        endTime = Date()
        
        // Transition to waiting for acknowledgment state
        timerState = .completedWaitingForAcknowledgment
        
        // Cancel scheduled notification (timer completed naturally)
        cancelTimerNotification()
        
        // Start repeating completion signals every second
        startCompletionSignals()
    }
    
    /// Start repeating completion signals
    private func startCompletionSignals() {
        // First signal immediately
        playCompletionSignal()
        
        // Then every second
        completionSignalTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.playCompletionSignal()
            }
    }
    
    /// Play completion signal (sound + haptic)
    private func playCompletionSignal() {
        hapticFeedback.playMeditationCompletion()
    }
    
    /// Stop signals and acknowledge meditation completion
    func acknowledgeMeditationCompletion() {
        // Stop repeating signals
        completionSignalTimer?.cancel()
        completionSignalTimer = nil
        
        // End background task
        endBackgroundTask()
        
        // Переходим в финальное состояние
        timerState = .completed
        
        // Показываем форму
        showMeditationForm = true
    }
    
    // MARK: - Background Task Management
    
    private func beginBackgroundTask() {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            // Task is about to expire, clean up
            self?.endBackgroundTask()
        }
        print("✅ Background task started: \(backgroundTaskID.rawValue)")
    }
    
    private func endBackgroundTask() {
        guard backgroundTaskID != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
        print("⏹️ Background task ended")
    }
    
    // MARK: - Computed Properties
    
    var formattedTime: String {
        remainingTime.asMinutesSeconds
    }
    
    var progress: Double {
        guard selectedDuration > 0 else { return 0 }
        return 1 - (remainingTime / selectedDuration)
    }
    
    var isRunning: Bool {
        if case .running = timerState { return true }
        return false
    }
    
    var isPaused: Bool {
        if case .paused = timerState { return true }
        return false
    }
    
    // MARK: - Background Mode Handling
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        guard isRunning else { return }
        backgroundEnteredDate = Date()
        scheduleTimerNotification()
    }
    
    @objc private func appWillEnterForeground() {
        guard let backgroundDate = backgroundEnteredDate, isRunning else { return }
        
        // Calculate time spent in background
        let timeInBackground = Date().timeIntervalSince(backgroundDate)
        remainingTime = max(0, remainingTime - timeInBackground)
        
        if remainingTime <= 0 {
            completeTimer()
        }
        
        backgroundEnteredDate = nil
        cancelTimerNotification()
    }
    
    // MARK: - Notifications
    
    private func scheduleTimerNotification() {
        notificationService.scheduleTimerCompletionNotification(in: remainingTime)
    }
    
    private func cancelTimerNotification() {
        notificationService.cancelTimerNotification()
    }
    
    // MARK: - Haptic Feedback
    
    private func triggerHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // MARK: - Reset Timer
    
    func resetTimer() {
        timer?.cancel()
        timer = nil
        completionSignalTimer?.cancel()
        completionSignalTimer = nil
        
        // End background task if still active
        endBackgroundTask()
        
        timerState = .idle
        remainingTime = selectedDuration
        startTime = nil
        endTime = nil
        showMeditationForm = false
    }
    
    // MARK: - Meditation Session Info
    
    func getMeditationSessionInfo() -> (startTime: Date, endTime: Date)? {
        guard let start = startTime, let end = endTime else { return nil }
        return (start, end)
    }
}

// MARK: - Timer State
enum TimerState: Equatable {
    case idle
    case selecting(duration: TimeInterval)
    case running(remainingTime: TimeInterval)
    case paused(remainingTime: TimeInterval)
    case completedWaitingForAcknowledgment  // Meditation completed, waiting for acknowledgment
    case completed  // Acknowledged, show form
    
    var isRunning: Bool {
        if case .running = self { return true }
        return false
    }
    
    var isPaused: Bool {
        if case .paused = self { return true }
        return false
    }
    
    var isWaitingForAcknowledgment: Bool {
        if case .completedWaitingForAcknowledgment = self { return true }
        return false
    }
}

