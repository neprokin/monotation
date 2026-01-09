//
//  AppSettings.swift
//  monotation
//
//  User settings stored in UserDefaults
//

import Foundation
import Combine

@MainActor
class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Settings Keys
    
    private enum Keys {
        static let defaultDuration = "defaultDuration"
        static let defaultPose = "defaultPose"
        static let obsidianSessionsPath = "obsidianSessionsPath"
    }
    
    // MARK: - Default Duration
    
    @Published var defaultDuration: TimeInterval {
        didSet {
            defaults.set(defaultDuration, forKey: Keys.defaultDuration)
        }
    }
    
    // MARK: - Default Pose
    
    @Published var defaultPose: MeditationPose {
        didSet {
            defaults.set(defaultPose.rawValue, forKey: Keys.defaultPose)
        }
    }
    
    // MARK: - Obsidian Integration
    
    /// URL to sessions.md file (stored as security-scoped bookmark)
    @Published var obsidianSessionsURL: URL? {
        didSet {
            if let url = obsidianSessionsURL {
                // Check if file exists before creating bookmark
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: url.path) {
                    // File exists - save as bookmark for iCloud files
                    // Note: In iOS, security-scoped bookmarks work differently than macOS
                    do {
                        let bookmarkData = try url.bookmarkData(
                            options: [],
                            includingResourceValuesForKeys: nil,
                            relativeTo: nil
                        )
                        defaults.set(bookmarkData, forKey: Keys.obsidianSessionsPath)
                    } catch {
                        print("⚠️ AppSettings: Failed to save bookmark: \(error)")
                        // Fallback: save as path string
                        defaults.set(url.path, forKey: Keys.obsidianSessionsPath)
                    }
                } else {
                    // File doesn't exist yet - save as path string
                    // Bookmark will be created when file is first written
                    defaults.set(url.path, forKey: Keys.obsidianSessionsPath)
                }
            } else {
                defaults.removeObject(forKey: Keys.obsidianSessionsPath)
            }
        }
    }
    
    /// Legacy: String path (for backward compatibility, converts to/from URL)
    var obsidianSessionsPath: String? {
        get {
            return obsidianSessionsURL?.path
        }
        set {
            if let path = newValue, !path.isEmpty {
                obsidianSessionsURL = URL(fileURLWithPath: path)
            } else {
                obsidianSessionsURL = nil
            }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Load default duration (default: 15 minutes)
        let savedDuration = defaults.double(forKey: Keys.defaultDuration)
        self.defaultDuration = savedDuration > 0 ? savedDuration : 900 // 15 minutes
        
        // Load default pose (default: lotus)
        if let poseString = defaults.string(forKey: Keys.defaultPose),
           let pose = MeditationPose(rawValue: poseString) {
            self.defaultPose = pose
        } else {
            self.defaultPose = .lotus
        }
        
        // Load Obsidian sessions URL from bookmark or path
        if let bookmarkData = defaults.data(forKey: Keys.obsidianSessionsPath) {
            do {
                var isStale = false
                let url = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: [.withoutUI],
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )
                if !isStale {
                    // Try to access security-scoped resource (may not be needed in iOS)
                    _ = url.startAccessingSecurityScopedResource()
                    self.obsidianSessionsURL = url
                } else {
                    // Bookmark is stale, try string path
                    if let path = defaults.string(forKey: Keys.obsidianSessionsPath) {
                        self.obsidianSessionsURL = URL(fileURLWithPath: path)
                    } else {
                        defaults.removeObject(forKey: Keys.obsidianSessionsPath)
                        self.obsidianSessionsURL = nil
                    }
                }
            } catch {
                print("⚠️ AppSettings: Failed to resolve bookmark: \(error)")
                // Try legacy string path for backward compatibility
                if let path = defaults.string(forKey: Keys.obsidianSessionsPath) {
                    self.obsidianSessionsURL = URL(fileURLWithPath: path)
                } else {
                    self.obsidianSessionsURL = nil
                }
            }
        } else {
            // Try legacy string path for backward compatibility
            if let path = defaults.string(forKey: Keys.obsidianSessionsPath) {
                self.obsidianSessionsURL = URL(fileURLWithPath: path)
            } else {
                self.obsidianSessionsURL = nil
            }
        }
    }
}

