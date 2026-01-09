//
//  LocationMapView.swift
//  monotation
//
//  Map view showing meditation location
//

import SwiftUI
import MapKit

struct LocationMapView: View {
    let latitude: Double
    let longitude: Double
    let locationName: String?
    
    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    private var cameraPosition: MapCameraPosition {
        MapCameraPosition.region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        )
    }
    
    var body: some View {
        Map(position: .constant(cameraPosition)) {
            Marker(
                locationName ?? "Место медитации",
                coordinate: coordinate
            )
            .tint(.blue)
        }
        .frame(height: 200)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    LocationMapView(
        latitude: 55.7558,
        longitude: 37.6173,
        locationName: "Москва, Россия"
    )
    .padding()
}
