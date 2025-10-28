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
        let context = persistenceController.container.viewContext
        let spots = fetchEntities(context: context, fetchRequest: SpotEntity.fetchRequest())
            .map(Spot.init(entity:))
        let groups = fetchEntities(context: context, fetchRequest: GroupEntity.fetchRequest())
            .map(Group.init(entity:))
        do {
            try await syncService.push(spots: spots, groups: groups)
        } catch {
            print("Sync push failed: \(error)")
        }
    }

    func pullChanges() async {
        do {
            let latestVersion = latestVersionNumber()
            let payload = try await syncService.pull(since: latestVersion)
            merge(payload: payload)
        } catch {
            print("Sync pull failed: \(error)")
        }
    }

    private func latestVersionNumber() -> Int {
        let context = persistenceController.container.viewContext
        let spotRequest: NSFetchRequest<SpotEntity> = SpotEntity.fetchRequest()
        spotRequest.sortDescriptors = [NSSortDescriptor(key: "version", ascending: false)]
        spotRequest.fetchLimit = 1
        let groupRequest: NSFetchRequest<GroupEntity> = GroupEntity.fetchRequest()
        groupRequest.sortDescriptors = [NSSortDescriptor(key: "version", ascending: false)]
        groupRequest.fetchLimit = 1
        let spotVersion = (try? context.fetch(spotRequest).first?.version).map(Int.init) ?? 0
        let groupVersion = (try? context.fetch(groupRequest).first?.version).map(Int.init) ?? 0
        return max(spotVersion, groupVersion)
    }

    private func merge(payload: SyncPayload) {
        let context = persistenceController.container.viewContext
        context.performAndWait {
            for dto in payload.spots {
                let fetch: NSFetchRequest<SpotEntity> = SpotEntity.fetchRequest()
                fetch.predicate = NSPredicate(format: "id == %@", dto.id)
                let entity = (try? context.fetch(fetch).first) ?? SpotEntity(context: context)
                let spot = dto.model
                entity.update(from: spot, context: context)
            }
            for dto in payload.groups {
                let fetch: NSFetchRequest<GroupEntity> = GroupEntity.fetchRequest()
                fetch.predicate = NSPredicate(format: "id == %@", dto.id)
                let entity = (try? context.fetch(fetch).first) ?? GroupEntity(context: context)
                entity.update(from: dto.model)
            }
            if context.hasChanges {
                try? context.save()
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
