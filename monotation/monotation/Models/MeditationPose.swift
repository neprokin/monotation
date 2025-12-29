//
//  MeditationPose.swift
//  monotation
//
//  Enum for meditation pose types
//

import Foundation

enum MeditationPose: String, Codable, CaseIterable, Identifiable {
    case burmese = "Бирманская поза"
    case walking = "Ходьба"
    
    var id: String { rawValue }
    
    /// SF Symbol icon name for UI
    var iconName: String {
        switch self {
        case .burmese: return "figure.mind.and.body"
        case .walking: return "figure.walk"
        }
    }
    
    /// Localized display name
    var displayName: String {
        self.rawValue
    }
}

