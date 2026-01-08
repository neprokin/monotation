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
        // Access config values (assuming Config is nonisolated or accessed safely)
        let configURL = MainActor.assumeIsolated { SupabaseConfig.url }
        let configKey = MainActor.assumeIsolated { SupabaseConfig.anonKey }
        
        if let url = URL(string: configURL),
           !configURL.contains("YOUR_SUPABASE_URL_HERE"),
           !configKey.contains("YOUR_SUPABASE_ANON_KEY_HERE") {
            // Initialize Supabase client with AuthClient configuration
            // This fixes the warning about emitLocalSessionAsInitialSession
            // Use default localStorage (Keychain) and set emitLocalSessionAsInitialSession
            let authConfig = AuthClient.Configuration(
                localStorage: .keychain,
                emitLocalSessionAsInitialSession: true
            )
            
            let options = SupabaseClientOptions(
                auth: authConfig
            )
            
            self.client = SupabaseClient(
                supabaseURL: url,
                supabaseKey: configKey,
                options: options
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
            return await MainActor.run { Meditation.sampleList }
        }
        
        do {
            // Query meditations for user, ordered by start_time descending
            // Convert userId string to UUID for query
            // For "temp-user-id", use the same fixed UUID as in insert
            let userUUID: UUID
            if userId == "temp-user-id" {
                userUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
            } else {
                userUUID = UUID(uuidString: userId) ?? UUID()
            }
            print("🔍 SupabaseService: Fetching meditations for userId: \(userId) (UUID: \(userUUID.uuidString))")
            
            // For development: load all meditations if temp-user-id (to see all test data)
            let response: [MeditationDB]
            if userId == "temp-user-id" {
                // Load all meditations for development (no filter)
                print("🔍 SupabaseService: Loading ALL meditations (development mode)")
                response = try await client
                    .from("meditations")
                    .select()
                    .order("start_time", ascending: false)
                    .execute()
                    .value
            } else {
                // Load only user's meditations
                response = try await client
                    .from("meditations")
                    .select()
                    .eq("user_id", value: userUUID.uuidString)
                    .order("start_time", ascending: false)
                    .execute()
                    .value
            }
            
            print("✅ SupabaseService: Fetched \(response.count) meditations")
            
            // Convert DB models to app models (need MainActor for MeditationPlace.from)
            return await MainActor.run {
                response.map { $0.toMeditation() }
            }
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
            // Convert app model to DB model (nonisolated struct, safe to use)
            let dbMeditation = MeditationDB(from: meditation)
            
            print("💾 SupabaseService: Saving meditation with userId: \(meditation.userId) -> UUID: \(dbMeditation.userId.uuidString)")
            
            try await client
                .from("meditations")
                .insert(dbMeditation)
                .execute()
            
            print("✅ Meditation saved to Supabase: \(meditation.id), user_id: \(dbMeditation.userId.uuidString)")
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
private nonisolated struct MeditationDB: Codable {
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
    
    // Custom decoding for duration (PostgreSQL INTERVAL is returned as string)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decode(Date.self, forKey: .endTime)
        
        // Decode duration: PostgreSQL INTERVAL is returned as string (e.g., "00:00:03")
        if let durationString = try? container.decode(String.self, forKey: .duration) {
            duration = Self.parsePostgreSQLInterval(durationString)
        } else if let durationSeconds = try? container.decode(Double.self, forKey: .duration) {
            // If it's already a number (seconds), use it directly
            duration = durationSeconds
        } else {
            // Fallback: calculate from startTime and endTime
            duration = endTime.timeIntervalSince(startTime)
        }
        
        pose = try container.decode(String.self, forKey: .pose)
        place = try container.decode(String.self, forKey: .place)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    // Custom encoding: convert TimeInterval to PostgreSQL INTERVAL string
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        
        // Encode duration as PostgreSQL INTERVAL string (format: "HH:MM:SS")
        try container.encode(MeditationDB.formatPostgreSQLInterval(duration), forKey: .duration)
        
        try container.encode(pose, forKey: .pose)
        try container.encode(place, forKey: .place)
        try container.encodeIfPresent(note, forKey: .note)
        try container.encode(createdAt, forKey: .createdAt)
    }
    
    // Helper: Parse PostgreSQL INTERVAL string to TimeInterval
    private static func parsePostgreSQLInterval(_ intervalString: String) -> TimeInterval {
        // PostgreSQL INTERVAL format examples:
        // "00:00:03" (HH:MM:SS)
        // "00:10:00" (HH:MM:SS)
        // "1 day 00:10:00" (DD HH:MM:SS)
        // "00:10:00.123456" (with microseconds)
        
        var totalSeconds: TimeInterval = 0
        
        // Check for days (format: "N day(s) HH:MM:SS")
        let parts = intervalString.split(separator: " ", omittingEmptySubsequences: true)
        var timePart = intervalString
        
        if parts.count >= 3, let days = Double(parts[0]) {
            // Has days prefix
            totalSeconds += days * 86400 // 24 * 60 * 60
            // Extract time part (everything after "day" or "days")
            if let dayIndex = intervalString.range(of: "day") {
                timePart = String(intervalString[dayIndex.upperBound...]).trimmingCharacters(in: .whitespaces)
            }
        }
        
        // Parse time part (HH:MM:SS or HH:MM:SS.microseconds)
        let timeComponents = timePart.split(separator: ":")
        if timeComponents.count >= 3 {
            let hours = Double(timeComponents[0]) ?? 0
            let minutes = Double(timeComponents[1]) ?? 0
            // Remove microseconds if present
            let secondsString = String(timeComponents[2]).split(separator: ".").first ?? Substring(timeComponents[2])
            let seconds = Double(secondsString) ?? 0
            totalSeconds += hours * 3600 + minutes * 60 + seconds
        }
        
        return totalSeconds
    }
    
    // Helper: Format TimeInterval to PostgreSQL INTERVAL string
    private static func formatPostgreSQLInterval(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    init(from meditation: Meditation) {
        self.id = meditation.id
        // Convert String userId to UUID
        // For "temp-user-id", use a fixed UUID for consistency
        let userUUID: UUID
        if meditation.userId == "temp-user-id" {
            // Fixed UUID for temp user (for development)
            userUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
        } else {
            userUUID = UUID(uuidString: meditation.userId) ?? UUID()
        }
        self.userId = userUUID
        self.startTime = meditation.startTime
        self.endTime = meditation.endTime
        // Duration is computed from startTime and endTime (no MainActor needed)
        self.duration = meditation.endTime.timeIntervalSince(meditation.startTime)
        self.pose = meditation.pose.rawValue
        // storedValue is a simple computed property (no MainActor needed)
        self.place = meditation.place.storedValue
        self.note = meditation.note
        self.createdAt = meditation.createdAt
    }
    
    func toMeditation() -> Meditation {
        // MeditationPlace.from is a static method, safe to call
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

