//
//  MainView.swift
//  monotation Watch App
//
//  Main screen with emoji, title, and play button (like Apple Workout)
//  Handles countdown sequence before meditation starts
//

import SwiftUI
import WatchKit

struct MainView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var alarmController: MeditationAlarmController
    @State private var showSettings = false
    @State private var countdownPhase: Int = -1 // -1 = idle, 0-3 = countdown
    @State private var navigateToMeditation = false
    @State private var countdownTimer: Timer?
    @State private var countdownTickCount: Int = 0
    
    var body: some View {
        NavigationStack {
            if countdownPhase >= 0 {
                // Countdown screen
                countdownView
                    .navigationBarHidden(true)
            } else {
                // Main screen (like Apple Workout)
                mainScreen
            }
        }
    }
    
    // MARK: - Main Screen
    
    private var mainScreen: some View {
        VStack(spacing: 0) {
            // Content area
            VStack(spacing: 4) {
                Spacer()
                
                // Emoji icon
                Text("🧘")
                    .font(.system(size: 40))
                
                // Title
                Text("Медитация")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            // Bottom toolbar with Play button
            HStack {
                Spacer()
                
                Button {
                    startCountdown()
                } label: {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "play.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.black)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(.bottom, 8)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            WatchSettingsView()
        }
        .fullScreenCover(isPresented: $navigateToMeditation) {
            ActiveMeditationView()
        }
        .onChange(of: navigateToMeditation) { oldValue, newValue in
            if !newValue {
                // Returning to main screen - cleanup
                cleanup()
            }
        }
    }
    
    // MARK: - Countdown View
    
    private var countdownView: some View {
        VStack {
            Spacer()
            
            // Countdown display
            if countdownPhase == 0 {
                Text("🧘")
                    .font(.system(size: 60))
            } else {
                Text("\(4 - countdownPhase)")
                    .font(.system(size: 80, weight: .light, design: .rounded))
                    .foregroundStyle(.primary)
            }
            
            Spacer()
        }
        .id(countdownPhase)
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Countdown Logic
    
    /// Start countdown sequence
    /// CRITICAL: Schedule Smart Alarm BEFORE workout session (while app is active)
    private func startCountdown() {
        // 1. Schedule Smart Alarm FIRST (before workout session, while app is definitely active)
        let countdownDuration: TimeInterval = 4.0  // 4 seconds countdown
        let endDate = Date().addingTimeInterval(countdownDuration + workoutManager.selectedDuration)
        alarmController.scheduleAlarm(at: endDate)
        
        // 2. Start workout session (activates Extended Runtime Session)
        Task { @MainActor in
            do {
                try await workoutManager.startWorkout()
                // 3. Start countdown timer after workout session is active
                startCountdownTimer()
            } catch {
                print("❌ Failed to start workout session: \(error.localizedDescription)")
                // Start countdown anyway, but it may not work when screen locked
                startCountdownTimer()
            }
        }
    }
    
    /// Start countdown timer
    private func startCountdownTimer() {
        // Reset tick count
        countdownTickCount = 0
        
        // Phase 0: 🧘 emoji
        withAnimation {
            countdownPhase = 0
        }
        
        // Create timer with RunLoop.main and .common mode (works even when screen locked)
        let timer = Timer(timeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.countdownTickCount += 1
                
                if self.countdownTickCount <= 3 {
                    // Phases 1-3: countdown numbers "3", "2", "1"
                    withAnimation {
                        self.countdownPhase = self.countdownTickCount
                    }
                } else {
                    // Phase 4: start meditation
                    self.countdownTimer?.invalidate()
                    self.countdownTimer = nil
                    self.countdownPhase = -1
                    self.navigateToMeditation = true
                }
            }
        }
        
        // Add timer to RunLoop with .common mode (works even when screen locked)
        RunLoop.main.add(timer, forMode: .common)
        countdownTimer = timer
    }
    
    /// Cleanup when returning to main screen
    private func cleanup() {
        // Cancel Smart Alarm if meditation was stopped early
        alarmController.cancelAlarm()
        
        // End workout session if it was started
        if workoutManager.isSessionActive {
            workoutManager.endWorkout()
        }
        
        // Cleanup countdown timer
        countdownTimer?.invalidate()
        countdownTimer = nil
        countdownPhase = -1
        countdownTickCount = 0
    }
}

// MARK: - Preview

#Preview {
    MainView()
        .environmentObject(WorkoutManager())
        .environmentObject(MeditationAlarmController())
}
