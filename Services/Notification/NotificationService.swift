import Foundation
import SwiftUI

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    
    private init() {}
    
    func addNotification(title: String, message: String, type: AppNotification.NotificationType = .info) {
        let notification = AppNotification(
            id: UUID().uuidString,
            title: title,
            message: message,
            type: type,
            timestamp: Date(),
            isRead: false
        )
        
        DispatchQueue.main.async {
            self.notifications.insert(notification, at: 0)
            self.unreadCount += 1
        }
    }
    
    func markAsRead(_ id: String) {
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            notifications[index].isRead = true
            unreadCount = notifications.filter { !$0.isRead }.count
        }
    }
    
    func markAllAsRead() {
        notifications = notifications.map { var n = $0; n.isRead = true; return n }
        unreadCount = 0
    }
    
    func clearAll() {
        notifications.removeAll()
        unreadCount = 0
    }
}

struct AppNotification: Identifiable {
    let id: String
    let title: String
    let message: String
    let type: NotificationType
    let timestamp: Date
    var isRead: Bool
    
    enum NotificationType {
        case success
        case error
        case info
        case warning
    }
}

