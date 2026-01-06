//
//  MainView.swift
//  monotation Watch App
//
//  Main screen with emoji, title, and play button (like Apple Workout)
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var showSettings = false
    @State private var countdownPhase: Int = -1 // -1 = idle, 0-3 = countdown
    @State private var navigateToMeditation = false
    
    var body: some View {
        NavigationStack {
            if countdownPhase >= 0 {
                // Countdown screen
                countdownView
                    .navigationBarHidden(true)
            } else {
                // Main screen
                VStack(spacing: 20) {
                    Spacer()
                    
                    // Emoji icon
                    Text("🧘")
                        .font(.system(size: 60))
                    
                    // Title
                    Text("Медитация")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    // Play button (monochrome)
                    Button {
                        startCountdown()
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                            .frame(width: 80, height: 80)
                            .background(Color.primary)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
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
                .navigationDestination(isPresented: $navigateToMeditation) {
                    ActiveMeditationView()
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
        // Phase 0: 🧘 emoji
        withAnimation {
            countdownPhase = 0
        }
        
        // Phase 1: "3"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                countdownPhase = 1
            }
        }
        
        // Phase 2: "2"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                countdownPhase = 2
            }
        }
        
        // Phase 3: "1"
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                countdownPhase = 3
            }
        }
        
        // Complete: start meditation
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            countdownPhase = -1
            navigateToMeditation = true
        }
    }
}

// MARK: - Preview
#Preview {
    MainView()
        .environmentObject(WorkoutManager())
}

