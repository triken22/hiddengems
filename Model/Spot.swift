import Foundation
import CoreLocation
import UIKit

struct Spot: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let subtitle: String?
    let details: String
    let coordinate: CLLocationCoordinate2D
    let address: String?
    let tags: [String]
    let topics: [String]
    let images: [SpotImage]
    let groupId: String?
    let userId: String?
    let deleted: Bool
    let saved: Bool
    let version: Int
    let globalRating: Double
    let ratingUpdatedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
    // Transient property for distance computation (not persisted)
    var distanceMeters: Double?
    
    // Distance formatting helper
    var formattedDistance: String? {
        guard let distance = distanceMeters else { return nil }
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1
        
        if distance < 1000 {
            let meters = Measurement(value: distance, unit: UnitLength.meters)
            return formatter.string(from: meters)
        } else {
            let kilometers = Measurement(value: distance / 1000, unit: UnitLength.kilometers)
            return formatter.string(from: kilometers)
        }
    }
    
    static func == (lhs: Spot, rhs: Spot) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, details, address, tags, topics, images, groupId, userId, deleted, saved, version, globalRating, ratingUpdatedAt, createdAt, updatedAt
        case latitude, longitude
    }
    
    init(id: String,
         title: String,
         subtitle: String?,
         details: String,
         coordinate: CLLocationCoordinate2D,
         address: String?,
         tags: [String],
         topics: [String],
         images: [SpotImage],
         groupId: String?,
         userId: String?,
         deleted: Bool,
         saved: Bool = false,
         version: Int,
         globalRating: Double = 0.0,
         ratingUpdatedAt: Date? = nil,
         createdAt: Date,
         updatedAt: Date) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.details = details
        self.coordinate = coordinate
        self.address = address
        self.tags = tags
        self.topics = topics
        self.images = images
        self.groupId = groupId
        self.userId = userId
        self.deleted = deleted
        self.saved = saved
        self.version = version
        self.globalRating = globalRating
        self.ratingUpdatedAt = ratingUpdatedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.distanceMeters = nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        details = try container.decode(String.self, forKey: .details)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        tags = try container.decode([String].self, forKey: .tags)
        topics = try container.decode([String].self, forKey: .topics)
        images = try container.decode([SpotImage].self, forKey: .images)
        groupId = try container.decodeIfPresent(String.self, forKey: .groupId)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        deleted = try container.decode(Bool.self, forKey: .deleted)
        saved = try container.decodeIfPresent(Bool.self, forKey: .saved) ?? false
        version = try container.decode(Int.self, forKey: .version)
        globalRating = try container.decodeIfPresent(Double.self, forKey: .globalRating) ?? 0.0
        ratingUpdatedAt = try container.decodeIfPresent(Date.self, forKey: .ratingUpdatedAt)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        distanceMeters = nil
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(subtitle, forKey: .subtitle)
        try container.encode(details, forKey: .details)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encode(tags, forKey: .tags)
        try container.encode(topics, forKey: .topics)
        try container.encode(images, forKey: .images)
        try container.encodeIfPresent(groupId, forKey: .groupId)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encode(deleted, forKey: .deleted)
        try container.encode(saved, forKey: .saved)
        try container.encode(version, forKey: .version)
        try container.encode(globalRating, forKey: .globalRating)
        try container.encodeIfPresent(ratingUpdatedAt, forKey: .ratingUpdatedAt)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
}

struct SpotImage: Hashable, Identifiable, Codable {
    let id: UUID
    let localIdentifier: String?
    let remoteURL: URL?
    let imageData: Data? // Stores JPEG data for persistence
    
    var localImage: UIImage? {
        if let data = imageData {
            return UIImage(data: data)
        }
        return nil
    }
    
    init(id: UUID, localIdentifier: String? = nil, remoteURL: URL? = nil, localImage: UIImage? = nil, imageData: Data? = nil) {
        self.id = id
        self.localIdentifier = localIdentifier
        self.remoteURL = remoteURL
        // Convert UIImage to Data if provided
        if let image = localImage, imageData == nil {
            self.imageData = image.jpegData(compressionQuality: 0.8)
        } else {
            self.imageData = imageData
        }
    }
    
    // Custom Hashable implementation to exclude UIImage
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(localIdentifier)
        hasher.combine(remoteURL)
        // Note: We don't include localImage in hash since UIImage doesn't conform to Hashable
    }
    
    // Custom Equatable implementation to exclude UIImage
    static func == (lhs: SpotImage, rhs: SpotImage) -> Bool {
        return lhs.id == rhs.id &&
               lhs.localIdentifier == rhs.localIdentifier &&
               lhs.remoteURL == rhs.remoteURL
        // Note: We don't compare localImage since UIImage doesn't conform to Equatable
    }
    
    enum CodingKeys: String, CodingKey {
        case id, localIdentifier, remoteURL, imageData
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        localIdentifier = try container.decodeIfPresent(String.self, forKey: .localIdentifier)
        remoteURL = try container.decodeIfPresent(URL.self, forKey: .remoteURL)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(localIdentifier, forKey: .localIdentifier)
        try container.encodeIfPresent(remoteURL, forKey: .remoteURL)
        try container.encodeIfPresent(imageData, forKey: .imageData)
    }
}
