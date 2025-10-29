import Foundation

struct SyncConfiguration {
    let baseURL: URL
    let bearerToken: String
}

struct SyncPayload: Codable {
    let spots: [SpotDTO]
    let groups: [GroupDTO]
}

struct SpotDTO: Codable {
    var id: String
    var title: String
    var details: String
    var latitude: Double
    var longitude: Double
    var tags: [String]
    var topics: [String]
    var imageRemoteURLs: [URL]
    var groupId: String?
    var userId: String?
    var createdAt: Date
    var updatedAt: Date
    var version: Int
    var deleted: Bool
}

struct GroupDTO: Codable {
    var id: String
    var name: String
    var inviteCode: String
    var memberCount: Int
    var createdAt: Date
    var updatedAt: Date
    var version: Int
    var deleted: Bool
}
