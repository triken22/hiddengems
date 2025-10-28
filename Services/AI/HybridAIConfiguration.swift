import Foundation

struct HybridAIConfiguration {
    let openAIKey: String?
    let groqKey: String?
    let embeddingDimension: Int
}

struct AIMetadataResult {
    let title: String
    let details: String
    let tags: [String]
}
