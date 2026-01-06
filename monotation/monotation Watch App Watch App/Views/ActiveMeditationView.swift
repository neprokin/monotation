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
    
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    @State private var completionSignalTimer: Timer?  // NEW: для повторяющихся вибраций
    @State private var isPaused: Bool = false
    @State private var isWaitingForAcknowledgment: Bool = false  // NEW: состояние ожидания подтверждения
    @State private var startTime: Date?
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
                // NEW: Кнопка "Завершить" при ожидании подтверждения
                Button {
                    acknowledgeMeditationCompletion()
                } label: {
                    Text("Завершить")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
            } else {
                // Обычные кнопки управления
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
                    .background(Color.primary.opacity(0.2))  // Монохромная тема
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
                    .background(Color.primary.opacity(0.1))  // Монохромная тема
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
    
    // MARK: - Timer Control
    
    private func startTimer() {
        startTime = Date()
        
        // Haptic feedback: подтверждение старта медитации
        WKInterfaceDevice.current().play(.start)
        
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
        completionSignalTimer?.invalidate()  // NEW: останавливаем вибрации
        completionSignalTimer = nil
        isWaitingForAcknowledgment = false  // NEW: сбрасываем состояние
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
        
        // NEW: Переходим в состояние ожидания подтверждения
        isWaitingForAcknowledgment = true
        
        // NEW: Начинаем повторяющиеся вибрации каждую секунду
        startCompletionSignals()
    }
    
    // NEW: Начать повторяющиеся вибрации о завершении
    private func startCompletionSignals() {
        // Первая вибрация сразу
        playCompletionSignal()
        
        // Затем каждую секунду
        completionSignalTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            playCompletionSignal()
        }
    }
    
    // NEW: Воспроизвести вибрацию завершения (БЕЗ звука на часах)
    private func playCompletionSignal() {
        // .success - короткая четкая вибрация (не длинный паттерн как .notification)
        WKInterfaceDevice.current().play(.success)
    }
    
    // NEW: Подтвердить завершение медитации
    private func acknowledgeMeditationCompletion() {
        // Останавливаем вибрации
        completionSignalTimer?.invalidate()
        completionSignalTimer = nil
        
        // Показываем форму завершения
        isWaitingForAcknowledgment = false
        showCompletion = true
    }
    
    private func cleanup() {
        timer?.invalidate()
        timer = nil
        completionSignalTimer?.invalidate()  // NEW: очистка таймера вибраций
        completionSignalTimer = nil
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
    }
}

