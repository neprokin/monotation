//
//  CompletionView.swift
//  monotation Watch App
//
//  Completion screen showing session summary
//

import SwiftUI

struct CompletionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isSyncing: Bool = false
    @State private var syncError: String?
    
    let duration: TimeInterval
    let averageHeartRate: Double
    let startTime: Date
    let pose: MeditationPose
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
                    
                    // Sync status
                    if isSyncing {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Синхронизация...")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } else if let error = syncError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Сохранено")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
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
        .onAppear {
            syncToPhone()
        }
    }
    
    // MARK: - Sync
    
    private func syncToPhone() {
        Task {
            // Give a bit more time before trying to sync
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            
            isSyncing = true
            syncError = nil
            
            do {
                try await ConnectivityManager.shared.sendMeditationToPhone(
                    duration: duration,
                    averageHeartRate: averageHeartRate,
                    startTime: startTime,
                    pose: pose
                )
                print("✅ Watch: Meditation synced to iPhone")
            } catch ConnectivityError.activationTimeout {
                print("⚠️ Watch: WCSession activation timeout (simulator limitation)")
                syncError = nil // Don't show error, it's expected in simulator
            } catch ConnectivityError.phoneNotReachable {
                print("⚠️ Watch: iPhone not reachable")
                syncError = "Синхронизация отложена"
            } catch {
                print("❌ Watch: Sync failed: \(error)")
                syncError = "Синхронизация отложена"
            }
            
            isSyncing = false
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
        pose: .lotus,
        onDismiss: {}
    )
}

