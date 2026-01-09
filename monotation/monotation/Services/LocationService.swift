//
//  LocationService.swift
//  monotation
//
//  Service for getting current location and reverse geocoding
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
    
    private func reverseGeocode(location: CLLocation) async throws -> String {
        // Use CLGeocoder for now (deprecated in iOS 26.0+ but still functional)
        // TODO: Migrate to MapKit API when stable API is available
        let geocoder = CLGeocoder()
        
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        
        guard let placemark = placemarks.first else {
            throw LocationError.geocodingFailed
        }
        
        // Build address string
        var addressComponents: [String] = []
        
        if let street = placemark.thoroughfare {
            addressComponents.append(street)
        }
        if let subLocality = placemark.subLocality {
            addressComponents.append(subLocality)
        }
        if let locality = placemark.locality {
            addressComponents.append(locality)
        }
        if let country = placemark.country {
            addressComponents.append(country)
        }
        
        return addressComponents.joined(separator: ", ")
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        Task { @MainActor in
            currentLocation = location
            
            // Reverse geocode to get address
            do {
                let address = try await reverseGeocode(location: location)
                currentAddress = address
                
                let result = LocationResult(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    address: address
                )
                
                locationContinuation?.resume(returning: result)
                locationContinuation = nil
            } catch {
                // If geocoding fails, still return location with coordinates
                let result = LocationResult(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    address: nil
                )
                
                locationContinuation?.resume(returning: result)
                locationContinuation = nil
            }
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
