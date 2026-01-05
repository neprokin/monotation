//
//  DurationSelectionView.swift
//  monotation Watch App
//
//  Duration selection screen (like Workout app)
//

import SwiftUI

struct DurationSelectionView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var selectedDuration: TimeInterval = 300 // Default 5 min
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(DurationOption.allCases) { option in
                    NavigationLink {
                        ActiveMeditationView(duration: option.duration)
                    } label: {
                        HStack {
                            Image(systemName: "moon.stars.fill")
                                .font(.title3)
                                .foregroundStyle(.primary)
                            
                            Text(option.title)
                                .font(.headline)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("monotation")
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
    DurationSelectionView()
        .environmentObject(WorkoutManager())
}

