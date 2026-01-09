//
//  MeditationModel.swift
//  monotation
//
//  SwiftData model for CloudKit storage
//

import Foundation
import SwiftData

@Model
final class MeditationModel {
    // Note: CloudKit doesn't support @Attribute(.unique), so we'll handle uniqueness in code
    // All properties must have default values for CloudKit compatibility
    var id: UUID = UUID()
    var startTime: Date = Date()
    var endTime: Date = Date()
    var pose: String = MeditationPose.burmese.rawValue  // MeditationPose.rawValue
    var place: String = MeditationPlace.home.storedValue  // MeditationPlace.storedValue
    var note: String? = nil
    var createdAt: Date = Date()
    
    // Computed properties (не сохраняются в CloudKit)
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date,
        pose: String,
        place: String,
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.pose = pose
        self.place = place
        self.note = note
        self.createdAt = createdAt
    }
    
    // MARK: - Conversion from Meditation struct
    
    convenience init(from meditation: Meditation) {
        self.init(
            id: meditation.id,
            startTime: meditation.startTime,
            endTime: meditation.endTime,
            pose: meditation.pose.rawValue,
            place: meditation.place.storedValue,
            note: meditation.note,
            createdAt: meditation.createdAt
        )
    }
    
    // MARK: - Conversion to Meditation struct
    
    func toMeditation() -> Meditation {
        Meditation(
            id: id,
            userId: "iCloud", // CloudKit использует iCloud аккаунт автоматически
            startTime: startTime,
            endTime: endTime,
            pose: MeditationPose(rawValue: pose) ?? .burmese,
            place: MeditationPlace.from(place),
            note: note,
            createdAt: createdAt
        )
    }
}
