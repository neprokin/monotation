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
    var latitude: Double? = nil  // Широта
    var longitude: Double? = nil  // Долгота
    var locationName: String? = nil  // Название места (адрес)
    var note: String? = nil
    var averageHeartRate: Double? = nil  // Средний пульс (только для Watch медитаций)
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
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationName: String? = nil,
        note: String? = nil,
        averageHeartRate: Double? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.pose = pose
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        self.note = note
        self.averageHeartRate = averageHeartRate
        self.createdAt = createdAt
    }
    
    // MARK: - Conversion from Meditation struct
    
    convenience init(from meditation: Meditation) {
        self.init(
            id: meditation.id,
            startTime: meditation.startTime,
            endTime: meditation.endTime,
            pose: meditation.pose.rawValue,
            latitude: meditation.latitude,
            longitude: meditation.longitude,
            locationName: meditation.locationName,
            note: meditation.note,
            averageHeartRate: meditation.averageHeartRate,
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
            latitude: latitude,
            longitude: longitude,
            locationName: locationName,
            note: note,
            averageHeartRate: averageHeartRate,
            createdAt: createdAt
        )
    }
}
