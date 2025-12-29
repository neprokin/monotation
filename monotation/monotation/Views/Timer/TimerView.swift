//
//  TimerView.swift
//  monotation
//
//  Main meditation timer screen
//

import SwiftUI

struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()
    @State private var showHistory = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()
                
                // Timer display
                timerDisplay
                
                Spacer()
                
                // Controls
                if case .idle = viewModel.timerState {
                    durationSelector
                    startButton
                } else if viewModel.isRunning || viewModel.isPaused {
                    controlButtons
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("monotation")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                }
            }
            .sheet(isPresented: $showHistory) {
                Text("History (coming soon)")
            }
            .sheet(isPresented: $viewModel.showMeditationForm) {
                if let session = viewModel.getMeditationSessionInfo() {
                    MeditationFormView(
                        startTime: session.startTime,
                        endTime: session.endTime
                    )
                }
            }
        }
    }
    
    // MARK: - Timer Display
    
    private var timerDisplay: some View {
        VStack(spacing: 16) {
            // Circular progress
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 280, height: 280)
                
                // Progress circle (monochrome - dark gray)
                Circle()
                    .trim(from: 0, to: viewModel.progress)
                    .stroke(
                        Color.primary,
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 280, height: 280)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: viewModel.progress)
                
                // Time text
                Text(viewModel.formattedTime)
                    .font(.system(size: 60, weight: .light, design: .rounded))
                    .monospacedDigit()
            }
        }
    }
    
    // MARK: - Duration Selector
    
    private var durationSelector: some View {
        VStack(spacing: 12) {
            Text("Выберите длительность")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DurationOption.allCases) { option in
                        DurationButton(
                            title: option.title,
                            isSelected: viewModel.selectedDuration == option.duration,
                            action: {
                                viewModel.selectDuration(option.duration)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Control Buttons
    
    private var startButton: some View {
        Button {
            viewModel.startTimer()
        } label: {
            Text("Начать")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color(uiColor: .systemBackground))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.primary)
                .cornerRadius(16)
        }
        .padding(.horizontal)
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
                    .font(.title2)
                    .foregroundStyle(Color(uiColor: .systemBackground))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.primary)
                    .cornerRadius(16)
            }
            
            // Stop button
            Button {
                viewModel.stopTimer()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: 56, height: 56)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(16)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Duration Button Component
struct DurationButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title3)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Color(uiColor: .systemBackground) : .primary)
                .frame(width: 80, height: 80)
                .background(isSelected ? Color.primary : Color(uiColor: .secondarySystemBackground))
                .cornerRadius(16)
        }
    }
}

// MARK: - Duration Options
enum DurationOption: CaseIterable, Identifiable {
    case five
    case ten
    case fifteen
    case twenty
    case thirty
    
    var id: String { title }
    
    var title: String {
        switch self {
        case .five: return "5 мин"
        case .ten: return "10 мин"
        case .fifteen: return "15 мин"
        case .twenty: return "20 мин"
        case .thirty: return "30 мин"
        }
    }
    
    var duration: TimeInterval {
        switch self {
        case .five: return 300      // 5 * 60
        case .ten: return 600       // 10 * 60
        case .fifteen: return 900   // 15 * 60
        case .twenty: return 1200   // 20 * 60
        case .thirty: return 1800   // 30 * 60
        }
    }
}

// MARK: - Placeholder for MeditationFormView
struct MeditationFormView: View {
    let startTime: Date
    let endTime: Date
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Meditation Form")
                    .font(.title)
                Text("Start: \(startTime.formatted())")
                Text("End: \(endTime.formatted())")
                Text("(Coming soon)")
            }
            .navigationTitle("Сохранить медитацию")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview
#Preview {
    TimerView()
}

