//
//  monotation_Watch_AppApp.swift
//  monotation Watch App
//
//  Main Watch App entry point
//

import SwiftUI

@main
struct monotation_Watch_App: App {
    @StateObject private var workoutManager = WorkoutManager()
    @StateObject private var connectivityManager = ConnectivityManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(workoutManager)
                .environmentObject(connectivityManager)
        }
    }
}
