import Foundation
import CoreData

protocol SyncService {
    func push(spots: [Spot], groups: [Group]) async throws
    func pull(since version: Int) async throws -> SyncPayload
}

final class DefaultSyncService: SyncService {
    private let configuration: SyncConfiguration
    private let urlSession: URLSession

    init(configuration: SyncConfiguration, urlSession: URLSession = .shared) {
        self.configuration = configuration
        self.urlSession = urlSession
    }

    func push(spots: [Spot], groups: [Group]) async throws {
        let payload = SyncPayload(spots: spots.map(SpotDTO.init), groups: groups.map(GroupDTO.init))
        var request = URLRequest(url: configuration.baseURL.appendingPathComponent("/api/sync/push"))
        request.httpMethod = "POST"
        request.addValue("Bearer \(configuration.bearerToken)", forHTTPHeaderField: "Authorization")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(payload)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        _ = try await urlSession.data(for: request)
    }

    func pull(since version: Int) async throws -> SyncPayload {
        var components = URLComponents(url: configuration.baseURL.appendingPathComponent("/api/sync/pull"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "sinceVersion", value: String(version))]
        var request = URLRequest(url: components!.url!)
        request.addValue("Bearer \(configuration.bearerToken)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await urlSession.data(for: request)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SyncPayload.self, from: data)
    }
}

extension SpotDTO {
    init(_ spot: Spot) {
        self.id = spot.id
        self.title = spot.title
        self.details = spot.details
        self.latitude = spot.coordinate.latitude
        self.longitude = spot.coordinate.longitude
        self.tags = spot.tags
        self.topics = spot.topics
        self.imageRemoteURLs = spot.images.compactMap(\.remoteURL)
        self.groupId = spot.groupId
        self.userId = spot.userId
        self.createdAt = spot.createdAt
        self.updatedAt = spot.updatedAt
        self.version = spot.version
        self.deleted = spot.deleted
    }
}

extension GroupDTO {
    init(_ group: Group) {
        self.id = group.id
        self.name = group.name
        self.inviteCode = group.inviteCode
        self.memberCount = group.memberCount
        self.createdAt = group.createdAt
        self.updatedAt = group.updatedAt
        self.version = group.version
        self.deleted = group.deleted
    }
}
