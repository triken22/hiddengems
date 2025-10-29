import CoreData
import CoreLocation

extension Spot {
    init(entity: SpotEntity) {
        // CRITICAL: Do not generate IDs or dates during mapping - these must exist in the entity
        // If these are nil, it indicates data corruption or migration failure
        guard let id = entity.id,
              let createdAt = entity.createdAt,
              let updatedAt = entity.updatedAt else {
            print("ERROR: SpotEntity missing required fields. ID: \(entity.id ?? "nil"), created: \(entity.createdAt?.description ?? "nil"), updated: \(entity.updatedAt?.description ?? "nil")")
            // Fall back to safe defaults to prevent crash, but this should be investigated
            self.id = entity.id ?? UUID().uuidString
            self.createdAt = entity.createdAt ?? Date()
            self.updatedAt = entity.updatedAt ?? Date()
            self.title = entity.title ?? "Untitled"
            self.subtitle = entity.subtitle
            self.details = entity.details ?? ""
            self.coordinate = CLLocationCoordinate2D(latitude: entity.latitude, longitude: entity.longitude)
            self.address = entity.address
            self.tags = entity.tagsArray
            self.topics = entity.topicsArray
            self.images = entity.imagesArray
            self.groupId = entity.groupId
            self.userId = entity.userId
            self.deleted = entity.isMarkedDeleted
            self.saved = entity.isSaved
            self.version = Int(entity.version)
            self.globalRating = entity.globalRating
            self.ratingUpdatedAt = entity.ratingUpdatedAt
            self.distanceMeters = nil
            return
        }
        
        self.id = id
        self.title = entity.title ?? "Untitled"
        self.subtitle = entity.subtitle
        self.details = entity.details ?? ""
        self.coordinate = CLLocationCoordinate2D(latitude: entity.latitude, longitude: entity.longitude)
        self.address = entity.address
        self.tags = entity.tagsArray
        self.topics = entity.topicsArray
        self.images = entity.imagesArray
        self.groupId = entity.groupId
        self.userId = entity.userId
        self.deleted = entity.isMarkedDeleted
        self.saved = entity.isSaved
        self.version = Int(entity.version)
        self.globalRating = entity.globalRating
        self.ratingUpdatedAt = entity.ratingUpdatedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.distanceMeters = nil
    }
}

extension SpotEntity {
    func update(from spot: Spot, context: NSManagedObjectContext) {
        // Ensure ID is always set for new entities
        if id == nil {
            id = spot.id
        }
        
        title = spot.title
        subtitle = spot.subtitle
        details = spot.details
        latitude = spot.coordinate.latitude
        longitude = spot.coordinate.longitude
        address = spot.address
        tags = spot.tags.jsonData as NSObject?
        topics = spot.topics.jsonData as NSObject?
        images = spot.images.jsonData as NSObject?
        groupId = spot.groupId
        userId = spot.userId
        isMarkedDeleted = spot.deleted
        isSaved = spot.saved
        version = Int64(spot.version)
        globalRating = spot.globalRating
        ratingUpdatedAt = spot.ratingUpdatedAt
        
        // Ensure createdAt is set for new entities (never update it)
        if createdAt == nil {
            createdAt = spot.createdAt
        }
        
        // Always update updatedAt
        updatedAt = spot.updatedAt
    }

    var tagsArray: [String] { ((tags as? Data)?.decodeJSON() ?? []) }
    var topicsArray: [String] { ((topics as? Data)?.decodeJSON() ?? []) }
    var imagesArray: [SpotImage] { ((images as? Data)?.decodeJSON() ?? []) }
}

private extension Array where Element == String {
    var jsonData: Data? { try? JSONEncoder().encode(self) }
}

private extension Array where Element == SpotImage {
    var jsonData: Data? { try? JSONEncoder().encode(self) }
}

private extension Data {
    func decodeJSON<T: Decodable>() -> T? {
        try? JSONDecoder().decode(T.self, from: self)
    }
}
