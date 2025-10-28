import CoreData
import CoreLocation

extension Spot {
    init(entity: SpotEntity) {
        self.id = entity.id ?? UUID().uuidString
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
        self.deleted = entity.deleted
        self.version = Int(entity.version)
        self.createdAt = entity.createdAt ?? Date()
        self.updatedAt = entity.updatedAt ?? Date()
    }
}

extension SpotEntity {
    func update(from spot: Spot, context: NSManagedObjectContext) {
        id = spot.id
        title = spot.title
        subtitle = spot.subtitle
        details = spot.details
        latitude = spot.coordinate.latitude
        longitude = spot.coordinate.longitude
        address = spot.address
        tags = spot.tags.jsonData
        topics = spot.topics.jsonData
        images = spot.images.jsonData
        groupId = spot.groupId
        userId = spot.userId
        deleted = spot.deleted
        version = Int64(spot.version)
        createdAt = spot.createdAt
        updatedAt = spot.updatedAt
    }

    var tagsArray: [String] { (tags?.decodeJSON() ?? []) }
    var topicsArray: [String] { (topics?.decodeJSON() ?? []) }
    var imagesArray: [SpotImage] { (images?.decodeJSON() ?? []) }
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
