//
//  SettingsView.swift
//  monotation
//
//  User settings screen
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss
    @State private var showDocumentPicker = false
    @State private var showSyncStatus = false
    @State private var syncStatusMessage = ""
    
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
                
                // MARK: - Obsidian Integration Section
                Section {
                    Button {
                        showDocumentPicker = true
                    } label: {
                        HStack {
                            Label(
                                settings.obsidianSessionsURL != nil ? "Изменить файл" : "Выбрать файл sessions.md",
                                systemImage: "doc.text"
                            )
                            Spacer()
                            if settings.obsidianSessionsURL != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    
                    if settings.obsidianSessionsURL != nil {
                        Button(role: .destructive) {
                            settings.obsidianSessionsURL = nil
                        } label: {
                            Label("Удалить файл", systemImage: "trash")
                        }
                        
                        Button {
                            checkSyncStatus()
                        } label: {
                            HStack {
                                Label("Проверить статус синхронизации", systemImage: "arrow.clockwise")
                                Spacer()
                                if showSyncStatus {
                                    Text(syncStatusMessage)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Label("Интеграция с Obsidian", systemImage: "doc.text")
                } footer: {
                    VStack(alignment: .leading, spacing: 6) {
                        if let url = settings.obsidianSessionsURL {
                            Text("Выбранный файл:")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text(url.lastPathComponent)
                                .font(.caption)
                                .fontDesign(.monospaced)
                                .foregroundStyle(.secondary)
                            Text(url.deletingLastPathComponent().path)
                                .font(.caption2)
                                .fontDesign(.monospaced)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        } else {
                            Text("Выбери файл sessions.md из твоего Obsidian vault в iCloud Drive")
                                .font(.caption)
                        }
                    }
                }
                .fileImporter(
                    isPresented: $showDocumentPicker,
                    allowedContentTypes: [.plainText, UTType(filenameExtension: "md")!],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        if let url = urls.first {
                            // Start accessing security-scoped resource for iCloud files
                            _ = url.startAccessingSecurityScopedResource()
                            settings.obsidianSessionsURL = url
                        }
                    case .failure(let error):
                        print("⚠️ SettingsView: Failed to select file: \(error)")
                    }
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
    
    // MARK: - Sync Status Check
    
    private func checkSyncStatus() {
        Task {
            showSyncStatus = true
            do {
                let existingKeys = try await ObsidianService.shared.readExistingMeditations()
                let allMeditations = try await CloudKitService.shared.fetchMeditations()
                let syncedCount = allMeditations.filter { meditation in
                    existingKeys.contains(meditation.obsidianKey)
                }.count
                
                syncStatusMessage = "Синхронизировано: \(syncedCount) из \(allMeditations.count)"
            } catch {
                syncStatusMessage = "Ошибка: \(error.localizedDescription)"
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

