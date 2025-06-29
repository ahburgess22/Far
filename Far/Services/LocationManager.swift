//
//  LocationManager.swift
//  Far
//
//  Created by Austin Burgess on 6/25/25.
//


//
//  LocationManager.swift
//  Far
//
//  Handles Core Location services, permissions, and GPS tracking
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    // MARK: - Properties
    private let locationManager = CLLocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?
    @Published var isLocationServicesEnabled = false
    @Published var heading: CLHeading?
    
    // MARK: - Configuration
    private let desiredAccuracy = kCLLocationAccuracyBest
    private let distanceFilter: CLLocationDistance = 10 // Update every 10 meters
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
        checkLocationServices()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = desiredAccuracy
        locationManager.distanceFilter = distanceFilter
    }
    
    // MARK: - Public Methods
    func checkLocationServices() {
        isLocationServicesEnabled = CLLocationManager.locationServicesEnabled()
        if isLocationServicesEnabled {
            checkLocationAuthorization()
        } else {
            locationError = "Location services are not enabled on this device"
        }
    }
    
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationError = "Location access denied. Please enable in Settings."
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    func startLocationUpdates() {
        guard isLocationServicesEnabled && 
              (authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways) else {
            locationError = "Location permission required to start tracking"
            return
        }
        
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        locationError = nil
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    func requestLocationUpdate() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            locationError = "Location permission required"
            return
        }
        
        locationManager.requestLocation()
    }
    
    // MARK: - Private Methods
    private func checkLocationAuthorization() {
        authorizationStatus = locationManager.authorizationStatus
        
        switch authorizationStatus {
        case .notDetermined:
            break
        case .restricted, .denied:
            locationError = "Location access denied. Please enable location services in Settings."
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Ensure location is recent and accurate
        let locationAge = abs(location.timestamp.timeIntervalSinceNow)
        if locationAge < 30 && location.horizontalAccuracy < 100 {
            DispatchQueue.main.async {
                self.currentLocation = location
                self.locationError = nil
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy > 0 else { return }
        
        DispatchQueue.main.async {
            self.heading = newHeading
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Don't show error if we haven't even requested permission yet
        guard authorizationStatus != .notDetermined else { return }
        
        DispatchQueue.main.async {
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.locationError = "Location access denied"
                case .network:
                    self.locationError = "Network error while getting location"
                case .locationUnknown:
                    self.locationError = "Unable to determine location"
                default:
                    self.locationError = "Location error: \(error.localizedDescription)"
                }
            } else {
                self.locationError = "Failed to get location: \(error.localizedDescription)"
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            self.checkLocationAuthorization()
        }
    }
}

// MARK: - LocationManager Extensions
extension LocationManager {
    /// Returns true if location services are available and authorized
    var isLocationAvailable: Bool {
        return isLocationServicesEnabled && 
               (authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways)
    }
    
    /// Returns a user-friendly status message
    var statusMessage: String {
        if !isLocationServicesEnabled {
            return "Location services disabled"
        }
        
        switch authorizationStatus {
        case .notDetermined:
            return "Location permission needed"
        case .denied, .restricted:
            return "Location access denied"
        case .authorizedWhenInUse, .authorizedAlways:
            return currentLocation != nil ? "Location active" : "Getting location..."
        @unknown default:
            return "Unknown location status"
        }
    }
}
