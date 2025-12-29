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
    let place: MeditationPlace
    let note: String?
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
    var asMarkdown: String {
        var markdown = "# Медитация \(startTime.formatted())\n\n"
        markdown += "- **Дата**: \(startTime.formatted(date: .long, time: .omitted))\n"
        markdown += "- **Время начала**: \(formattedStartTime)\n"
        markdown += "- **Длительность**: \(formattedDuration)\n"
        markdown += "- **Поза**: \(pose.rawValue)\n"
        markdown += "- **Место**: \(place.displayName)\n\n"
        
        if let note = note, !note.isEmpty {
            markdown += "## Заметка\n\n"
            markdown += note
            markdown += "\n"
        }
        
        return markdown
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
        place: .home,
        note: "Хорошая концентрация на дыхании",
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
            place: .home,
            note: "Утренняя медитация",
            createdAt: Date()
        ),
        Meditation(
            id: UUID(),
            userId: "sample",
            startTime: Date().addingTimeInterval(-90000), // yesterday
            endTime: Date().addingTimeInterval(-89100),
            pose: .walking,
            place: .custom("Парк"),
            note: nil,
            createdAt: Date().addingTimeInterval(-90000)
        ),
        Meditation(
            id: UUID(),
            userId: "sample",
            startTime: Date().addingTimeInterval(-180000), // 2 days ago
            endTime: Date().addingTimeInterval(-178200),
            pose: .burmese,
            place: .work,
            note: "Медитация во время обеда",
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

