import Foundation

final class PreviewSyncService: SyncService {
    func push(spots: [Spot], groups: [Group]) async throws {}

    func pull(since version: Int) async throws -> SyncPayload {
        return SyncPayload(spots: [], groups: [])
    }
}
