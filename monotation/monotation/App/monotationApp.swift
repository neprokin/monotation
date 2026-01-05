//
//  monotationApp.swift
//  monotation
//
//  Created by Stas Neprokin on 28.12.2025.
//

import SwiftUI

@main
struct monotationApp: App {
    @StateObject private var connectivityManager = ConnectivityManager.shared
    
    var body: some Scene {
        WindowGroup {
            TimerView()
                .tint(.primary) // Monochrome accent color
                .environmentObject(connectivityManager)
        }
    }
}
