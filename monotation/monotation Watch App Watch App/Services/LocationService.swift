//
//  LocationService.swift
//  monotation Watch App
//
//  Service for getting current location on Apple Watch
//

import Foundation
import CoreLocation
import Combine

@MainActor
class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var currentAddress: String?
    @Published var isLocationLoading = false
    
    private var locationContinuation: CheckedContinuation<LocationResult, Error>?
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Request Authorization
    
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Get Current Location
    
    /// Get current location with address
    /// Returns coordinates and address string
    func getCurrentLocation() async throws -> LocationResult {
        // Check authorization
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            throw LocationError.notAuthorized
        }
        
        isLocationLoading = true
        defer { isLocationLoading = false }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            
            // Request location
            locationManager.requestLocation()
        }
    }
    
    // MARK: - Reverse Geocoding
    
    // Note: On watchOS 26.0+, CLGeocoder is deprecated
    // We'll only get coordinates on Watch and let iPhone do the geocoding
    private func reverseGeocode(location: CLLocation) async throws -> String {
        // On Watch, we skip geocoding and return nil
        // iPhone will handle geocoding when it receives the coordinates
        throw LocationError.geocodingFailed
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        Task { @MainActor in
            currentLocation = location
            
            // On Watch, we only return coordinates
            // iPhone will handle geocoding when it receives the data
            let result = LocationResult(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                address: nil  // Will be geocoded on iPhone
            )
            
            locationContinuation?.resume(returning: result)
            locationContinuation = nil
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            locationContinuation?.resume(throwing: error)
            locationContinuation = nil
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
        }
    }
}

// MARK: - Location Result

struct LocationResult {
    let latitude: Double
    let longitude: Double
    let address: String?
}

// MARK: - Location Errors

enum LocationError: LocalizedError {
    case notAuthorized
    case geocodingFailed
    case locationUnavailable
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Доступ к геолокации не разрешен"
        case .geocodingFailed:
            return "Не удалось определить адрес"
        case .locationUnavailable:
            return "Геолокация недоступна"
        }
    }
}
