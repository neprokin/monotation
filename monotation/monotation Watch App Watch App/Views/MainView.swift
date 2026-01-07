//
//  MainView.swift
//  monotation Watch App
//
//  Main screen with emoji, title, and play button (like Apple Workout)
//

import SwiftUI
import WatchKit
import Combine

struct MainView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @StateObject private var runtimeManager = ExtendedRuntimeManager()  // NEW: управляем фоновой сессией
    @State private var showSettings = false
    @State private var countdownPhase: Int = -1 // -1 = idle, 0-3 = countdown
    @State private var navigateToMeditation = false
    @State private var countdownTimer: Timer? // NEW: Timer for countdown (works in background)
    
    var body: some View {
        NavigationStack {
            if countdownPhase >= 0 {
                // Countdown screen
                countdownView
                    .navigationBarHidden(true)
            } else {
                // Main screen (like Apple Workout)
                VStack(spacing: 0) {
                    // Content area
                    VStack(spacing: 4) {
                        Spacer()
                        
                        // Emoji icon (smaller)
                        Text("🧘")
                            .font(.system(size: 40))
                        
                        // Title (smaller)
                        Text("Медитация")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(.primary)
                        
                        Spacer()
                    }
                    
                    // Bottom toolbar with Play button
                    VStack(spacing: 4) {
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
                        
                        // Version label
                        Text(AppVersion.versionString)
                            .font(.system(size: 8))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    .padding(.bottom, 4)
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
                        .environmentObject(runtimeManager)  // NEW: передаем менеджер фоновой сессии
                }
                .onChange(of: navigateToMeditation) { _, isPresented in
                    // Остановить сессию когда возвращаемся на главный экран
                    if !isPresented {
                        runtimeManager.stop()
                        countdownTimer?.invalidate()
                        countdownTimer = nil
                        countdownPhase = -1
                    }
                }
                .onDisappear {
                    // Cleanup timer if view disappears
                    countdownTimer?.invalidate()
                    countdownTimer = nil
                }
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
    
    private func startCountdown() {
        print("🎬 [MainView] Starting countdown sequence")
        
        // Start extended runtime session BEFORE countdown
        // This ensures background operation even if user locks screen during countdown
        runtimeManager.start()
        print("📱 [MainView] Requested extended runtime session")
        
        // Reset countdown
        countdownPhase = 0
        print("⏱️ [MainView] Countdown phase 0 (emoji)")
        
        // Use Timer instead of DispatchQueue.main.asyncAfter
        // Timer continues to work even when screen is locked
        var tickCount = 0
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] timer in
            tickCount += 1
            
            print("⏱️ [MainView] Countdown tick \(tickCount)")
            
            if tickCount <= 3 {
                // Phases 1-3: countdown numbers "3", "2", "1"
                withAnimation {
                    countdownPhase = tickCount
                }
            } else {
                // Phase 4: start meditation
                timer.invalidate()
                countdownTimer = nil
                countdownPhase = -1
                navigateToMeditation = true
                print("✅ [MainView] Countdown completed - starting meditation")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MainView()
        .environmentObject(WorkoutManager())
}

