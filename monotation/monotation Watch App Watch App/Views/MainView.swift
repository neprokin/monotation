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
    @EnvironmentObject var runtimeManager: ExtendedRuntimeManager  // NEW: получаем из App
    @State private var showSettings = false
    @State private var countdownPhase: Int = -1 // -1 = idle, 0-3 = countdown
    @State private var navigateToMeditation = false
    @State private var countdownTimer: Timer?  // NEW: Timer для countdown
    
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
                        // runtimeManager уже доступен через environmentObject
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
        
        // Start extended runtime session ASYNCHRONOUSLY (don't block main thread!)
        // This ensures background operation even if user locks screen during countdown
        DispatchQueue.global(qos: .userInitiated).async {
            Task { @MainActor in
                self.runtimeManager.start()
            }
        }
        print("📱 [MainView] Requested extended runtime session (async)")
        
        // Phase 0: 🧘 emoji
        withAnimation {
            countdownPhase = 0
        }
        print("⏱️ [MainView] Countdown phase 0 (emoji)")
        
        // Use Timer with RunLoop.main and .common mode
        // This ensures Timer works even when screen is locked
        var tickCount = 0
        let timer = Timer(timeInterval: 1.0, repeats: true) { timer in
            tickCount += 1
            
            DispatchQueue.main.async {
                print("⏱️ [MainView] Countdown tick \(tickCount)")
                
                if tickCount <= 3 {
                    // Phases 1-3: countdown numbers "3", "2", "1"
                    withAnimation {
                        self.countdownPhase = tickCount
                    }
                } else {
                    // Phase 4: start meditation
                    timer.invalidate()
                    self.countdownTimer = nil
                    self.countdownPhase = -1
                    self.navigateToMeditation = true
                    print("✅ [MainView] Countdown completed - starting meditation")
                }
            }
        }
        
        // Add Timer to RunLoop with .common mode (works even when screen locked)
        RunLoop.main.add(timer, forMode: .common)
        countdownTimer = timer
    }
}

// MARK: - Preview
#Preview {
    MainView()
        .environmentObject(WorkoutManager())
        .environmentObject(ExtendedRuntimeManager())
}

