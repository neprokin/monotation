//
//  ActiveMeditationView.swift
//  monotation Watch App
//
//  Active meditation screen with timer and heart rate
//

import SwiftUI
import WatchKit

struct ActiveMeditationView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var runtimeManager: ExtendedRuntimeManager
    @EnvironmentObject var alarmController: MeditationAlarmController  // Smart Alarm - ГЛАВНАЯ гарантия
    @Environment(\.dismiss) private var dismiss
    
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    @State private var isPaused: Bool = false
    @State private var isWaitingForAcknowledgment: Bool = false
    @State private var startTime: Date?
    @State private var endDate: Date?  // Время завершения медитации
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
            
            // Вариант A: Если пользователь остановил Smart Alarm через системный UI "Остановить",
            // автоматически показываем CompletionView (без промежуточного экрана)
            checkAndHandleSystemStop()
        }
        .onChange(of: alarmController.wasStoppedBySystem) { oldValue, newValue in
            // Отслеживаем изменение флага (может установиться асинхронно после onAppear)
            if newValue {
                print("🔄 [ActiveMeditation] wasStoppedBySystem changed to true - showing completion")
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
    
    /// Проверяет, был ли Smart Alarm остановлен через системный UI "Остановить"
    /// и автоматически показывает CompletionView
    private func checkAndHandleSystemStop() {
        print("🔍 [ActiveMeditation] Checking wasStoppedBySystem: \(alarmController.wasStoppedBySystem)")
        if alarmController.wasStoppedBySystem {
            print("✅ [ActiveMeditation] User stopped via system UI - showing completion immediately")
            alarmController.resetStoppedBySystemFlag()
            isWaitingForAcknowledgment = false
            
            // Убеждаемся, что timer остановлен и workout завершён
            timer?.invalidate()
            timer = nil
            if workoutManager.isSessionActive {
                workoutManager.endWorkout()
            }
            
            showCompletion = true
        } else {
            print("ℹ️ [ActiveMeditation] wasStoppedBySystem is false - normal flow")
        }
    }
    
    // MARK: - Timer Control
    
    private func startTimer() {
        startTime = Date()
        endDate = Date().addingTimeInterval(timeRemaining)
        
        print("🎯 [ActiveMeditation] Starting meditation timer")
        print("📊 [ActiveMeditation] End date: \(endDate!)")
        
        // NOTE: Workout session already started in MainView during countdown
        // This is for HR tracking, NOT for alarm guarantee
        
        // Haptic feedback: подтверждение старта медитации (UX только)
        print("📳 [ActiveMeditation] Playing START haptic")
        WKInterfaceDevice.current().play(.start)
        
        // ========================================
        // КОНТУР 1 (ЕДИНСТВЕННАЯ ГАРАНТИЯ): Smart Alarm
        // Это СИСТЕМНЫЙ механизм "будильника"
        // Гарантированно работает в AOD/wrist-down
        // ========================================
        // NOTE: Smart Alarm should already be scheduled in MainView (before navigation)
        // when app was still active. Only reschedule if not already active.
        if !alarmController.isAlarmActive {
            // Fallback: try to schedule if not already done (may fail if screen is locked)
            alarmController.scheduleAlarm(at: endDate!)
            print("📅 [ActiveMeditation] Smart Alarm scheduled (fallback) for \(endDate!)")
        } else {
            print("📅 [ActiveMeditation] Smart Alarm already scheduled (from MainView)")
        }
        
        // ========================================
        // КОНТУР 2 (ВИЗУАЛЬНЫЙ): Timer для UI
        // Только для отображения обратного отсчёта
        // НЕ для гарантии уведомления!
        // ========================================
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
        
        // Отменяем Smart Alarm при паузе (перепланируем при resume)
        alarmController.cancelAlarm()
        print("⏸️ [ActiveMeditation] Paused - cancelled alarm")
    }
    
    private func resumeTimer() {
        isPaused = false
        
        // Пересчитываем новое время завершения
        let newEndDate = Date().addingTimeInterval(timeRemaining)
        endDate = newEndDate
        
        // Перепланируем Smart Alarm
        alarmController.scheduleAlarm(at: newEndDate)
        print("▶️ [ActiveMeditation] Resumed - Smart Alarm rescheduled for \(newEndDate)")
        
        // Перезапускаем визуальный Timer
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
        isWaitingForAcknowledgment = false
        workoutManager.endWorkout()
        
        // Отменяем Smart Alarm при досрочном завершении
        alarmController.cancelAlarm()
        print("⏹️ [ActiveMeditation] Stopped early - cancelled alarm")
        
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
        
        print("⏰ [ActiveMeditation] Timer COMPLETED")
        print("📊 [ActiveMeditation] Smart Alarm active: \(alarmController.isAlarmActive)")
        
        // НЕ отменяем Smart Alarm!
        // Smart Alarm должен сработать и дать системный haptic + UI
        // Система автоматически покажет alarm UI и будет повторять haptic
        
        // Переходим в состояние ожидания подтверждения
        isWaitingForAcknowledgment = true
    }
    
    // Подтвердить завершение медитации
    // Вызывается если пользователь нажал "Завершить" в UI (не через системный "Остановить")
    private func acknowledgeMeditationCompletion() {
        print("✅ [ActiveMeditation] User acknowledged completion via app UI - stopping Smart Alarm")
        
        // Останавливаем Smart Alarm (системный haptic + UI)
        alarmController.cancelAlarm()
        
        // Показываем форму завершения
        isWaitingForAcknowledgment = false
        showCompletion = true
    }
    
    private func cleanup() {
        print("🧹 [ActiveMeditation] Cleanup")
        timer?.invalidate()
        timer = nil
        
        // НЕ отменяем Smart Alarm здесь!
        // Alarm должен продолжать работать если пользователь не подтвердил завершение
        // Он будет отменён только в acknowledgeMeditationCompletion()
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
            .environmentObject(ExtendedRuntimeManager())
            .environmentObject(MeditationAlarmController())
    }
}

