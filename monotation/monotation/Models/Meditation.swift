//
//  Meditation.swift
//  monotation
//
//  Main data model for meditation session
//

import Foundation

struct Meditation: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: String
    let startTime: Date
    let endTime: Date
    let pose: MeditationPose
    let latitude: Double? // Широта
    let longitude: Double? // Долгота
    let locationName: String? // Название места (адрес)
    let note: String?
    let averageHeartRate: Double? // Средний пульс (только для Watch медитаций)
    let createdAt: Date
    
    /// Computed duration in seconds
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    /// Formatted duration for display (e.g., "20 мин")
    var formattedDuration: String {
        duration.asMinutes
    }
    
    /// Formatted start time for display (e.g., "15:30")
    var formattedStartTime: String {
        startTime.timeString
    }
    
    /// Date grouping string for history list (e.g., "Сегодня", "Вчера", "28 декабря")
    var dateGrouping: String {
        startTime.relativeDateString
    }
    
    /// Markdown representation for future AI analysis
    /// Format matches the app's MeditationDetailView format
    var asMarkdown: String {
        var markdown = "# Медитация \(startTime.formatted())\n\n"
        markdown += "- **Начало**: \(startTime.formatted(date: .abbreviated, time: .shortened))\n"
        markdown += "- **Окончание**: \(endTime.formatted(date: .abbreviated, time: .shortened))\n"
        markdown += "- **Длительность**: \(formattedDuration)\n"
        markdown += "- **Поза**: \(pose.displayName)\n"
        if let locationName = locationName, !locationName.isEmpty {
            markdown += "- **Место**: \(locationName)\n"
        }
        
        if let heartRate = averageHeartRate, heartRate > 0 {
            markdown += "- **Пульс**: \(Int(heartRate)) уд/мин\n"
        }
        
        markdown += "\n"
        
        if let note = note, !note.isEmpty {
            markdown += "## Заметка\n\n"
            markdown += note
            markdown += "\n"
        }
        
        return markdown
    }
    
    /// Key for deduplication in Obsidian (format: "YYYY-MM-DD HH:MM")
    var obsidianKey: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: startTime)
        
        guard let year = components.year,
              let month = components.month,
              let day = components.day,
              let hour = components.hour,
              let minute = components.minute else {
            return UUID().uuidString // Fallback
        }
        
        return String(format: "%04d-%02d-%02d %02d:%02d", year, month, day, hour, minute)
    }
    
    /// Format for Obsidian sessions.md file
    /// Format matches the app's MeditationDetailView format
    var obsidianFormat: String {
        let time = formattedStartTime
        let duration = formattedDuration
        let poseName = pose.displayName
        
        var result = "- **\(time)** — \(duration)\n"
        result += "- **Поза**: \(poseName)\n"
        
        if let locationName = locationName, !locationName.isEmpty {
            result += "- **Место**: \(locationName)\n"
        }
        
        // Add heart rate if available
        if let heartRate = averageHeartRate, heartRate > 0 {
            result += "- **Пульс**: \(Int(heartRate)) уд/мин\n"
        }
        
        // Add note if exists
        if let note = note, !note.isEmpty {
            let noteLines = note.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            
            if !noteLines.isEmpty {
                result += "- **Заметки**:\n"
                result += noteLines.map { "  - \($0)" }.joined(separator: "\n")
            }
        }
        
        return result
    }
}

// MARK: - Sample Data for Previews
extension Meditation {
    /// Single sample meditation for previews
    static let sampleData = Meditation(
        id: UUID(),
        userId: "sample-user-id",
        startTime: Date().addingTimeInterval(-1200), // 20 min ago
        endTime: Date(),
        pose: .burmese,
        latitude: 55.7558,
        longitude: 37.6173,
        locationName: "Москва, Россия",
        note: "Хорошая концентрация на дыхании",
        averageHeartRate: nil,
        createdAt: Date()
    )
    
    /// Array of sample meditations for list previews
    static let sampleList: [Meditation] = [
        Meditation(
            id: UUID(),
            userId: "sample",
            startTime: Date().addingTimeInterval(-3600), // 1 hour ago
            endTime: Date().addingTimeInterval(-3000),
            pose: .burmese,
            latitude: 55.7558,
            longitude: 37.6173,
            locationName: "Москва, ул. Тверская, 1",
            note: "Утренняя медитация",
            averageHeartRate: nil,
            createdAt: Date()
        ),
        Meditation(
            id: UUID(),
            userId: "sample",
            startTime: Date().addingTimeInterval(-90000), // yesterday
            endTime: Date().addingTimeInterval(-89100),
            pose: .walking,
            latitude: 55.7520,
            longitude: 37.6156,
            locationName: "Парк Горького, Москва",
            note: nil,
            averageHeartRate: 65.0,
            createdAt: Date().addingTimeInterval(-90000)
        ),
        Meditation(
            id: UUID(),
            userId: "sample",
            startTime: Date().addingTimeInterval(-180000), // 2 days ago
            endTime: Date().addingTimeInterval(-178200),
            pose: .burmese,
            latitude: 55.7512,
            longitude: 37.6184,
            locationName: "Офис, Москва",
            note: "Медитация во время обеда",
            averageHeartRate: nil,
            createdAt: Date().addingTimeInterval(-180000)
        )
    ]
}

// MARK: - Markdown Export
extension Meditation {
    /// Export array of meditations as single markdown document
    static func exportAsMarkdown(_ meditations: [Meditation]) -> String {
        var markdown = "# История медитаций\n\n"
        
        for meditation in meditations {
            markdown += meditation.asMarkdown
            markdown += "\n---\n\n"
        }
        
        return markdown
    }
}

