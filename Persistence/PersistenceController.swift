import CoreData

final class PersistenceController {
    static let shared = PersistenceController(inMemory: false, modelName: "HiddenGems")
    static let preview = PersistenceController(inMemory: true, modelName: "HiddenGems")
    
    let container: NSPersistentContainer

    init(inMemory: Bool = false, modelName: String) {
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Missing Core Data model")
        }
        container = NSPersistentContainer(name: modelName, managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.persistentStoreDescriptions.forEach { description in
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
