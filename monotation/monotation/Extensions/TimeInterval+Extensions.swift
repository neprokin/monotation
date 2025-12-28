//
//  TimeInterval+Extensions.swift
//  monotation
//
//  TimeInterval extensions for meditation durations
//

import Foundation

extension TimeInterval {
    /// Formatted as "MM:SS" (e.g., "05:30")
    var asMinutesSeconds: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Formatted as "X мин" (e.g., "20 мин")
    var asMinutes: String {
        let minutes = Int(self / 60)
        return "\(minutes) мин"
    }
    
    /// Formatted as "X ч Y мин" for longer durations
    var asHoursMinutes: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        
        if hours > 0 {
            return "\(hours) ч \(minutes) мин"
        } else {
            return "\(minutes) мин"
        }
    }
}

