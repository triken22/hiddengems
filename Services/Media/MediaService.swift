import Foundation
import PhotosUI

protocol MediaService {
    func loadMediaItems(from items: [PhotosPickerItem]) async throws -> [MediaItem]
}

struct MediaItem: Codable, Hashable {
    let identifier: String
    let url: URL?
    let metadataSummary: String?
    let exifTags: [String]
    let suggestedTitle: String?
}

final class DefaultMediaService: MediaService {
    func loadMediaItems(from items: [PhotosPickerItem]) async throws -> [MediaItem] {
        try await withThrowingTaskGroup(of: MediaItem.self) { group in
            for item in items {
                group.addTask {
                    _ = try await item.loadTransferable(type: Data.self)
                    let identifier = item.itemIdentifier ?? UUID().uuidString
                    return MediaItem(identifier: identifier,
                                     url: nil,
                                     metadataSummary: "Captured photo",
                                     exifTags: [],
                                     suggestedTitle: "Photo \(identifier.prefix(4))")
                }
            }
            return try await group.reduce(into: []) { $0.append($1) }
        }
    }
}

final class PreviewMediaService: MediaService {
    func loadMediaItems(from items: [PhotosPickerItem]) async throws -> [MediaItem] {
        return [MediaItem(identifier: "preview",
                          url: nil,
                          metadataSummary: "Preview image",
                          exifTags: ["preview"],
                          suggestedTitle: "Preview Spot")]
    }
}
