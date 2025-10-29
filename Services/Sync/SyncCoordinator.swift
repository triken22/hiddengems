import Foundation
import CoreData

@MainActor
final class SyncCoordinator: ObservableObject {
    private let syncService: SyncService
    private let persistenceController: PersistenceController
    private var isPerforming = false

    init(syncService: SyncService, persistenceController: PersistenceController) {
        self.syncService = syncService
        self.persistenceController = persistenceController
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(triggerManualSync),
                                               name: .manualSyncRequested,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func triggerManualSync() {
        Task { await performInitialSync() }
    }

    func performInitialSync() async {
        guard !isPerforming else { return }
        isPerforming = true
        defer { isPerforming = false }

        await pushChanges()
        await pullChanges()
    }

    func pushChanges() async {
        // Use background context for sync operations to avoid blocking UI
        let backgroundContext = persistenceController.container.newBackgroundContext()
        
        let spots = await backgroundContext.perform {
            let spots = self.fetchEntities(context: backgroundContext, fetchRequest: SpotEntity.fetchRequest())
                .map(Spot.init(entity:))
            return spots
        }
        
        let groups = await backgroundContext.perform {
            let groups = self.fetchEntities(context: backgroundContext, fetchRequest: GroupEntity.fetchRequest())
                .map(Group.init(entity:))
            return groups
        }
        
        do {
            try await syncService.push(spots: spots, groups: groups)
        } catch {
            print("Sync push failed: \(error)")
        }
    }

    func pullChanges() async {
        do {
            let latestVersion = await getLatestVersionNumber()
            let payload = try await syncService.pull(since: latestVersion)
            await mergePayload(payload)
        } catch {
            print("Sync pull failed: \(error)")
        }
    }

    private func getLatestVersionNumber() async -> Int {
        let backgroundContext = persistenceController.container.newBackgroundContext()
        
        return await backgroundContext.perform {
            let spotRequest: NSFetchRequest<SpotEntity> = SpotEntity.fetchRequest()
            spotRequest.sortDescriptors = [NSSortDescriptor(key: "version", ascending: false)]
            spotRequest.fetchLimit = 1
            let groupRequest: NSFetchRequest<GroupEntity> = GroupEntity.fetchRequest()
            groupRequest.sortDescriptors = [NSSortDescriptor(key: "version", ascending: false)]
            groupRequest.fetchLimit = 1
            let spotVersion = (try? backgroundContext.fetch(spotRequest).first?.version).map(Int.init) ?? 0
            let groupVersion = (try? backgroundContext.fetch(groupRequest).first?.version).map(Int.init) ?? 0
            return max(spotVersion, groupVersion)
        }
    }

    private func mergePayload(_ payload: SyncPayload) async {
        // Use background context for merging to avoid blocking main thread
        let backgroundContext = persistenceController.container.newBackgroundContext()
        
        await backgroundContext.perform {
            for dto in payload.spots {
                let fetch: NSFetchRequest<SpotEntity> = SpotEntity.fetchRequest()
                fetch.predicate = NSPredicate(format: "id == %@", dto.id)
                let entity = (try? backgroundContext.fetch(fetch).first) ?? SpotEntity(context: backgroundContext)
                let spot = dto.model
                entity.update(from: spot, context: backgroundContext)
            }
            for dto in payload.groups {
                let fetch: NSFetchRequest<GroupEntity> = GroupEntity.fetchRequest()
                fetch.predicate = NSPredicate(format: "id == %@", dto.id)
                let entity = (try? backgroundContext.fetch(fetch).first) ?? GroupEntity(context: backgroundContext)
                entity.update(from: dto.model)
            }
            if backgroundContext.hasChanges {
                do {
                    try backgroundContext.save()
                } catch {
                    print("Failed to save sync merge: \(error)")
                }
            }
        }
    }

    private func fetchEntities<Entity: NSManagedObject>(context: NSManagedObjectContext,
                                                         fetchRequest: NSFetchRequest<Entity>) -> [Entity] {
        (try? context.fetch(fetchRequest)) ?? []
    }
}

private extension SpotDTO {
    var model: Spot {
        Spot(id: id,
             title: title,
             subtitle: nil,
             details: details,
             coordinate: .init(latitude: latitude, longitude: longitude),
             address: nil,
             tags: tags,
             topics: topics,
             images: imageRemoteURLs.map { SpotImage(id: UUID(), localIdentifier: nil, remoteURL: $0) },
             groupId: groupId,
             userId: userId,
             deleted: deleted,
             version: version,
             createdAt: createdAt,
             updatedAt: updatedAt)
    }
}

private extension GroupDTO {
    var model: Group {
        Group(id: id,
              name: name,
              inviteCode: inviteCode,
              memberCount: memberCount,
              deleted: deleted,
              version: version,
              createdAt: createdAt,
              updatedAt: updatedAt)
    }
}
