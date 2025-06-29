//
//  Adventure.swift
//  Far
//
//  Created by Austin Burgess on 6/25/25.
//


//
//  Adventure.swift
//  Far
//
//  Adventure data model with proper Codable implementation for persistence
//

import Foundation
import CoreLocation

struct Adventure: Identifiable, Codable {
    var id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
    var photosData: [Data]
    let address: String?
    
    // Custom coding keys for CLLocationCoordinate2D
    enum CodingKeys: String, CodingKey {
        case id, name, timestamp, photosData, address
        case latitude, longitude
    }
    
    init(name: String, coordinate: CLLocationCoordinate2D, photosData: [Data] = [], address: String? = nil) {
        self.name = name
        self.coordinate = coordinate
        self.timestamp = Date()
        self.photosData = photosData
        self.address = address
    }
    
    // MARK: - Custom Codable Implementation
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        photosData = try container.decode([Data].self, forKey: .photosData)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(photosData, forKey: .photosData)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
}

// MARK: - Adventure Extensions
extension Adventure {
    /// Returns the distance from this adventure to a given location
    func distance(from location: CLLocation) -> CLLocationDistance {
        let adventureLocation = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        return location.distance(from: adventureLocation)
    }
    
    /// Returns a formatted address string for display
    var displayAddress: String {
        return address ?? "Unknown Location"
    }
    
    /// Returns true if this adventure has a photo
    var hasPhotos: Bool {
        return !photosData.isEmpty
    }
}
