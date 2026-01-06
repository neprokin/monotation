//
//  MeditationPose.swift
//  monotation
//
//  Enum for meditation pose types
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
    
    /// SF Symbol icon name for UI
    var iconName: String {
        switch self {
        case .lotus, .halfLotus, .burmese, .seiza:
            return "figure.mind.and.body"
        case .chair:
            return "chair.fill"
        case .lying:
            return "bed.double.fill"
        case .standing:
            return "figure.stand"
        case .walking:
            return "figure.walk"
        }
    }
    
    /// Localized display name
    var displayName: String {
        self.rawValue
    }
}

