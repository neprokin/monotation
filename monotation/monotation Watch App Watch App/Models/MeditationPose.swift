//
//  MeditationPose.swift
//  monotation Watch App
//
//  Enum for meditation pose types (shared model)
//

import Foundation

enum MeditationPose: String, Codable, CaseIterable, Identifiable {
    case lotus = "Лотос"
    case halfLotus = "Полулотос"
    case burmese = "Бирманская"
    case seiza = "Сейдза"
    case chair = "На стуле"
    case lying = "Лежа"
    case standing = "Стоя"
    case walking = "Ходьба"
    
    var id: String { rawValue }
    
    /// Localized display name
    var displayName: String {
        self.rawValue
    }
}

