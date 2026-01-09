//
//  monotationApp.swift
//  monotation
//
//  Created by Stas Neprokin on 28.12.2025.
//

import SwiftUI
import SwiftData

@main
struct monotationApp: App {
    @StateObject private var connectivityManager = ConnectivityManager.shared
    let container: ModelContainer
    
    init() {
        container = ModelContainer.create()
    }
    
    var body: some Scene {
        WindowGroup {
            TimerView()
                .tint(.primary) // Monochrome accent color
                .environmentObject(connectivityManager)
        }
        .modelContainer(container)
    }
}
