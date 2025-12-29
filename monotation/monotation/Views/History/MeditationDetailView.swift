//
//  MeditationDetailView.swift
//  monotation
//
//  Detailed view for a single meditation session
//

import SwiftUI

struct MeditationDetailView: View {
    let meditation: Meditation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with icon
                    HStack {
                        Image(systemName: meditation.pose.iconName)
                            .font(.system(size: 48))
                            .foregroundStyle(.primary)
                            .frame(width: 80, height: 80)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(20)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(meditation.pose.displayName)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            HStack(spacing: 4) {
                                Image(systemName: meditation.place.iconName)
                                    .font(.caption)
                                Text(meditation.place.displayName)
                                    .font(.subheadline)
                            }
                            .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 8)
                    
                    Divider()
                    
                    // Session info
                    VStack(alignment: .leading, spacing: 16) {
                        LabeledContent("Начало") {
                            Text(meditation.startTime.formatted(date: .abbreviated, time: .shortened))
                                .foregroundStyle(.secondary)
                        }
                        
                        LabeledContent("Окончание") {
                            Text(meditation.endTime.formatted(date: .abbreviated, time: .shortened))
                                .foregroundStyle(.secondary)
                        }
                        
                        LabeledContent("Длительность") {
                            Text(meditation.formattedDuration)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.body)
                    
                    // Note (if exists)
                    if let note = meditation.note, !note.isEmpty {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Заметка")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text(note)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Медитация")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MeditationDetailView(meditation: Meditation.sample)
}

