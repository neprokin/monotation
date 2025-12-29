//
//  MeditationFormViewModel.swift
//  monotation
//
//  Form validation and saving logic
//

import Foundation
import SwiftUI
import Combine

@MainActor
class MeditationFormViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var selectedPose: MeditationPose = .burmese
    @Published var selectedPlace: MeditationPlace = .home
    @Published var customPlace: String = ""
    @Published var note: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // MARK: - Session Info
    
    let startTime: Date
    let endTime: Date
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    // MARK: - Initialization
    
    init(startTime: Date, endTime: Date) {
        self.startTime = startTime
        self.endTime = endTime
    }
    
    // MARK: - Validation
    
    var isValid: Bool {
        // Note should not exceed 500 characters
        guard note.count <= 500 else { return false }
        
        // If custom place is selected, it should not be empty
        if case .custom = selectedPlace, customPlace.trimmingCharacters(in: .whitespaces).isEmpty {
            return false
        }
        
        return true
    }
    
    var validationError: String? {
        if note.count > 500 {
            return "Заметка слишком длинная (максимум 500 символов)"
        }
        
        if case .custom = selectedPlace, customPlace.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Укажите место"
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
            
            // TODO: Save to Supabase when service is ready
            // For now, just simulate success
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
            
            print("✅ Meditation saved:", meditation.asMarkdown)
            
            return true
        } catch {
            errorMessage = "Ошибка сохранения: \(error.localizedDescription)"
            showError = true
            return false
        }
    }
    
    // MARK: - Create Meditation Object
    
    private func createMeditation() -> Meditation {
        let actualPlace: MeditationPlace
        if case .custom = selectedPlace {
            actualPlace = .custom(customPlace.trimmingCharacters(in: .whitespaces))
        } else {
            actualPlace = selectedPlace
        }
        
        let noteText = note.trimmingCharacters(in: .whitespaces)
        
        return Meditation(
            id: UUID(),
            userId: "temp-user-id", // TODO: Replace with actual user ID from auth
            startTime: startTime,
            endTime: endTime,
            pose: selectedPose,
            place: actualPlace,
            note: noteText.isEmpty ? nil : noteText,
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

