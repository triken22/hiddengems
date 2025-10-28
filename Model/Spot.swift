import Foundation
import CoreLocation

struct Spot: Identifiable, Hashable, Codable {
    var id: String
    var title: String
    var subtitle: String?
    var details: String
    var coordinate: CLLocationCoordinate2D
    var address: String?
    var tags: [String]
    var topics: [String]
    var images: [SpotImage]
    var groupId: String?
    var userId: String?
    var deleted: Bool
    var version: Int
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, details, address, tags, topics, images, groupId, userId, deleted, version, createdAt, updatedAt
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
         version: Int,
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
        self.version = version
        self.createdAt = createdAt
        self.updatedAt = updatedAt
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
        version = try container.decode(Int.self, forKey: .version)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
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
        try container.encode(version, forKey: .version)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
}

struct SpotImage: Hashable, Identifiable, Codable {
    var id: UUID
    var localIdentifier: String?
    var remoteURL: URL?
}
