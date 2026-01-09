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
    
    // MARK: - Private Properties
    
    private let cloudKitService = CloudKitService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        loadMeditations()
        setupNotificationObserver()
    }
    
    // MARK: - Notification Observer
    
    private func setupNotificationObserver() {
        NotificationCenter.default
            .publisher(for: .meditationAdded)
            .sink { [weak self] _ in
                print("📱 HistoryViewModel: Meditation added, refreshing...")
                self?.loadMeditations()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Load Meditations
    
    func loadMeditations() {
        Task {
            await loadMeditationsAsync()
        }
    }
    
    private func loadMeditationsAsync() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // CloudKit automatically filters by iCloud account
            meditations = try await cloudKitService.fetchMeditations()
            
            groupMeditations()
        } catch {
            print("❌ HistoryViewModel.loadMeditations error: \(error)")
            errorMessage = "Ошибка загрузки медитаций: \(error.localizedDescription)"
            showError = true
            // Fallback to empty array on error (CloudKit will sync automatically)
            meditations = []
            groupMeditations()
        }
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
        await loadMeditationsAsync()
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
