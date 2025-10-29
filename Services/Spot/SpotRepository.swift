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
    }
    
    func load() async {
        await loadInitialSpots()
    }

    private func loadInitialSpots() async {
        let request: NSFetchRequest<SpotEntity> = SpotEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isMarkedDeleted == NO")
        
        await context.perform {
            do {
                let entities = try self.context.fetch(request)
                let spots = entities.map(Spot.init(entity:))
                self.subject.send(spots)
            } catch {
                print("Error loading initial spots: \(error)")
                self.subject.send([])
            }
        }
    }

    nonisolated func spotsPublisher() -> AnyPublisher<[Spot], Never> {
        subject.eraseToAnyPublisher()
    }

    func fetchAll() async -> [Spot] {
        let request: NSFetchRequest<SpotEntity> = SpotEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isMarkedDeleted == NO")
        
        return await context.perform {
            do {
                let entities = try self.context.fetch(request)
                return entities.map(Spot.init(entity:))
            } catch {
                print("Error fetching all spots: \(error)")
                return []
            }
        }
    }

    func save(spot: Spot) async throws {
        // Generate and persist embedding first to avoid publishing inconsistent state
        if let embedding = try await aiService.embedding(for: spot) {
            try vectorStore.upsert(embedding: embedding, for: spot.id)
        }
        
        try await context.perform {
            let fetch: NSFetchRequest<SpotEntity> = SpotEntity.fetchRequest()
            fetch.predicate = NSPredicate(format: "id == %@", spot.id)
            let entity = try self.context.fetch(fetch).first ?? SpotEntity(context: self.context)
            entity.update(from: spot, context: self.context)
            try self.context.save()
        }
        
        // Update publisher on main thread to ensure UI updates safely
        let updatedSpots = (subject.value.filter { $0.id != spot.id } + [spot]).sorted { $0.updatedAt > $1.updatedAt }
        subject.send(updatedSpots)
    }

    func delete(id: String) async throws {
        try await context.perform {
            let fetch: NSFetchRequest<SpotEntity> = SpotEntity.fetchRequest()
            fetch.predicate = NSPredicate(format: "id == %@", id)
            guard let entity = try self.context.fetch(fetch).first else { return }
            entity.isMarkedDeleted = true
            entity.updatedAt = Date()
            try self.context.save()
        }
        
        // Update publisher on main thread
        subject.send(subject.value.filter { $0.id != id })
    }

    func semanticSearch(vector: [Float], topK: Int) throws -> [Spot] {
        let identifiers = try vectorStore.searchSimilar(to: vector, topK: topK)
        return subject.value.filter { identifiers.contains($0.id) }
    }
    
    func updateRating(spotId: String, newRating: Double) async throws {
        try await context.perform {
            let fetch: NSFetchRequest<SpotEntity> = SpotEntity.fetchRequest()
            fetch.predicate = NSPredicate(format: "id == %@", spotId)
            guard let entity = try self.context.fetch(fetch).first else {
                throw NSError(domain: "SpotRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Spot not found"])
            }
            
            entity.globalRating = newRating
            entity.ratingUpdatedAt = Date()
            entity.updatedAt = Date()
            
            try self.context.save()
        }
        
        // Update the published spots on main thread
        let updatedSpots = subject.value.map { spot in
            if spot.id == spotId {
                return Spot(
                    id: spot.id,
                    title: spot.title,
                    subtitle: spot.subtitle,
                    details: spot.details,
                    coordinate: spot.coordinate,
                    address: spot.address,
                    tags: spot.tags,
                    topics: spot.topics,
                    images: spot.images,
                    groupId: spot.groupId,
                    userId: spot.userId,
                    deleted: spot.deleted,
                    saved: spot.saved,
                    version: spot.version,
                    globalRating: newRating,
                    ratingUpdatedAt: Date(),
                    createdAt: spot.createdAt,
                    updatedAt: Date()
                )
            }
            return spot
        }
        
        subject.send(updatedSpots)
    }
}
