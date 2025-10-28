import CoreData

extension Group {
    init(entity: GroupEntity) {
        self.id = entity.id ?? UUID().uuidString
        self.name = entity.name ?? "Group"
        self.inviteCode = entity.inviteCode ?? ""
        self.memberCount = Int(entity.memberCount)
        self.deleted = entity.deleted
        self.version = Int(entity.version)
        self.createdAt = entity.createdAt ?? Date()
        self.updatedAt = entity.updatedAt ?? Date()
    }
}

extension GroupEntity {
    func update(from group: Group) {
        id = group.id
        name = group.name
        inviteCode = group.inviteCode
        memberCount = Int32(group.memberCount)
        deleted = group.deleted
        version = Int64(group.version)
        createdAt = group.createdAt
        updatedAt = group.updatedAt
    }
}
