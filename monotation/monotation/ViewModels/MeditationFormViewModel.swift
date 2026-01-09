//
//  MeditationFormViewModel.swift
//  monotation
//
//  Form validation and saving logic
//

import Foundation
import SwiftUI
import Combine
import SwiftData
import CoreLocation

@MainActor
class MeditationFormViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var selectedPose: MeditationPose
    @Published var locationName: String? = nil
    @Published var editableLocationName: String = ""  // Для редактирования адреса пользователем
    @Published var latitude: Double? = nil
    @Published var longitude: Double? = nil
    @Published var isLocationLoading = false
    @Published var note: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // MARK: - Private Properties
    
    // Use CloudKitService for now, but we could also use ModelContext directly
    private let cloudKitService = CloudKitService.shared
    private let locationService = LocationService.shared
    
    // MARK: - Session Info
    
    let startTime: Date
    let endTime: Date
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    // MARK: - Initialization
    
    init(startTime: Date, endTime: Date, defaultPose: MeditationPose = .lotus) {
        self.startTime = startTime
        self.endTime = endTime
        self.selectedPose = defaultPose
        
        // Request location authorization and get current location
        // Используем Task.detached для асинхронной загрузки без блокировки UI
        Task { @MainActor in
            await requestLocation()
        }
    }
    
    // MARK: - Location
    
    func requestLocation() async {
        // Check authorization
        if locationService.authorizationStatus == .notDetermined {
            locationService.requestAuthorization()
            // Wait a bit for authorization to be granted
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        // Get location if authorized
        guard locationService.authorizationStatus == .authorizedWhenInUse || 
              locationService.authorizationStatus == .authorizedAlways else {
            return
        }
        
        isLocationLoading = true
        defer { isLocationLoading = false }
        
        do {
            let locationResult = try await locationService.getCurrentLocation()
            self.latitude = locationResult.latitude
            self.longitude = locationResult.longitude
            self.locationName = locationResult.address
            // Инициализируем редактируемое поле адресом из геокодирования
            self.editableLocationName = locationResult.address ?? ""
        } catch {
            // Location error is not critical, continue without location
            print("⚠️ Failed to get location: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Validation
    
    var isValid: Bool {
        // Note should not exceed 500 characters
        guard note.count <= 500 else { return false }
        
        return true
    }
    
    var validationError: String? {
        if note.count > 500 {
            return "Заметка слишком длинная (максимум 500 символов)"
        }
        
        return nil
    }
    
    // MARK: - Save Meditation
    
    func saveMeditation() async -> Bool {
        guard isValid else {
            errorMessage = validationError
            showError = true
            return false
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Create meditation object
            let meditation = createMeditation()
            
            // Save to CloudKit
            try await cloudKitService.insertMeditation(meditation)
            
            return true
        } catch {
            errorMessage = "Ошибка сохранения: \(error.localizedDescription)"
            showError = true
            return false
        }
    }
    
    // MARK: - Create Meditation Object
    
    private func createMeditation() -> Meditation {
        let noteText = note.trimmingCharacters(in: .whitespaces)
        
        // Используем отредактированный адрес, если он есть, иначе используем адрес из геокодирования
        let finalLocationName = editableLocationName.trimmingCharacters(in: .whitespaces).isEmpty 
            ? locationName 
            : editableLocationName.trimmingCharacters(in: .whitespaces)
        
        // CloudKit automatically uses iCloud account (no userId needed)
        return Meditation(
            id: UUID(),
            userId: "iCloud", // CloudKit uses iCloud account automatically
            startTime: startTime,
            endTime: endTime,
            pose: selectedPose,
            latitude: latitude,
            longitude: longitude,
            locationName: finalLocationName,
            note: noteText.isEmpty ? nil : noteText,
            averageHeartRate: nil, // iPhone медитации не имеют пульса
            createdAt: Date()
        )
    }
    
    // MARK: - Helper computed properties
    
    var formattedStartTime: String {
        startTime.formatted(date: .abbreviated, time: .shortened)
    }
    
    var formattedEndTime: String {
        endTime.formatted(date: .abbreviated, time: .shortened)
    }
    
    var formattedDuration: String {
        duration.asMinutes
    }
    
    var noteCharacterCount: String {
        "\(note.count)/500"
    }
    
    var isNoteValid: Bool {
        note.count <= 500
    }
}
