//
//  ActiveMeditationView.swift
//  monotation Watch App
//
//  Active meditation screen with timer and heart rate
//

import SwiftUI

struct ActiveMeditationView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) private var dismiss
    
    let duration: TimeInterval
    
    @State private var timeRemaining: TimeInterval
    @State private var timer: Timer?
    @State private var isPaused: Bool = false
    @State private var startTime: Date?
    @State private var showCompletion: Bool = false
    
    init(duration: TimeInterval) {
        self.duration = duration
        _timeRemaining = State(initialValue: duration)
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
                .background(Color.green)
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
                .background(Color.red)
                .cornerRadius(25)
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            cleanup()
        }
        .fullScreenCover(isPresented: $showCompletion) {
            CompletionView(
                duration: duration - timeRemaining,
                averageHeartRate: workoutManager.averageHeartRate,
                startTime: startTime ?? Date(),
                onDismiss: {
                    dismiss()
                }
            )
        }
    }
    
    // MARK: - Timer Control
    
    private func startTimer() {
        startTime = Date()
        workoutManager.startWorkout()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timerCompleted()
            }
        }
    }
    
    private func pauseTimer() {
        timer?.invalidate()
        isPaused = true
    }
    
    private func resumeTimer() {
        isPaused = false
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timerCompleted()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        workoutManager.endWorkout()
        
        // Show completion if at least 3 seconds passed
        if duration - timeRemaining >= 3 {
            showCompletion = true
        } else {
            dismiss()
        }
    }
    
    private func timerCompleted() {
        timer?.invalidate()
        workoutManager.endWorkout()
        
        // Haptic feedback
        WKInterfaceDevice.current().play(.success)
        
        showCompletion = true
    }
    
    private func cleanup() {
        timer?.invalidate()
        timer = nil
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
        ActiveMeditationView(duration: 300)
            .environmentObject(WorkoutManager())
    }
}

