//
//  AdventureService.swift
//  Far
//
//  Created by Austin Burgess on 6/25/25.
//


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
    @Published var formattedTimerDuration: String = "00:00"
    @Published var timerProgress: Double = 0.0
    @Published var formattedTimeRemaining: String = "05:00"
    
    // MARK: - Configuration Constants
    private let minimumStayDuration: TimeInterval = 60 // 1 minute
    private let newLocationRadius: CLLocationDistance = 27 // 100 meters
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
    func checkForNewAdventure(at location: CLLocation, forceCheck: Bool = false) {
        // Only avoid processing duplicates if NOT a forced check
        if !forceCheck,
           let lastLocation = lastCheckedLocation,
           location.distance(from: lastLocation) < 5 {
            return
        }
        
        lastCheckedLocation = location
        
        print("🗺️ Checking location (forced: \(forceCheck)), shouldPrompt: \(shouldPromptForAdventure)")
            
        if isNewLocation(location) {
            print("✅ New location detected, starting timer")
            startLocationTimer(for: location)
        } else {
            print("❌ Not new location, resetting timer")
            resetLocationTimer()
        }
    }
    
    /// Create a new adventure with the given details
    func createAdventure(name: String, photosData: [Data] = []) {
        guard let location = pendingAdventureLocation else { return }
        
        let adventure = Adventure(
            name: name,
            coordinate: location.coordinate,
            photosData: photosData
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
        
        let currentTime = Date().timeIntervalSince(startTime)
        print("⏰ Timer: \(currentTime), shouldPrompt: \(shouldPromptForAdventure)")
        
        // 🔥 THIS IS THE FIX - Ensure main thread for @Published updates:
        DispatchQueue.main.async {
            self.timeAtCurrentLocation = currentTime
            self.formattedTimerDuration = self.formatTimerDuration(currentTime)
            self.timerProgress = min(currentTime / self.minimumStayDuration, 1.0)
            self.formattedTimeRemaining = self.formatTimerDuration(max(self.minimumStayDuration - currentTime, 0))
            
            // Check if we've reached the minimum stay duration
            if currentTime >= self.minimumStayDuration && !self.shouldPromptForAdventure {
                print("🎉 TRIGGERING ADVENTURE PROMPT!")
                self.shouldPromptForAdventure = true
            }
        }
    }

    // Helper function (add this too):
    private func formatTimerDuration(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
    func saveAdventures() {
        do {
            let encoded = try JSONEncoder().encode(adventures)
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        } catch {
            print("Failed to save adventures: \(error)")
        }
    }
    
    private func loadAdventures() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            print("🗂️ No saved adventures found")
            return
        }
        
        print("🗂️ Loading adventures from UserDefaults...")
        
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
    /// Remaining time until adventure prompt
    var timeRemaining: TimeInterval {
        return max(minimumStayDuration - timeAtCurrentLocation, 0)
    }
}
