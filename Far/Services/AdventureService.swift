//
//  AdventureService.swift
//  Far
//
//  Handles adventure detection, timing, and persistence logic
//

import Foundation
import CoreLocation
import Combine

class AdventureService: ObservableObject {
    // MARK: - Published Properties
    @Published var adventures: [Adventure] = []
    @Published var timeAtCurrentLocation: TimeInterval = 0
    @Published var shouldPromptForAdventure = false
    @Published var pendingAdventureLocation: CLLocation?
    @Published var isTimerActive = false
    
    // MARK: - Configuration Constants
    private let minimumStayDuration: TimeInterval = 300 // 5 minutes
    private let newLocationRadius: CLLocationDistance = 100 // 100 meters
    private let timerUpdateInterval: TimeInterval = 1.0
    private let userDefaultsKey = "SavedAdventures"
    
    // MARK: - Private Properties
    private var currentLocationTimer: Timer?
    private var stableLocationStart: Date?
    private var lastCheckedLocation: CLLocation?
    
    // MARK: - Initialization
    init() {
        loadAdventures()
    }
    
    deinit {
        resetLocationTimer()
    }
    
    // MARK: - Public Methods
    
    /// Check if the given location should trigger a new adventure
    func checkForNewAdventure(at location: CLLocation) {
        // Avoid processing duplicate locations
        if let lastLocation = lastCheckedLocation,
           location.distance(from: lastLocation) < 5 {
            return
        }
        
        lastCheckedLocation = location
        
        if isNewLocation(location) {
            startLocationTimer(for: location)
        } else {
            resetLocationTimer()
        }
    }
    
    /// Create a new adventure with the given details
    func createAdventure(name: String, photoData: Data? = nil) {
        guard let location = pendingAdventureLocation else { return }
        
        let adventure = Adventure(
            name: name,
            coordinate: location.coordinate,
            photoData: photoData
        )
        
        adventures.append(adventure)
        saveAdventures()
        
        // Reset state
        resetAdventurePrompt()
    }
    
    /// Dismiss the current adventure prompt without creating an adventure
    func dismissAdventurePrompt() {
        resetAdventurePrompt()
    }
    
    /// Delete an adventure by ID
    func deleteAdventure(withId id: UUID) {
        adventures.removeAll { $0.id == id }
        saveAdventures()
    }
    
    /// Get adventures sorted by date (most recent first)
    var sortedAdventures: [Adventure] {
        return adventures.sorted { $0.timestamp > $1.timestamp }
    }
    
    /// Get adventures from the current month
    var currentMonthAdventures: [Adventure] {
        let calendar = Calendar.current
        let now = Date()
        
        return adventures.filter { adventure in
            calendar.isDate(adventure.timestamp, equalTo: now, toGranularity: .month)
        }
    }
    
    /// Get the total number of unique months with adventures
    var uniqueMonthsCount: Int {
        let calendar = Calendar.current
        let months = Set(adventures.map { adventure in
            calendar.dateInterval(of: .month, for: adventure.timestamp)?.start ?? adventure.timestamp
        })
        return months.count
    }
    
    // MARK: - Private Methods
    
    private func isNewLocation(_ location: CLLocation) -> Bool {
        // Check if we've been within the specified radius of this location before
        for adventure in adventures {
            if adventure.distance(from: location) < newLocationRadius {
                return false // We've been here before
            }
        }
        return true // This is a new location
    }
    
    private func startLocationTimer(for location: CLLocation) {
        // Reset any existing timer
        resetLocationTimer()
        
        stableLocationStart = Date()
        pendingAdventureLocation = location
        isTimerActive = true
        
        currentLocationTimer = Timer.scheduledTimer(withTimeInterval: timerUpdateInterval, repeats: true) { _ in
            self.updateLocationTimer()
        }
    }
    
    private func updateLocationTimer() {
        guard let startTime = stableLocationStart else { 
            resetLocationTimer()
            return 
        }
        
        timeAtCurrentLocation = Date().timeIntervalSince(startTime)
        
        // Check if we've reached the minimum stay duration
        if timeAtCurrentLocation >= minimumStayDuration && !shouldPromptForAdventure {
            shouldPromptForAdventure = true
        }
    }
    
    private func resetLocationTimer() {
        currentLocationTimer?.invalidate()
        currentLocationTimer = nil
        stableLocationStart = nil
        timeAtCurrentLocation = 0
        isTimerActive = false
        
        // Only reset pending location if we're not showing the prompt
        if !shouldPromptForAdventure {
            pendingAdventureLocation = nil
        }
    }
    
    private func resetAdventurePrompt() {
        shouldPromptForAdventure = false
        pendingAdventureLocation = nil
        resetLocationTimer()
    }
}

// MARK: - Persistence
extension AdventureService {
    private func saveAdventures() {
        do {
            let encoded = try JSONEncoder().encode(adventures)
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        } catch {
            print("Failed to save adventures: \(error)")
        }
    }
    
    private func loadAdventures() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return
        }
        
        do {
            adventures = try JSONDecoder().decode([Adventure].self, from: data)
        } catch {
            print("Failed to load adventures: \(error)")
            adventures = []
        }
    }
    
    /// Export adventures as JSON data
    func exportAdventures() -> Data? {
        do {
            return try JSONEncoder().encode(adventures)
        } catch {
            print("Failed to export adventures: \(error)")
            return nil
        }
    }
    
    /// Import adventures from JSON data
    func importAdventures(from data: Data) -> Bool {
        do {
            let importedAdventures = try JSONDecoder().decode([Adventure].self, from: data)
            
            // Merge with existing adventures (avoid duplicates by location and time)
            for newAdventure in importedAdventures {
                let isDuplicate = adventures.contains { existingAdventure in
                    let timeDiff = abs(existingAdventure.timestamp.timeIntervalSince(newAdventure.timestamp))
                    let distance = existingAdventure.distance(from: CLLocation(
                        latitude: newAdventure.coordinate.latitude,
                        longitude: newAdventure.coordinate.longitude
                    ))
                    
                    return timeDiff < 3600 && distance < 50 // Same adventure if within 1 hour and 50 meters
                }
                
                if !isDuplicate {
                    adventures.append(newAdventure)
                }
            }
            
            saveAdventures()
            return true
        } catch {
            print("Failed to import adventures: \(error)")
            return false
        }
    }
}

// MARK: - Utility Extensions
extension AdventureService {
    /// Format the current timer duration as a string
    var formattedTimerDuration: String {
        let minutes = Int(timeAtCurrentLocation) / 60
        let seconds = Int(timeAtCurrentLocation) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Progress towards the minimum stay duration (0.0 to 1.0)
    var timerProgress: Double {
        return min(timeAtCurrentLocation / minimumStayDuration, 1.0)
    }
    
    /// Remaining time until adventure prompt
    var timeRemaining: TimeInterval {
        return max(minimumStayDuration - timeAtCurrentLocation, 0)
    }
    
    /// Format remaining time as a string
    var formattedTimeRemaining: String {
        let remaining = timeRemaining
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}