//
//  ActiveMeditationView.swift
//  monotation Watch App
//
//  Active meditation screen with timer and heart rate
//

import SwiftUI
import UserNotifications
import WatchKit

struct ActiveMeditationView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var runtimeManager: ExtendedRuntimeManager  // Получаем из App через environment
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
    
    // MARK: - Notification ID for scheduled end notification
    private static let endNotificationId = "meditation.end"
    
    // MARK: - Timer Control
    
    private func startTimer() {
        startTime = Date()
        
        print("🎯 [ActiveMeditation] Starting meditation timer")
        print("📊 [ActiveMeditation] Runtime session active: \(runtimeManager.isActive)")
        
        // NOTE: Workout session already started in MainView during countdown
        // This automatically enables Extended Runtime Session, so Timer works in background
        
        // Haptic feedback: подтверждение старта медитации (Контур 2 - когда app активно)
        print("📳 [ActiveMeditation] Playing START haptic")
        WKInterfaceDevice.current().play(.start)
        
        // CRITICAL: Контур 1 - планируем уведомление ЗАРАНЕЕ на время T_end
        // Это гарантирует вибрацию в AOD/wrist-down, даже если приложение в background
        scheduleEndNotification(after: timeRemaining)
        
        // Use Timer with RunLoop.main and .common mode (works in background)
        // CRITICAL: Use Task { @MainActor } instead of DispatchQueue.main.async
        // This ensures timer works even when screen is locked
        let meditationTimer = Timer(timeInterval: 1.0, repeats: true) { timer in
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
        timer = nil  // NEW: clear reference to prevent memory leak
        isPaused = true
        
        // Отменяем запланированное уведомление при паузе
        cancelEndNotification()
        print("⏸️ [ActiveMeditation] Paused - cancelled end notification")
    }
    
    private func resumeTimer() {
        isPaused = false
        
        // Перепланируем уведомление на новое время T_end
        scheduleEndNotification(after: timeRemaining)
        print("▶️ [ActiveMeditation] Resumed - rescheduled end notification for \(timeRemaining)s")
        
        // Use Timer with RunLoop.main and .common mode (works in background)
        // CRITICAL: Use Task { @MainActor } instead of DispatchQueue.main.async
        // This ensures timer works even when screen is locked
        let meditationTimer = Timer(timeInterval: 1.0, repeats: true) { timer in
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
        completionSignalTimer?.invalidate()  // NEW: останавливаем вибрации
        completionSignalTimer = nil
        isWaitingForAcknowledgment = false  // NEW: сбрасываем состояние
        workoutManager.endWorkout()
        
        // Отменяем запланированное уведомление при досрочном завершении
        cancelEndNotification()
        print("⏹️ [ActiveMeditation] Stopped early - cancelled end notification")
        
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
        print("📊 [ActiveMeditation] Runtime session active: \(runtimeManager.isActive)")
        
        // Отменяем запланированное уведомление - мы сами обработаем завершение
        // (если приложение активно, уведомление не нужно - мы покажем haptic напрямую)
        cancelEndNotification()
        
        // NEW: Переходим в состояние ожидания подтверждения
        isWaitingForAcknowledgment = true
        
        // NEW: Контур 2 - когда приложение активно, играем haptic напрямую
        // Если приложение в background, системное уведомление уже должно было прийти
        startCompletionSignals()
    }
    
    // MARK: - Scheduled Notification (Контур 1 - гарантия в AOD/wrist-down)
    
    /// Планируем уведомление ЗАРАНЕЕ на время окончания медитации
    /// Это гарантирует доставку даже если приложение в background/inactive (AOD/wrist-down)
    private func scheduleEndNotification(after seconds: TimeInterval) {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Медитация завершена"
        content.body = "Нажмите, чтобы завершить сессию"
        content.sound = .default  // Системный звук + haptic
        content.interruptionLevel = .timeSensitive  // Высокий приоритет
        
        // Минимум 1 секунда для trigger
        let triggerTime = max(1, seconds)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerTime, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: Self.endNotificationId,
            content: content,
            trigger: trigger
        )
        
        // Удаляем предыдущее уведомление (если было) и добавляем новое
        center.removePendingNotificationRequests(withIdentifiers: [Self.endNotificationId])
        center.add(request) { error in
            if let error = error {
                print("❌ [ActiveMeditation] Failed to schedule end notification: \(error)")
            } else {
                print("📅 [ActiveMeditation] Scheduled end notification for \(triggerTime)s from now")
            }
        }
    }
    
    /// Отменяем запланированное уведомление (при паузе, досрочном завершении, или когда обрабатываем сами)
    private func cancelEndNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.endNotificationId])
        print("🚫 [ActiveMeditation] Cancelled pending end notification")
    }
    
    // NEW: Контур 2 - начать повторяющиеся вибрации о завершении (когда app активно)
    // Если приложение в background (AOD/wrist-down), то уже должно было прийти
    // запланированное заранее системное уведомление (Контур 1)
    private func startCompletionSignals() {
        print("🔔 [ActiveMeditation] Starting repeating completion signals (Контур 2 - app active)")
        
        // Первая вибрация сразу
        playCompletionSignal()
        
        // Затем каждую секунду (используем Timer с .common mode)
        // CRITICAL: Use Task { @MainActor } instead of DispatchQueue.main.async
        // This ensures haptic signals work even when screen is locked
        let signalTimer = Timer(timeInterval: 1.0, repeats: true) { timer in
            Task { @MainActor in
                self.playCompletionSignal()
            }
        }
        
        RunLoop.main.add(signalTimer, forMode: .common)
        completionSignalTimer = signalTimer
    }
    
    // NEW: Воспроизвести вибрацию завершения (БЕЗ звука на часах)
    private func playCompletionSignal() {
        print("📳 [ActiveMeditation] Playing COMPLETION haptic (session active: \(runtimeManager.isActive))")
        // .notification - stronger haptic for important alerts, works better in AOD
        WKInterfaceDevice.current().play(.notification)
    }
    
    // NEW: Подтвердить завершение медитации
    private func acknowledgeMeditationCompletion() {
        print("✅ [ActiveMeditation] User acknowledged completion - stopping signals")
        
        // Останавливаем вибрации (Контур 2)
        completionSignalTimer?.invalidate()
        completionSignalTimer = nil
        
        // Отменяем pending уведомление если оно ещё не доставлено (Контур 1)
        cancelEndNotification()
        
        // Показываем форму завершения
        isWaitingForAcknowledgment = false
        showCompletion = true
    }
    
    private func cleanup() {
        print("🧹 [ActiveMeditation] Cleanup")
        timer?.invalidate()
        timer = nil
        completionSignalTimer?.invalidate()  // очистка таймера вибраций (Контур 2)
        completionSignalTimer = nil
        cancelEndNotification()  // отмена pending уведомления (Контур 1)
        // NOTE: Workout session will be ended by WorkoutManager when meditation completes
        // No need to stop Extended Runtime Session - it's managed by Workout Session
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
    }
}

