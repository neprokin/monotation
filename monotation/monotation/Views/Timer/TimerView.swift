//
//  TimerView.swift
//  monotation
//
//  Main meditation timer screen
//

import SwiftUI

struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()
    @StateObject private var settings = AppSettings.shared
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var countdownPhase: Int = -1 // -1 = idle, 0 = "На старт!", 1-3 = countdown
    @State private var countdownProgress: Double = 0.0
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Main timer (absolutely centered, never moves)
                    timerDisplay
                        .frame(width: 280, height: 280)
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        )
                    
                    // Controls overlay (below timer, absolutely positioned)
                    VStack {
                        Spacer()
                        
                        ZStack {
                            // Show Play button in idle state
                            if countdownPhase < 0 && !viewModel.isRunning && !viewModel.isPaused && !viewModel.timerState.isWaitingForAcknowledgment {
                                if case .idle = viewModel.timerState {
                                    startButton
                                } else if case .completed = viewModel.timerState {
                                    startButton
                                }
                            }
                            
                            // Show control buttons when timer is running or paused
                            if viewModel.isRunning || viewModel.isPaused {
                                controlButtons
                                    .transition(.opacity)
                            }
                            
                            // Show "Завершить" button when waiting for acknowledgment
                            if viewModel.timerState.isWaitingForAcknowledgment {
                                acknowledgmentButton
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .frame(height: 64)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isRunning)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isPaused)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.timerState.isWaitingForAcknowledgment)
                        .padding(.bottom, 80)
                    }
                    
                    // Version label (bottom right corner)
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(AppVersion.versionString)
                                .font(.caption2)
                                .foregroundColor(.secondary.opacity(0.5))
                                .padding(.trailing, 16)
                                .padding(.bottom, 8)
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(countdownPhase >= 0 || viewModel.isRunning || viewModel.isPaused || viewModel.timerState.isWaitingForAcknowledgment ? .hidden : .visible, for: .navigationBar)
            .toolbar {
                // Settings button (left)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                
                // History button (right)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                }
            }
            .sheet(isPresented: $showHistory) {
                HistoryView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(settings: settings)
            }
            .sheet(
                isPresented: $viewModel.showMeditationForm,
                onDismiss: {
                    // Reset timer after form is dismissed (saved or cancelled)
                    viewModel.resetTimer()
                }
            ) {
                if let session = viewModel.getMeditationSessionInfo() {
                    MeditationFormView(
                        startTime: session.startTime,
                        endTime: session.endTime,
                        defaultPose: settings.defaultPose
                    )
                }
            }
            .onAppear {
                // Set default duration from settings when view appears
                if case .idle = viewModel.timerState {
                    viewModel.selectDuration(settings.defaultDuration)
                }
            }
            .onChange(of: settings.defaultDuration) { _, newDuration in
                // Update timer when default duration changes in settings
                if case .idle = viewModel.timerState {
                    viewModel.selectDuration(newDuration)
                }
            }
            .onChange(of: viewModel.timerState) { _, newState in
                // Reset countdown when returning to idle
                if case .idle = newState {
                    countdownPhase = -1
                    countdownProgress = 0.0
                }
            }
        }
    }
    
    // MARK: - Timer Display
    
    private var timerDisplay: some View {
        // Circular progress (280x280, absolutely positioned)
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 20)
            
            // Progress circle (monochrome - primary color)
            Circle()
                .trim(from: 0, to: {
                    // In completion state - 100%
                    if viewModel.timerState.isWaitingForAcknowledgment {
                        return 1.0
                    } else if countdownPhase >= 0 {
                        return countdownProgress
                    } else {
                        return viewModel.progress
                    }
                }())
                .stroke(
                    Color.primary,
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(countdownPhase >= 0 ? .easeInOut(duration: 0.3) : .linear(duration: 0.1), 
                          value: countdownPhase >= 0 ? countdownProgress : viewModel.progress)
            
            // Text: countdown, timer, or completion checkmark (unified typography)
            Group {
                if viewModel.timerState.isWaitingForAcknowledgment {
                    // Show checkmark on completion
                    Text("✓")
                        .font(.system(size: 80, weight: .light, design: .rounded))
                        .foregroundStyle(.primary)
                } else if countdownPhase == 0 {
                    Text("🧘")
                        .font(.system(size: 60, weight: .light, design: .rounded))
                } else if countdownPhase > 0 {
                    Text("\(4 - countdownPhase)")
                        .font(.system(size: 60, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                } else {
                    Text(viewModel.formattedTime)
                        .font(.system(size: 60, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                }
            }
            .id("\(countdownPhase)-\(viewModel.formattedTime)-\(viewModel.timerState.isWaitingForAcknowledgment)")
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    // MARK: - Start Button (80% of timer width = 224pt)
    
    private var startButton: some View {
        Button {
            startCountdown()
        } label: {
            Image(systemName: "play.fill")
                .font(.system(size: 32))
                .foregroundStyle(Color(uiColor: .systemBackground))
                .frame(width: 224, height: 64)
                .background(Color.primary)
                .clipShape(Capsule())
        }
    }
    
    // MARK: - Countdown Logic
    
    private func startCountdown() {
        // Phase 0: "На старт!" (0 seconds, no fill)
        withAnimation {
            countdownPhase = 0
            countdownProgress = 0.0
        }
        
        // Phase 1: "3" (1 second, 33% fill)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                countdownPhase = 1
                countdownProgress = 0.33
            }
        }
        
        // Phase 2: "2" (2 seconds, 66% fill)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                countdownPhase = 2
                countdownProgress = 0.66
            }
        }
        
        // Phase 3: "1" (3 seconds, 100% fill)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                countdownPhase = 3
                countdownProgress = 1.0
            }
        }
        
        // Complete (4 seconds): start timer
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            countdownPhase = -1
            countdownProgress = 0.0
            
            print("⏱️ Starting timer after countdown")
            viewModel.startTimerAfterCountdown()
            
            // Force UI update
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("⏱️ Timer state: \(viewModel.timerState), isRunning: \(viewModel.isRunning)")
            }
        }
    }
    
    // MARK: - Control Buttons (Running/Paused state)
    
    private var controlButtons: some View {
        HStack(spacing: 16) {
            // Play/Pause button
            Button {
                if viewModel.isRunning {
                    viewModel.pauseTimer()
                } else {
                    viewModel.resumeTimer()
                }
            } label: {
                Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(uiColor: .systemBackground))
                    .frame(width: 144, height: 64)
                    .background(Color.primary)
                    .clipShape(Capsule())
            }
            
            // Stop button
            Button {
                viewModel.stopTimer()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.primary)
                    .frame(width: 64, height: 64)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(Circle())
            }
        }
        .frame(width: 224, height: 64) // Fixed width container (same as Play button)
    }
    
    // MARK: - Acknowledgment Button (Completion state)
    
    private var acknowledgmentButton: some View {
        Button {
            viewModel.acknowledgeMeditationCompletion()
        } label: {
            Image(systemName: "stop.fill")
                .font(.system(size: 32))
                .foregroundStyle(Color(uiColor: .systemBackground))
                .frame(width: 224, height: 64)
                .background(Color.primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Duration Options
enum DurationOption: CaseIterable, Identifiable {
    case threeSeconds  // For testing
    case five
    case ten
    case fifteen
    case twenty
    case thirty
    
    var id: String { title }
    
    var title: String {
        switch self {
        case .threeSeconds: return "3 сек"
        case .five: return "5 мин"
        case .ten: return "10 мин"
        case .fifteen: return "15 мин"
        case .twenty: return "20 мин"
        case .thirty: return "30 мин"
        }
    }
    
    var pickerTitle: String {
        switch self {
        case .threeSeconds: return "3 секунды"
        case .five: return "5 минут"
        case .ten: return "10 минут"
        case .fifteen: return "15 минут"
        case .twenty: return "20 минут"
        case .thirty: return "30 минут"
        }
    }
    
    var duration: TimeInterval {
        switch self {
        case .threeSeconds: return 3        // For testing
        case .five: return 300              // 5 * 60
        case .ten: return 600               // 10 * 60
        case .fifteen: return 900           // 15 * 60
        case .twenty: return 1200           // 20 * 60
        case .thirty: return 1800           // 30 * 60
        }
    }
}


// MARK: - Preview
#Preview {
    TimerView()
}

