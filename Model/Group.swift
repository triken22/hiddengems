import Foundation

struct Group: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var inviteCode: String
    var memberCount: Int
    var deleted: Bool
    var version: Int
    var createdAt: Date
    var updatedAt: Date
}
