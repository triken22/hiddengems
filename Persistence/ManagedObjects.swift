import Foundation
import CoreData

@objc(SpotEntity)
final class SpotEntity: NSManagedObject {
    @NSManaged var id: String?
    @NSManaged var title: String?
    @NSManaged var subtitle: String?
    @NSManaged var details: String?
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var address: String?
    @NSManaged var tags: Data?
    @NSManaged var topics: Data?
    @NSManaged var images: Data?
    @NSManaged var groupId: String?
    @NSManaged var userId: String?
    @NSManaged var deleted: Bool
    @NSManaged var version: Int64
    @NSManaged var createdAt: Date?
    @NSManaged var updatedAt: Date?
}

extension SpotEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<SpotEntity> {
        return NSFetchRequest<SpotEntity>(entityName: "SpotEntity")
    }
}

@objc(GroupEntity)
final class GroupEntity: NSManagedObject {
    @NSManaged var id: String?
    @NSManaged var name: String?
    @NSManaged var inviteCode: String?
    @NSManaged var memberCount: Int32
    @NSManaged var deleted: Bool
    @NSManaged var version: Int64
    @NSManaged var createdAt: Date?
    @NSManaged var updatedAt: Date?
}

extension GroupEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<GroupEntity> {
        return NSFetchRequest<GroupEntity>(entityName: "GroupEntity")
    }
}

@objc(SettingEntity)
final class SettingEntity: NSManagedObject {
    @NSManaged var id: String?
    @NSManaged var value: Data?
}

extension SettingEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<SettingEntity> {
        return NSFetchRequest<SettingEntity>(entityName: "SettingEntity")
    }
}
