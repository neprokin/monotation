//
//  MeditationCard.swift
//  monotation
//
//  Card component for displaying meditation in history list
//

import SwiftUI

struct MeditationCard: View {
    let meditation: Meditation
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon (pose)
            Image(systemName: meditation.pose.iconName)
                .font(.title2)
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(12)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Time and duration
                HStack(spacing: 8) {
                    Text(meditation.formattedStartTime)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text(meditation.formattedDuration)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Location - показываем всегда, если есть координаты или адрес
                if (meditation.latitude != nil && meditation.longitude != nil) || 
                   (meditation.locationName != nil && !meditation.locationName!.isEmpty) {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if let locationName = meditation.locationName, !locationName.isEmpty {
                            Text(locationName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        } else if meditation.latitude != nil && meditation.longitude != nil {
                            Text("Координаты: \(String(format: "%.4f", meditation.latitude!)), \(String(format: "%.4f", meditation.longitude!))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview
#Preview {
    List {
        MeditationCard(meditation: Meditation.sampleData)
        MeditationCard(meditation: Meditation.sampleList[1])
        MeditationCard(meditation: Meditation.sampleList[2])
    }
    .listStyle(.insetGrouped)
}

