//
//  SettingsView.swift
//  monotation
//
//  User settings screen
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Duration Section
                Section {
                    Picker("Длительность", selection: $settings.defaultDuration) {
                        ForEach(DurationOption.settingsOptions, id: \.duration) { option in
                            Text(option.title).tag(option.duration)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Label("Длительность по умолчанию", systemImage: "clock")
                }
                
                // MARK: - Pose Section
                Section {
                    Picker("Поза", selection: $settings.defaultPose) {
                        ForEach(MeditationPose.allCases) { pose in
                            Label(pose.displayName, systemImage: pose.iconName)
                                .tag(pose)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Label("Поза по умолчанию", systemImage: "figure.mind.and.body")
                } footer: {
                    Text("Можно изменить при завершении медитации")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Duration Options Extension
extension DurationOption {
    /// Options for settings (including test duration)
    static let settingsOptions: [DurationOption] = [
        .threeSeconds,
        .five,
        .ten,
        .fifteen,
        .twenty,
        .thirty
    ]
}

// MARK: - Preview
#Preview {
    SettingsView(settings: AppSettings.shared)
}

