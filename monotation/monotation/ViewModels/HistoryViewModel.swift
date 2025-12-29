//
//  HistoryViewModel.swift
//  monotation
//
//  History screen logic and data management
//

import Foundation
import Combine
import SwiftUI

@MainActor
class HistoryViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var meditations: [Meditation] = []
    @Published var groupedMeditations: [String: [Meditation]] = [:]
    @Published var sectionKeys: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // MARK: - Initialization
    
    init() {
        loadMeditations()
    }
    
    // MARK: - Load Meditations
    
    func loadMeditations() {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Load from Supabase when service is ready
        // For now, use sample data
        meditations = Meditation.sampleList
        
        groupMeditations()
    }
    
    // MARK: - Group Meditations by Date
    
    private func groupMeditations() {
        groupedMeditations = Dictionary(grouping: meditations) { meditation in
            meditation.dateGrouping
        }
        
        // Sort sections: Today first, then Yesterday, then by date (newest first)
        sectionKeys = groupedMeditations.keys.sorted { key1, key2 in
            if key1 == "Сегодня" { return true }
            if key2 == "Сегодня" { return false }
            if key1 == "Вчера" { return true }
            if key2 == "Вчера" { return false }
            
            // For other dates, sort by the actual date (newest first)
            guard let med1 = groupedMeditations[key1]?.first,
                  let med2 = groupedMeditations[key2]?.first else {
                return key1 > key2
            }
            
            return med1.startTime > med2.startTime
        }
        
        // Sort meditations within each section (newest first)
        for key in sectionKeys {
            groupedMeditations[key]?.sort { $0.startTime > $1.startTime }
        }
    }
    
    // MARK: - Refresh
    
    func refresh() async {
        loadMeditations()
    }
    
    // MARK: - Computed Properties
    
    var isEmpty: Bool {
        meditations.isEmpty
    }
    
    var totalMeditations: Int {
        meditations.count
    }
    
    var totalDuration: TimeInterval {
        meditations.reduce(0) { $0 + $1.duration }
    }
    
    var formattedTotalDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours) ч \(minutes) мин"
        } else {
            return "\(minutes) мин"
        }
    }
}

