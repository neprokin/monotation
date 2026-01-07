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
    @State private var countdownTickCount: Int = 0  // NEW: Track countdown ticks
    
    var body: some View {
        NavigationStack {
            if countdownPhase >= 0 {
                // Countdown screen
                countdownView
                    .navigationBarHidden(true)
                    .onAppear {
                        Logger.shared.info("👁️ COUNTDOWN VIEW APPEARED - countdownPhase=\(countdownPhase)")
                    }
                    .onChange(of: countdownPhase) { oldValue, newValue in
                        Logger.shared.info("🔄 COUNTDOWN PHASE CHANGED: \(oldValue) → \(newValue)")
                    }
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
                    Logger.shared.debug("🔄 navigateToMeditation changed: isPresented=\(isPresented)")
                    // Остановить сессию когда возвращаемся на главный экран
                    if !isPresented {
                        Logger.shared.info("🛑 Returning to main screen - cleaning up")
                        runtimeManager.stop()
                        countdownTimer?.invalidate()
                        countdownTimer = nil
                        countdownPhase = -1
                        countdownTickCount = 0
                        Logger.shared.info("✅ Cleanup complete")
                    }
                }
                .onDisappear {
                    Logger.shared.info("👋 MAIN VIEW DISAPPEARED - cleaning up timer")
                    // Cleanup timer if view disappears
                    countdownTimer?.invalidate()
                    countdownTimer = nil
                    countdownTickCount = 0
                    Logger.shared.info("✅ Timer cleanup complete")
                }
                .onAppear {
                    Logger.shared.info("👁️ MAIN VIEW APPEARED")
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
        Logger.shared.info("🎬 COUNTDOWN START - Function called")
        Logger.shared.debug("Current state: countdownPhase=\(countdownPhase), countdownTickCount=\(countdownTickCount)")
        
        // Start extended runtime session ASYNCHRONOUSLY (don't block main thread!)
        // This ensures background operation even if user locks screen during countdown
        Task { @MainActor in
            Logger.shared.debug("🚀 Starting ExtendedRuntimeSession async...")
        }
        DispatchQueue.global(qos: .userInitiated).async {
            Task { @MainActor in
                Logger.shared.debug("📱 Inside global queue async block")
                Logger.shared.debug("📱 Inside Task @MainActor block")
                self.runtimeManager.start()
                Logger.shared.debug("📱 runtimeManager.start() called")
            }
        }
        Logger.shared.info("📱 ExtendedRuntimeSession start requested (async)")
        
        // Reset tick count
        Logger.shared.debug("🔄 Resetting countdownTickCount from \(countdownTickCount) to 0")
        countdownTickCount = 0
        Logger.shared.debug("✅ countdownTickCount reset to \(countdownTickCount)")
        
        // Phase 0: 🧘 emoji
        Logger.shared.debug("🎨 Setting countdownPhase to 0 (emoji) with animation")
        withAnimation {
            countdownPhase = 0
        }
        Logger.shared.info("⏱️ COUNTDOWN PHASE 0 SET - countdownPhase=\(countdownPhase)")
        
        // Use Timer with RunLoop.main and .common mode
        // This ensures Timer works even when screen is locked
        Task { @MainActor in
            Logger.shared.debug("⏰ Creating Timer with interval 1.0s, repeats=true")
        }
        let timer = Timer(timeInterval: 1.0, repeats: true) { timer in
            // Timer closure runs on background thread, need Task for MainActor
            // Note: RunLoop.current cannot be accessed from async context
            let currentMode = RunLoop.current.currentMode?.rawValue ?? "nil"
            Task { @MainActor in
                Logger.shared.debug("🔔 TIMER CLOSURE FIRED - This is INSIDE Timer closure")
                Logger.shared.debug("Current RunLoop mode: \(currentMode)")
            }
            
            DispatchQueue.main.async {
                Task { @MainActor in
                    Logger.shared.debug("📬 DISPATCHQUEUE.MAIN.ASYNC BLOCK STARTED")
                    Logger.shared.debug("Before increment: countdownTickCount=\(self.countdownTickCount)")
                }
                
                self.countdownTickCount += 1
                
                Task { @MainActor in
                    Logger.shared.info("⏱️ COUNTDOWN TICK \(self.countdownTickCount) - countdownTickCount incremented")
                    Logger.shared.debug("After increment: countdownTickCount=\(self.countdownTickCount), countdownPhase=\(self.countdownPhase)")
                }
                
                if self.countdownTickCount <= 3 {
                    Task { @MainActor in
                        Logger.shared.debug("✅ Tick \(self.countdownTickCount) <= 3, updating phase")
                        Logger.shared.debug("🎨 Setting countdownPhase to \(self.countdownTickCount) with animation")
                    }
                    // Phases 1-3: countdown numbers "3", "2", "1"
                    withAnimation {
                        self.countdownPhase = self.countdownTickCount
                    }
                    Task { @MainActor in
                        Logger.shared.info("✅ COUNTDOWN PHASE \(self.countdownTickCount) SET - countdownPhase=\(self.countdownPhase)")
                    }
                } else {
                    Task { @MainActor in
                        Logger.shared.info("✅ COUNTDOWN COMPLETED - Tick \(self.countdownTickCount) > 3")
                        Logger.shared.debug("🛑 Invalidating timer")
                    }
                    // Phase 4: start meditation
                    timer.invalidate()
                    self.countdownTimer = nil
                    self.countdownPhase = -1
                    Task { @MainActor in
                        Logger.shared.debug("🚀 Setting navigateToMeditation = true")
                    }
                    self.navigateToMeditation = true
                    Task { @MainActor in
                        Logger.shared.info("✅ COUNTDOWN COMPLETED - Starting meditation")
                    }
                }
                
                Task { @MainActor in
                    Logger.shared.debug("📬 DISPATCHQUEUE.MAIN.ASYNC BLOCK FINISHED")
                }
            }
            
            Task { @MainActor in
                Logger.shared.debug("🔔 TIMER CLOSURE FINISHED")
            }
        }
        
        Task { @MainActor in
            Logger.shared.debug("✅ Timer created: \(timer)")
            Logger.shared.debug("📋 RunLoop.main state check before add")
            Logger.shared.debug("RunLoop.main.currentMode: \(RunLoop.main.currentMode?.rawValue ?? "nil")")
        }
        
        // Add Timer to RunLoop with .common mode (works even when screen locked)
        Task { @MainActor in
            Logger.shared.debug("➕ Adding Timer to RunLoop.main with mode .common")
        }
        RunLoop.main.add(timer, forMode: .common)
        
        Task { @MainActor in
            Logger.shared.debug("✅ Timer added to RunLoop")
            Logger.shared.debug("📋 RunLoop.main.currentMode after add: \(RunLoop.main.currentMode?.rawValue ?? "nil")")
        }
        
        countdownTimer = timer
        Logger.shared.info("✅ COUNTDOWN TIMER SETUP COMPLETE - Timer stored in countdownTimer")
        Logger.shared.debug("countdownTimer is nil: \(countdownTimer == nil)")
    }
}

// MARK: - Preview
#Preview {
    MainView()
        .environmentObject(WorkoutManager())
        .environmentObject(ExtendedRuntimeManager())
}

