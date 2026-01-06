//
//  WatchSettingsView.swift
//  monotation Watch App
//
//  Settings for Apple Watch: duration and pose
//

import SwiftUI

struct WatchSettingsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            // Duration section
            Section {
                Picker("Длительность", selection: $workoutManager.selectedDuration) {
                    ForEach(WatchDurationOption.allCases) { option in
                        Text(option.title).tag(option.duration)
                    }
                }
            } header: {
                Text("Длительность")
            }
            
            // Pose section
            Section {
                Picker("Поза", selection: $workoutManager.selectedPose) {
                    ForEach(MeditationPose.allCases) { pose in
                        Text(pose.displayName).tag(pose)
                    }
                }
            } header: {
                Text("Поза по умолчанию")
            }
        }
        .navigationTitle("Настройки")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Duration Options for Watch
enum WatchDurationOption: CaseIterable, Identifiable {
    case threeSeconds  // For testing
    case five
    case ten
    case fifteen
    case twenty
    case thirty
    
    var id: TimeInterval { duration }
    
    var title: String {
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
        case .threeSeconds: return 3
        case .five: return 300
        case .ten: return 600
        case .fifteen: return 900
        case .twenty: return 1200
        case .thirty: return 1800
        }
    }
}

// MARK: - Preview
#Preview {
    WatchSettingsView()
        .environmentObject(WorkoutManager())
}

