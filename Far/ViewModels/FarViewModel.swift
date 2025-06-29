//
//  FarViewModel.swift
//  Far
//
//  Main view model that coordinates between LocationManager and AdventureService
//

import Foundation
import CoreLocation
import Combine
import SwiftUI

class FarViewModel: ObservableObject {
    // MARK: - Services
    @Published var locationManager = LocationManager()
    @Published var adventureService = AdventureService()
    
    // MARK: - UI State
    @Published var showingAdventureCreation = false
    @Published var showingSettings = false
    @Published var showingAdventuresList = false
    @Published var isAppActive = true
    
    // MARK: - Error Handling
    @Published var errorMessage: String?
    @Published var showingError = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupBindings()
        setupLocationTracking()
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup Methods
    
    private func setupBindings() {
        // Monitor adventure prompt state
        adventureService.$shouldPromptForAdventure
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldPrompt in
                if shouldPrompt {
                    self?.showingAdventureCreation = true
                }
            }
            .store(in: &cancellables)
        
        // Monitor location errors
        locationManager.$locationError
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.handleError(error)
            }
            .store(in: &cancellables)
    }
    
    private func setupLocationTracking() {
        // Monitor location changes and check for new adventures
        locationManager.$currentLocation
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard self?.isAppActive == true else { return }
                self?.adventureService.checkForNewAdventure(at: location)
            }
            .store(in: &cancellables)
    }
    
    private func setupNotificationObservers() {
        // Monitor app lifecycle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    // MARK: - Public Methods
    
    /// Initialize location services
    func startLocationTracking() {
        locationManager.requestLocationPermission()
    }
    
    /// Stop location services
    func stopLocationTracking() {
        locationManager.stopLocationUpdates()
    }
    
    /// Create a new adventure
    func createAdventure(name: String, photoData: Data? = nil) {
        adventureService.createAdventure(name: name, photoData: photoData)
        showingAdventureCreation = false
    }
    
    /// Dismiss adventure creation
    func dismissAdventureCreation() {
        adventureService.dismissAdventurePrompt()
        showingAdventureCreation = false
    }
    
    /// Delete an adventure
    func deleteAdventure(_ adventure: Adventure) {
        adventureService.deleteAdventure(withId: adventure.id)
    }
    
    /// Refresh current location
    func refreshLocation() {
        locationManager.requestLocationUpdate()
    }
    
    /// Handle error display
    private func handleError(_ error: String) {
        errorMessage = error
        showingError = true
    }
    
    /// Clear current error
    func clearError() {
        errorMessage = nil
        showingError = false
    }
    
    // MARK: - App Lifecycle
    
    @objc private func appDidBecomeActive() {
        isAppActive = true
        if locationManager.isLocationAvailable {
            locationManager.startLocationUpdates()
        }
    }
    
    @objc private func appWillResignActive() {
        isAppActive = false
        // Keep location updates running in background for adventure detection
        // iOS will automatically manage this based on app capabilities
    }
}

// MARK: - Computed Properties
extension FarViewModel {
    /// Current location status for UI display
    var locationStatus: String {
        return locationManager.statusMessage
    }
    
    /// Whether location is currently active
    var isLocationActive: Bool {
        return locationManager.currentLocation != nil && locationManager.isLocationAvailable
    }
    
    /// Current location coordinate for display
    var currentCoordinate: CLLocationCoordinate2D? {
        return locationManager.currentLocation?.coordinate
    }
    
    /// Recent adventures for quick display
    var recentAdventures: [Adventure] {
        return Array(adventureService.sortedAdventures.prefix(5))
    }
    
    /// Total adventure count
    var totalAdventures: Int {
        return adventureService.adventures.count
    }
    
    /// Current month adventure count
    var currentMonthAdventures: Int {
        return adventureService.currentMonthAdventures.count
    }
    
    /// Unique months with adventures
    var uniqueMonths: Int {
        return adventureService.uniqueMonthsCount
    }
    
    /// Whether we're currently timing a potential adventure
    var isTimingLocation: Bool {
        return adventureService.isTimerActive
    }
    
    /// Current timer progress (0.0 to 1.0)
    var timerProgress: Double {
        return adventureService.timerProgress
    }
    
    /// Formatted timer display
    var formattedTimer: String {
        return adventureService.formattedTimerDuration
    }
    
    /// Time remaining until adventure prompt
    var timeRemaining: String {
        return adventureService.formattedTimeRemaining
    }
}

// MARK: - Data Export/Import
extension FarViewModel {
    /// Export adventures data
    func exportAdventures() -> Data? {
        return adventureService.exportAdventures()
    }
    
    /// Import adventures data
    func importAdventures(from data: Data) -> Bool {
        return adventureService.importAdventures(from: data)
    }
}

// MARK: - Settings Management
extension FarViewModel {
    /// Reset all data (for settings/debug purposes)
    func resetAllData() {
        adventureService.adventures.removeAll()
        adventureService.dismissAdventurePrompt()
        // Note: This will trigger automatic save via the service
    }
    
    /// Get app statistics for settings display
    var appStatistics: [String: Any] {
        return [
            "totalAdventures": totalAdventures,
            "uniqueMonths": uniqueMonths,
            "currentMonthAdventures": currentMonthAdventures,
            "locationAccuracy": locationManager.currentLocation?.horizontalAccuracy ?? 0,
            "lastLocationUpdate": locationManager.currentLocation?.timestamp ?? Date()
        ]
    }
}