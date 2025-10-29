import Foundation

protocol MediaService {
    func loadMediaItems() async throws -> [MediaItem]
}

struct MediaItem: Codable, Hashable {
    let identifier: String
    let url: URL?
    let metadataSummary: String?
    let exifTags: [String]
    let suggestedTitle: String?
}

final class DefaultMediaService: MediaService {
    func loadMediaItems() async throws -> [MediaItem] {
        // PhotosUI temporarily disabled for compilation
        return []
    }
}

final class PreviewMediaService: MediaService {
    func loadMediaItems() async throws -> [MediaItem] {
        return [MediaItem(identifier: "preview",
                          url: nil,
                          metadataSummary: "Preview image",
                          exifTags: ["preview"],
                          suggestedTitle: "Preview Spot")]
    }
}
