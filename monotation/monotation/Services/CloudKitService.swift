//
//  CloudKitService.swift
//  monotation
//
//  CloudKit service using SwiftData for meditation CRUD operations
//

import Foundation
import SwiftData

@MainActor
class CloudKitService {
    static let shared = CloudKitService()
    
    private var modelContext: ModelContext?
    
    private init() {
        // ModelContext will be set from environment
    }
    
    /// Set ModelContext from environment (should be called once at app startup)
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    private func getModelContext() throws -> ModelContext {
        guard let context = modelContext else {
            // Fallback: create from shared container (shouldn't happen in normal flow)
            let container = ModelContainer.create()
            return ModelContext(container)
        }
        return context
    }
    
    // MARK: - Fetch Meditations
    
    /// Fetch all meditations (CloudKit automatically filters by iCloud account)
    func fetchMeditations() async throws -> [Meditation] {
        do {
            let context = try getModelContext()
            let descriptor = FetchDescriptor<MeditationModel>(
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
            
            let models = try context.fetch(descriptor)
            return models.map { $0.toMeditation() }
        } catch {
            print("❌ CloudKitService.fetchMeditations error: \(error)")
            throw CloudKitError.fetchFailed(error)
        }
    }
    
    // MARK: - Insert Meditation
    
    func insertMeditation(_ meditation: Meditation) async throws {
        do {
            let context = try getModelContext()
            let model = MeditationModel(from: meditation)
            context.insert(model)
            
            // Save to local store (this should trigger CloudKit sync automatically)
            try context.save()
            
            // Force process pending changes to trigger CloudKit sync
            // SwiftData with CloudKit should sync automatically, but we can help it along
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Try to save again to ensure changes are persisted
            try context.save()
            
            // Note: CloudKit sync happens in the background and may take 5-15 minutes
            // The data is safe locally and will sync when CloudKit is ready
            
            // Sync to Obsidian if enabled
            Task {
                do {
                    try await ObsidianService.shared.addMeditation(meditation)
                } catch {
                    // Don't throw - Obsidian sync is optional
                }
            }
        } catch {
            print("❌ CloudKitService.insertMeditation error: \(error)")
            throw CloudKitError.insertFailed(error)
        }
    }
    
    // MARK: - Update Meditation
    
    func updateMeditation(_ meditation: Meditation) async throws {
        do {
            let context = try getModelContext()
            let descriptor = FetchDescriptor<MeditationModel>(
                predicate: #Predicate { $0.id == meditation.id }
            )
            
            guard let model = try context.fetch(descriptor).first else {
                throw CloudKitError.notFound
            }
            
            // Update model properties
            model.startTime = meditation.startTime
            model.endTime = meditation.endTime
            model.pose = meditation.pose.rawValue
            model.latitude = meditation.latitude
            model.longitude = meditation.longitude
            model.locationName = meditation.locationName
            model.note = meditation.note
            model.averageHeartRate = meditation.averageHeartRate
            
            try context.save()
            print("✅ CloudKitService: Meditation updated in CloudKit: \(meditation.id)")
        } catch {
            if case CloudKitError.notFound = error {
                throw error
            }
            print("❌ CloudKitService.updateMeditation error: \(error)")
            throw CloudKitError.updateFailed(error)
        }
    }
    
    // MARK: - Delete Meditation
    
    func deleteMeditation(id: UUID) async throws {
        do {
            let context = try getModelContext()
            let descriptor = FetchDescriptor<MeditationModel>(
                predicate: #Predicate { $0.id == id }
            )
            
            guard let model = try context.fetch(descriptor).first else {
                throw CloudKitError.notFound
            }
            
            context.delete(model)
            
            try context.save()
            print("✅ CloudKitService: Meditation deleted from CloudKit: \(id)")
        } catch {
            if case CloudKitError.notFound = error {
                throw error
            }
            print("❌ CloudKitService.deleteMeditation error: \(error)")
            throw CloudKitError.deleteFailed(error)
        }
    }
}

// MARK: - CloudKit Errors

enum CloudKitError: LocalizedError {
    case insertFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    case fetchFailed(Error)
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .insertFailed(let error):
            return "Ошибка сохранения медитации: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Ошибка обновления медитации: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Ошибка удаления медитации: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Ошибка загрузки медитаций: \(error.localizedDescription)"
        case .notFound:
            return "Медитация не найдена"
        }
    }
}
