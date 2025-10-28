import Foundation
import CoreData
import Combine
import CoreLocation

actor SpotRepository {
    private let context: NSManagedObjectContext
    private let vectorStore: VectorStore
    private let aiService: HybridAIService

    nonisolated private let subject = CurrentValueSubject<[Spot], Never>([])

    init(context: NSManagedObjectContext, vectorStore: VectorStore, aiService: HybridAIService) {
        self.context = context
        self.vectorStore = vectorStore
        self.aiService = aiService
        Task { await loadInitialSpots() }
    }

    private func loadInitialSpots() async {
        let request: NSFetchRequest<SpotEntity> = SpotEntity.fetchRequest()
        request.predicate = NSPredicate(format: "deleted == NO")
        do {
            let entities = try context.fetch(request)
            subject.send(entities.map(Spot.init(entity:)))
        } catch {
            subject.send([])
        }
    }

    nonisolated func spotsPublisher() -> AnyPublisher<[Spot], Never> {
        subject.eraseToAnyPublisher()
    }

    func save(spot: Spot) async throws {
        try await context.perform {
            let fetch: NSFetchRequest<SpotEntity> = SpotEntity.fetchRequest()
            fetch.predicate = NSPredicate(format: "id == %@", spot.id)
            let entity = try self.context.fetch(fetch).first ?? SpotEntity(context: self.context)
            entity.update(from: spot, context: self.context)
            try self.context.save()
            self.subject.send((self.subject.value.filter { $0.id != spot.id } + [spot]).sorted { $0.updatedAt > $1.updatedAt })
        }
        if let embedding = try await aiService.embedding(for: spot) {
            try vectorStore.upsert(embedding: embedding, for: spot.id)
        }
    }

    func delete(id: String) async throws {
        try await context.perform {
            let fetch: NSFetchRequest<SpotEntity> = SpotEntity.fetchRequest()
            fetch.predicate = NSPredicate(format: "id == %@", id)
            guard let entity = try self.context.fetch(fetch).first else { return }
            entity.deleted = true
            entity.updatedAt = Date()
            try self.context.save()
            self.subject.send(self.subject.value.filter { $0.id != id })
        }
    }

    func semanticSearch(vector: [Float], topK: Int) throws -> [Spot] {
        let identifiers = try vectorStore.searchSimilar(to: vector, topK: topK)
        return subject.value.filter { identifiers.contains($0.id) }
    }
}
