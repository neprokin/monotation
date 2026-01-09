//
//  ModelContainer.swift
//  monotation
//
//  SwiftData ModelContainer configuration for CloudKit
//

import SwiftData
import SwiftUI

extension ModelContainer {
    // Shared ModelContainer instance to avoid duplicate CloudKit handlers
    private static var sharedContainer: ModelContainer?
    
    static func create() -> ModelContainer {
        // Return existing container if already created
        if let existing = sharedContainer {
            return existing
        }
        
        let schema = Schema([MeditationModel.self])
        
        // Configure for CloudKit
        // Note: cloudKitDatabase: .automatic uses the container from entitlements
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .automatic  // Uses iCloud.com.neprokin.monotation from entitlements
        )
        
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            
            // Store shared instance
            sharedContainer = container
            
            return container
        } catch {
            print("❌ Failed to create ModelContainer: \(error)")
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
