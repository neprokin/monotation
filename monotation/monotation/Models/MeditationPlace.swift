//
//  MeditationPlace.swift
//  monotation
//
//  Enum for meditation location with custom option support
//

import Foundation

enum MeditationPlace: Codable, Equatable, Hashable {
    case home
    case work
    case custom(String)
    
    /// Localized display name for UI
    var displayName: String {
        switch self {
        case .home: return "Дом"
        case .work: return "Работа"
        case .custom(let name): return name
        }
    }
    
    /// SF Symbol icon name for UI
    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .work: return "building.2.fill"
        case .custom: return "location.fill"
        }
    }
    
    /// String value for database storage
    var storedValue: String {
        switch self {
        case .home: return "home"
        case .work: return "work"
        case .custom(let name): return name
        }
    }
    
    /// Create from database string value
    static func from(_ string: String) -> MeditationPlace {
        switch string {
        case "home": return .home
        case "work": return .work
        default: return .custom(string)
        }
    }
}

// MARK: - Codable Implementation
extension MeditationPlace {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self = MeditationPlace.from(string)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(storedValue)
    }
}

// MARK: - Predefined places for picker
extension MeditationPlace {
    static let predefined: [MeditationPlace] = [.home, .work]
}

