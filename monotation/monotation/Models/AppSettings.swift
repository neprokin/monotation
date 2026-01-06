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
    }
}

