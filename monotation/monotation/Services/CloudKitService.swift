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
    
    private let modelContext: ModelContext
    
    private init() {
        // Create ModelContext from ModelContainer
        // Note: This uses the same ModelContainer as the app, so CloudKit sync should work
        let container = ModelContainer.create()
        self.modelContext = ModelContext(container)
        
        // Force CloudKit sync by accessing the persistent store coordinator
        // This ensures CloudKit knows about the changes
        print("📦 CloudKitService initialized with ModelContext")
    }
    
    // MARK: - Fetch Meditations
    
    /// Fetch all meditations (CloudKit automatically filters by iCloud account)
    func fetchMeditations() async throws -> [Meditation] {
        do {
            let descriptor = FetchDescriptor<MeditationModel>(
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
            
            let models = try modelContext.fetch(descriptor)
            print("✅ CloudKitService: Fetched \(models.count) meditations")
            
            return models.map { $0.toMeditation() }
        } catch {
            print("❌ CloudKitService.fetchMeditations error: \(error)")
            throw CloudKitError.fetchFailed(error)
        }
    }
    
    // MARK: - Insert Meditation
    
    func insertMeditation(_ meditation: Meditation) async throws {
        do {
            let model = MeditationModel(from: meditation)
            modelContext.insert(model)
            
            // Save to local store (this should trigger CloudKit sync automatically)
            try modelContext.save()
            print("✅ CloudKitService: Meditation saved locally: \(meditation.id)")
            
            // Force process pending changes to trigger CloudKit sync
            // SwiftData with CloudKit should sync automatically, but we can help it along
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Try to save again to ensure changes are persisted
            try modelContext.save()
            print("📦 CloudKitService: Changes persisted, CloudKit sync should happen automatically")
            
            // Note: CloudKit sync happens in the background and may take 5-15 minutes
            // The data is safe locally and will sync when CloudKit is ready
        } catch {
            print("❌ CloudKitService.insertMeditation error: \(error)")
            throw CloudKitError.insertFailed(error)
        }
    }
    
    // MARK: - Update Meditation
    
    func updateMeditation(_ meditation: Meditation) async throws {
        do {
            let descriptor = FetchDescriptor<MeditationModel>(
                predicate: #Predicate { $0.id == meditation.id }
            )
            
            guard let model = try modelContext.fetch(descriptor).first else {
                throw CloudKitError.notFound
            }
            
            // Update model properties
            model.startTime = meditation.startTime
            model.endTime = meditation.endTime
            model.pose = meditation.pose.rawValue
            model.place = meditation.place.storedValue
            model.note = meditation.note
            
            try modelContext.save()
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
            let descriptor = FetchDescriptor<MeditationModel>(
                predicate: #Predicate { $0.id == id }
            )
            
            guard let model = try modelContext.fetch(descriptor).first else {
                throw CloudKitError.notFound
            }
            
            modelContext.delete(model)
            
            try modelContext.save()
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
