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
    @EnvironmentObject var runtimeManager: ExtendedRuntimeManager
    @EnvironmentObject var alarmController: MeditationAlarmController  // Smart Alarm - ГЛАВНАЯ гарантия
    @Environment(\.dismiss) private var dismiss
    
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    @State private var completionSignalTimer: Timer?  // Для повторяющихся вибраций (best-effort)
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
    
    // MARK: - Notification IDs for scheduled end notifications
    private static let endNotificationId = "meditation.end"
    private static let endNotificationId2 = "meditation.end.2"
    private static let endNotificationId3 = "meditation.end.3"
    
    // MARK: - Timer Control
    
    private func startTimer() {
        startTime = Date()
        endDate = Date().addingTimeInterval(timeRemaining)
        
        print("🎯 [ActiveMeditation] Starting meditation timer")
        print("📊 [ActiveMeditation] End date: \(endDate!)")
        
        // NOTE: Workout session already started in MainView during countdown
        // This is for HR tracking, NOT for alarm guarantee
        
        // Haptic feedback: подтверждение старта медитации
        print("📳 [ActiveMeditation] Playing START haptic")
        WKInterfaceDevice.current().play(.start)
        
        // ========================================
        // КОНТУР 1 (ГЛАВНЫЙ): Smart Alarm
        // Это СИСТЕМНЫЙ механизм "будильника"
        // Гарантированно работает в AOD/wrist-down
        // ========================================
        alarmController.scheduleAlarm(at: endDate!)
        
        // ========================================
        // КОНТУР 2 (FALLBACK): Local Notifications
        // На случай если Smart Alarm не сработает
        // ========================================
        scheduleEndNotification(after: timeRemaining)
        
        // ========================================
        // КОНТУР 3 (ВИЗУАЛЬНЫЙ): Timer для UI
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
        
        // Отменяем Smart Alarm и уведомления при паузе
        alarmController.cancelAlarm()
        cancelEndNotification()
        print("⏸️ [ActiveMeditation] Paused - cancelled alarm and notifications")
    }
    
    private func resumeTimer() {
        isPaused = false
        
        // Пересчитываем новое время завершения
        let newEndDate = Date().addingTimeInterval(timeRemaining)
        endDate = newEndDate
        
        // Перепланируем Smart Alarm и уведомления
        alarmController.rescheduleAlarm(at: newEndDate)
        scheduleEndNotification(after: timeRemaining)
        print("▶️ [ActiveMeditation] Resumed - rescheduled for \(newEndDate)")
        
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
        completionSignalTimer?.invalidate()
        completionSignalTimer = nil
        isWaitingForAcknowledgment = false
        workoutManager.endWorkout()
        
        // Отменяем Smart Alarm и уведомления при досрочном завершении
        alarmController.cancelAlarm()
        cancelEndNotification()
        print("⏹️ [ActiveMeditation] Stopped early - cancelled alarm and notifications")
        
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
        print("📊 [ActiveMeditation] Alarm scheduled: \(alarmController.isAlarmScheduled)")
        
        // НЕ отменяем Smart Alarm и уведомления!
        // Smart Alarm должен сработать и дать системный haptic
        // Уведомления - fallback если Smart Alarm не сработает
        
        // Переходим в состояние ожидания подтверждения
        isWaitingForAcknowledgment = true
        
        // Best-effort: локальный haptic на случай если приложение активно
        // Smart Alarm даст системный haptic независимо от этого
        startCompletionSignals()
    }
    
    // MARK: - Scheduled Notification (Контур 1 - гарантия в AOD/wrist-down)
    
    /// Планируем НЕСКОЛЬКО уведомлений ЗАРАНЕЕ на время окончания медитации
    /// Это гарантирует доставку даже если приложение в background/inactive (AOD/wrist-down)
    /// Планируем 3 уведомления: T_end, T_end+5s, T_end+10s для надёжности
    private func scheduleEndNotification(after seconds: TimeInterval) {
        let center = UNUserNotificationCenter.current()
        
        // Удаляем все предыдущие уведомления
        center.removePendingNotificationRequests(withIdentifiers: [
            Self.endNotificationId,
            Self.endNotificationId2,
            Self.endNotificationId3
        ])
        
        // Планируем 3 уведомления с интервалом 5 секунд
        let delays: [(String, TimeInterval)] = [
            (Self.endNotificationId, 0),
            (Self.endNotificationId2, 5),
            (Self.endNotificationId3, 10)
        ]
        
        for (id, delay) in delays {
            let content = UNMutableNotificationContent()
            content.title = delay == 0 ? "Медитация завершена" : "🧘 Медитация завершена"
            content.body = delay == 0 ? "Нажмите, чтобы завершить" : "Нажмите для подтверждения"
            content.sound = .default  // Системный звук + haptic на watchOS
            content.interruptionLevel = .timeSensitive  // Высокий приоритет
            
            // Минимум 1 секунда для trigger
            let triggerTime = max(1, seconds + delay)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerTime, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: id,
                content: content,
                trigger: trigger
            )
            
            center.add(request) { error in
                if let error = error {
                    print("❌ [ActiveMeditation] Failed to schedule notification \(id): \(error)")
                } else {
                    print("📅 [ActiveMeditation] Scheduled notification \(id) for \(triggerTime)s from now")
                }
            }
        }
    }
    
    /// Отменяем ВСЕ запланированные уведомления (при паузе, досрочном завершении, подтверждении)
    private func cancelEndNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [
                Self.endNotificationId,
                Self.endNotificationId2,
                Self.endNotificationId3
            ])
        // Также удаляем уже доставленные уведомления из центра
        UNUserNotificationCenter.current()
            .removeDeliveredNotifications(withIdentifiers: [
                Self.endNotificationId,
                Self.endNotificationId2,
                Self.endNotificationId3
            ])
        print("🚫 [ActiveMeditation] Cancelled all pending/delivered notifications")
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
    
    // Подтвердить завершение медитации
    private func acknowledgeMeditationCompletion() {
        print("✅ [ActiveMeditation] User acknowledged completion - stopping all signals")
        
        // Останавливаем ВСЁ:
        // 1. Smart Alarm (системный haptic)
        alarmController.cancelAlarm()
        
        // 2. Local notifications (fallback)
        cancelEndNotification()
        
        // 3. Локальный haptic timer (best-effort)
        completionSignalTimer?.invalidate()
        completionSignalTimer = nil
        
        // Показываем форму завершения
        isWaitingForAcknowledgment = false
        showCompletion = true
    }
    
    private func cleanup() {
        print("🧹 [ActiveMeditation] Cleanup")
        timer?.invalidate()
        timer = nil
        completionSignalTimer?.invalidate()
        completionSignalTimer = nil
        
        // НЕ отменяем Smart Alarm здесь!
        // Alarm должен продолжать работать если пользователь не подтвердил завершение
        // Он будет отменён только в acknowledgeMeditationCompletion()
        
        // Но уведомления отменяем - они были fallback
        cancelEndNotification()
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

