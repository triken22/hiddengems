import Foundation
import CoreData
import Combine

actor GroupRepository {
    private let context: NSManagedObjectContext
    nonisolated private let subject = CurrentValueSubject<[Group], Never>([])

    init(context: NSManagedObjectContext) {
        self.context = context
        Task { await loadInitialGroups() }
    }

    private func loadInitialGroups() async {
        let request: NSFetchRequest<GroupEntity> = GroupEntity.fetchRequest()
        do {
            let groups = try context.fetch(request)
            subject.send(groups.map(Group.init(entity:)))
        } catch {
            subject.send([])
        }
    }

    nonisolated func groupsPublisher() -> AnyPublisher<[Group], Never> {
        subject.eraseToAnyPublisher()
    }

    func createGroup(name: String) async throws {
        try await context.perform {
            let entity = GroupEntity(context: self.context)
            let inviteCode = String(UUID().uuidString.prefix(6)).uppercased()
            let group = Group(id: UUID().uuidString,
                              name: name,
                              inviteCode: inviteCode,
                              memberCount: 1,
                              deleted: false,
                              version: 0,
                              createdAt: Date(),
                              updatedAt: Date())
            entity.update(from: group)
            try self.context.save()
            self.subject.send(self.subject.value + [group])
        }
    }

    func joinGroup(inviteCode: String) async throws {
        try await context.perform {
            let request: NSFetchRequest<GroupEntity> = GroupEntity.fetchRequest()
            request.predicate = NSPredicate(format: "inviteCode ==[c] %@", inviteCode)
            guard let entity = try self.context.fetch(request).first else {
                throw NSError(domain: "GroupRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Group not found"])
            }
            entity.memberCount += 1
            entity.updatedAt = Date()
            try self.context.save()
            let group = Group(entity: entity)
            var current = self.subject.value.filter { $0.id != group.id }
            current.append(group)
            self.subject.send(current)
        }
    }
}
