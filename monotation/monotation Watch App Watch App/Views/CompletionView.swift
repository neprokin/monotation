//
//  CompletionView.swift
//  monotation Watch App
//
//  Completion screen showing session summary
//

import SwiftUI

struct CompletionView: View {
    @Environment(\.dismiss) private var dismiss
    
    let duration: TimeInterval
    let averageHeartRate: Double
    let startTime: Date
    let onDismiss: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Success icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                
                // Title
                Text("Медитация\nзавершена")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                // Stats
                VStack(spacing: 16) {
                    // Duration
                    StatRow(
                        icon: "clock.fill",
                        label: "Длительность",
                        value: formatDuration(duration)
                    )
                    
                    // Heart rate (if available)
                    if averageHeartRate > 0 {
                        StatRow(
                            icon: "heart.fill",
                            label: "Средний пульс",
                            value: "\(Int(averageHeartRate)) уд/мин"
                        )
                    }
                    
                    // Time
                    StatRow(
                        icon: "calendar",
                        label: "Время",
                        value: formatTime(startTime)
                    )
                }
                .padding(.vertical)
                
                // Done button
                Button {
                    dismiss()
                    onDismiss()
                } label: {
                    Text("Готово")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding()
        }
    }
    
    // MARK: - Helpers
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        if minutes > 0 && seconds > 0 {
            return "\(minutes) мин \(seconds) сек"
        } else if minutes > 0 {
            return "\(minutes) мин"
        } else {
            return "\(seconds) сек"
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Stat Row Component
struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Preview
#Preview {
    CompletionView(
        duration: 300,
        averageHeartRate: 72,
        startTime: Date(),
        onDismiss: {}
    )
}

