//
//  Date+Extensions.swift
//  monotation
//
//  Date extensions for meditation app
//

import Foundation

extension Date {
    /// Start of day (00:00:00)
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// End of day (23:59:59)
    var endOfDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
            .addingTimeInterval(-1)
    }
    
    /// Relative date string (Today, Yesterday, or formatted date)
    var relativeDateString: String {
        if Calendar.current.isDateInToday(self) {
            return "Сегодня"
        } else if Calendar.current.isDateInYesterday(self) {
            return "Вчера"
        } else {
            return formatted(date: .abbreviated, time: .omitted)
        }
    }
    
    /// Formatted time string (HH:mm)
    var timeString: String {
        formatted(date: .omitted, time: .shortened)
    }
}

