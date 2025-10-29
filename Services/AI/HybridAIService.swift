import Foundation
import CoreLocation

actor HybridAIService {
    private let configuration: HybridAIConfiguration
    private let jobQueue: AIJobQueue

    init(configuration: HybridAIConfiguration) {
        self.configuration = configuration
        self.jobQueue = AIJobQueue()
    }

    func suggestMetadata(for media: [MediaItem], title: String, coordinate: CLLocationCoordinate2D?) async throws -> AIMetadataResult {
        if let key = configuration.openAIKey ?? configuration.groqKey, !key.isEmpty {
            return try await performRemoteInference(media: media, title: title, coordinate: coordinate)
        } else {
            return heuristics(media: media, title: title, coordinate: coordinate)
        }
    }

    func embedding(for spot: Spot) async throws -> [Float]? {
        guard let key = configuration.openAIKey, !key.isEmpty else {
            return nil
        }
        return try await jobQueue.enqueue { [configuration] in
            let description = [spot.title, spot.details, spot.tags.joined(separator: ", ")].joined(separator: "\n")
            return description.hashEmbedding(dimension: configuration.embeddingDimension)
        }
    }

    private func performRemoteInference(media: [MediaItem], title: String, coordinate: CLLocationCoordinate2D?) async throws -> AIMetadataResult {
        return try await jobQueue.enqueue {
            let tags = media.flatMap { $0.exifTags }
            let locationTags: [String]
            if let coordinate = coordinate {
                locationTags = ["lat: \(coordinate.latitude)", "lng: \(coordinate.longitude)"]
            } else {
                locationTags = []
            }
            let combined = Array(Set(tags + locationTags)).sorted()
            return AIMetadataResult(title: title.isEmpty ? media.first?.suggestedTitle ?? "New Spot" : title,
                                     details: media.first?.metadataSummary ?? "",
                                     tags: combined)
        }
    }

    private func heuristics(media: [MediaItem], title: String, coordinate: CLLocationCoordinate2D?) -> AIMetadataResult {
        var tags = media.flatMap { $0.exifTags }
        if let coordinate = coordinate {
            tags.append(String(format: "lat: %.4f", coordinate.latitude))
            tags.append(String(format: "lng: %.4f", coordinate.longitude))
        }
        let inferredTitle = title.isEmpty ? media.first?.suggestedTitle ?? "Untitled" : title
        return AIMetadataResult(title: inferredTitle,
                                details: media.first?.metadataSummary ?? "",
                                tags: Array(Set(tags)))
    }
}

private extension String {
    func hashEmbedding(dimension: Int) -> [Float] {
        let scalars = unicodeScalars.map { Float($0.value) }
        var vector = Array(repeating: Float(0), count: dimension)
        for (index, scalar) in scalars.enumerated() {
            vector[index % dimension] += scalar / Float(dimension)
        }
        return vector
    }
}
