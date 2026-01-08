//
//  ActiveMeditationView.swift
//  monotation Watch App
//
//  Active meditation screen with timer and heart rate
//  Handles meditation timer, pause/resume, and Smart Alarm integration
//

import SwiftUI
import WatchKit

struct ActiveMeditationView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var alarmController: MeditationAlarmController
    @Environment(\.dismiss) private var dismiss
    
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    @State private var isPaused: Bool = false
    @State private var isWaitingForAcknowledgment: Bool = false
    @State private var startTime: Date?
    @State private var endDate: Date?
    @State private var showCompletion: Bool = false
    
    private var duration: TimeInterval {
        workoutManager.selectedDuration
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            // Timer display
            Text(formatTime(timeRemaining))
                .font(.system(size: 48, weight: .light, design: .rounded))
                .monospacedDigit()
            
            // Heart rate (if available)
            if workoutManager.heartRate > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                    
                    Text("\(Int(workoutManager.heartRate))")
                        .font(.title2)
                        .monospacedDigit()
                    
                    Text("уд/мин")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Control buttons
            if isWaitingForAcknowledgment {
                // Button "Завершить" when waiting for acknowledgment
                Button {
                    acknowledgeMeditationCompletion()
                } label: {
                    Text("Завершить")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
            } else {
                // Normal control buttons
                HStack(spacing: 16) {
                    // Pause/Resume button
                    Button {
                        if isPaused {
                            resumeTimer()
                        } else {
                            pauseTimer()
                        }
                    } label: {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 60, height: 60)
                    .background(Color.primary.opacity(0.2))
                    .cornerRadius(30)
                    
                    // Stop button
                    Button {
                        stopTimer()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 50, height: 50)
                    .background(Color.primary.opacity(0.1))
                    .cornerRadius(25)
                }
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Initialize time remaining from settings
            timeRemaining = duration
            startTimer()
            
            // Вариант A: If user stopped Smart Alarm via system UI "Остановить",
            // automatically show CompletionView (without intermediate screen)
            checkAndHandleSystemStop()
        }
        .onChange(of: alarmController.wasStoppedBySystem) { oldValue, newValue in
            // Track flag change (may be set asynchronously after onAppear)
            if newValue {
                checkAndHandleSystemStop()
            }
        }
        .onDisappear {
            cleanup()
        }
        .fullScreenCover(isPresented: $showCompletion) {
            CompletionView(
                duration: duration - timeRemaining,
                averageHeartRate: workoutManager.averageHeartRate,
                startTime: startTime ?? Date(),
                pose: workoutManager.selectedPose,
                onDismiss: {
                    dismiss()
                }
            )
        }
    }
    
    // MARK: - System Stop Handling (Вариант A)
    
    /// Check if Smart Alarm was stopped via system UI "Остановить"
    /// and automatically show CompletionView
    private func checkAndHandleSystemStop() {
        if alarmController.wasStoppedBySystem {
            alarmController.resetStoppedBySystemFlag()
            isWaitingForAcknowledgment = false
            
            // Ensure timer is stopped and workout is ended
            timer?.invalidate()
            timer = nil
            if workoutManager.isSessionActive {
                workoutManager.endWorkout()
            }
            
            showCompletion = true
        }
    }
    
    // MARK: - Timer Control
    
    private func startTimer() {
        startTime = Date()
        endDate = Date().addingTimeInterval(timeRemaining)
        
        // Haptic feedback: confirmation of meditation start (UX only)
        WKInterfaceDevice.current().play(.start)
        
        // Smart Alarm should already be scheduled in MainView (before navigation)
        // Only reschedule if not already active (fallback)
        if !alarmController.isAlarmActive {
            alarmController.scheduleAlarm(at: endDate!)
        }
        
        // Visual timer for UI (NOT for guarantee - Smart Alarm is the guarantee)
        let meditationTimer = Timer(timeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.timerCompleted()
                }
            }
        }
        
        RunLoop.main.add(meditationTimer, forMode: .common)
        timer = meditationTimer
    }
    
    private func pauseTimer() {
        timer?.invalidate()
        timer = nil
        isPaused = true
        
        // Cancel Smart Alarm when paused (will reschedule on resume)
        alarmController.cancelAlarm()
    }
    
    private func resumeTimer() {
        isPaused = false
        
        // Recalculate new end date
        let newEndDate = Date().addingTimeInterval(timeRemaining)
        endDate = newEndDate
        
        // Reschedule Smart Alarm
        alarmController.scheduleAlarm(at: newEndDate)
        
        // Restart visual timer
        let meditationTimer = Timer(timeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.timerCompleted()
                }
            }
        }
        
        RunLoop.main.add(meditationTimer, forMode: .common)
        timer = meditationTimer
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isWaitingForAcknowledgment = false
        workoutManager.endWorkout()
        
        // Cancel Smart Alarm on early stop
        alarmController.cancelAlarm()
        
        // Show completion if at least 3 seconds passed
        if duration - timeRemaining >= 3 {
            showCompletion = true
        } else {
            dismiss()
        }
    }
    
    private func timerCompleted() {
        timer?.invalidate()
        timer = nil
        workoutManager.endWorkout()
        
        // DO NOT cancel Smart Alarm!
        // Smart Alarm should fire and provide system haptic + UI
        // System will automatically show alarm UI and repeat haptic
        
        // Transition to waiting for acknowledgment state
        isWaitingForAcknowledgment = true
    }
    
    /// Acknowledge meditation completion
    /// Called if user pressed "Завершить" in UI (not via system "Остановить")
    private func acknowledgeMeditationCompletion() {
        // Stop Smart Alarm (system haptic + UI)
        alarmController.cancelAlarm()
        
        // Show completion form
        isWaitingForAcknowledgment = false
        showCompletion = true
    }
    
    private func cleanup() {
        timer?.invalidate()
        timer = nil
        
        // DO NOT cancel Smart Alarm here!
        // Alarm should continue working if user hasn't acknowledged completion
        // It will be cancelled only in acknowledgeMeditationCompletion()
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ActiveMeditationView()
            .environmentObject(WorkoutManager())
            .environmentObject(MeditationAlarmController())
    }
}
