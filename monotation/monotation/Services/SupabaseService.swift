//
//  SupabaseService.swift
//  monotation
//
//  Supabase database service for meditation CRUD operations
//

import Foundation
import Supabase

actor SupabaseService {
    static let shared = SupabaseService()
    
    private let client: SupabaseClient?
    
    private init() {
        // Initialize client only if config is available
        if let url = URL(string: SupabaseConfig.url),
           !SupabaseConfig.url.contains("YOUR_SUPABASE_URL_HERE"),
           !SupabaseConfig.anonKey.contains("YOUR_SUPABASE_ANON_KEY_HERE") {
            self.client = SupabaseClient(
                supabaseURL: url,
                supabaseKey: SupabaseConfig.anonKey
            )
        } else {
            // Config not set up yet, client will be nil
            self.client = nil
            print("⚠️ SupabaseService: Config not set up. Using sample data mode.")
        }
    }
    
    // MARK: - Check if service is available
    
    var isAvailable: Bool {
        client != nil
    }
    
    // MARK: - Auth Client Access
    
    var authClient: AuthClient? {
        client?.auth
    }
    
    var clientInstance: SupabaseClient? {
        client
    }
    
    // MARK: - Fetch Meditations
    
    func fetchMeditations(for userId: String) async throws -> [Meditation] {
        guard let client = client else {
            // Return sample data if Supabase not configured
            return Meditation.sampleList
        }
        
        do {
            // Query meditations for user, ordered by start_time descending
            let response: [MeditationDB] = try await client
                .from("meditations")
                .select()
                .eq("user_id", value: userId)
                .order("start_time", ascending: false)
                .execute()
                .value
            
            // Convert DB models to app models
            return response.map { $0.toMeditation() }
        } catch {
            print("❌ SupabaseService.fetchMeditations error: \(error)")
            throw SupabaseError.fetchFailed(error)
        }
    }
    
    // MARK: - Insert Meditation
    
    func insertMeditation(_ meditation: Meditation) async throws {
        guard let client = client else {
            print("⚠️ SupabaseService: Config not set up. Meditation not saved.")
            return
        }
        
        do {
            // Convert app model to DB model
            let dbMeditation = MeditationDB(from: meditation)
            
            try await client
                .from("meditations")
                .insert(dbMeditation)
                .execute()
            
            print("✅ Meditation saved to Supabase: \(meditation.id)")
        } catch {
            print("❌ SupabaseService.insertMeditation error: \(error)")
            throw SupabaseError.insertFailed(error)
        }
    }
    
    // MARK: - Update Meditation
    
    func updateMeditation(_ meditation: Meditation) async throws {
        guard let client = client else {
            print("⚠️ SupabaseService: Config not set up. Meditation not updated.")
            return
        }
        
        do {
            let dbMeditation = MeditationDB(from: meditation)
            
            try await client
                .from("meditations")
                .update(dbMeditation)
                .eq("id", value: meditation.id.uuidString)
                .execute()
            
            print("✅ Meditation updated in Supabase: \(meditation.id)")
        } catch {
            print("❌ SupabaseService.updateMeditation error: \(error)")
            throw SupabaseError.updateFailed(error)
        }
    }
    
    // MARK: - Delete Meditation
    
    func deleteMeditation(id: UUID) async throws {
        guard let client = client else {
            print("⚠️ SupabaseService: Config not set up. Meditation not deleted.")
            return
        }
        
        do {
            try await client
                .from("meditations")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
            
            print("✅ Meditation deleted from Supabase: \(id)")
        } catch {
            print("❌ SupabaseService.deleteMeditation error: \(error)")
            throw SupabaseError.deleteFailed(error)
        }
    }
}

// MARK: - Database Model

/// Database representation of Meditation (matches Supabase schema)
private struct MeditationDB: Codable {
    let id: UUID
    let userId: UUID  // In DB it's UUID, but we use String in app model
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval  // Stored as INTERVAL in PostgreSQL
    let pose: String  // Stored as TEXT
    let place: String  // Stored as TEXT
    let note: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case duration
        case pose
        case place
        case note
        case createdAt = "created_at"
    }
    
    init(from meditation: Meditation) {
        self.id = meditation.id
        // Convert String userId to UUID (assuming it's a valid UUID string)
        self.userId = UUID(uuidString: meditation.userId) ?? UUID()
        self.startTime = meditation.startTime
        self.endTime = meditation.endTime
        self.duration = meditation.duration
        self.pose = meditation.pose.rawValue
        self.place = meditation.place.storedValue
        self.note = meditation.note
        self.createdAt = meditation.createdAt
    }
    
    func toMeditation() -> Meditation {
        Meditation(
            id: id,
            userId: userId.uuidString,
            startTime: startTime,
            endTime: endTime,
            pose: MeditationPose(rawValue: pose) ?? .burmese,
            place: MeditationPlace.from(place),
            note: note,
            createdAt: createdAt
        )
    }
}

// MARK: - Supabase Errors

enum SupabaseError: LocalizedError {
    case fetchFailed(Error)
    case insertFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    case notConfigured
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Ошибка загрузки медитаций: \(error.localizedDescription)"
        case .insertFailed(let error):
            return "Ошибка сохранения медитации: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Ошибка обновления медитации: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Ошибка удаления медитации: \(error.localizedDescription)"
        case .notConfigured:
            return "Supabase не настроен. Проверьте Config.swift"
        }
    }
}

