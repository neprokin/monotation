//
//  MeditationDetailView.swift
//  monotation
//
//  Detailed view for a single meditation session
//

import SwiftUI
import MapKit

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
                            
                            if let locationName = meditation.locationName, !locationName.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "location.fill")
                                        .font(.caption)
                                    Text(locationName)
                                        .font(.subheadline)
                                        .lineLimit(2)
                                }
                                .foregroundStyle(.secondary)
                            }
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
                        
                        // Heart rate (if available)
                        if let heartRate = meditation.averageHeartRate, heartRate > 0 {
                            LabeledContent("Пульс") {
                                Text("\(Int(heartRate)) уд/мин")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .font(.body)
                    
                    // Location map (if coordinates available)
                    if let latitude = meditation.latitude,
                       let longitude = meditation.longitude {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Место")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            LocationMapView(
                                latitude: latitude,
                                longitude: longitude,
                                locationName: meditation.locationName
                            )
                        }
                    }
                    
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
    MeditationDetailView(meditation: Meditation.sampleList.first!)
}

