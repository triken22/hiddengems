import CoreData

final class PersistenceController {
    static let shared = PersistenceController(inMemory: false, modelName: "HiddenGems")
    static let preview = PersistenceController(inMemory: true, modelName: "HiddenGems")
    
    let container: NSPersistentContainer

    init(inMemory: Bool = false, modelName: String) {
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            // Log critical error for debugging
            print("CRITICAL: Missing Core Data model '\(modelName)'. App cannot function.")
            // Attempt to use default name as fallback
            if let fallbackModel = NSManagedObjectModel.mergedModel(from: [Bundle.main]) {
                container = NSPersistentContainer(name: modelName, managedObjectModel: fallbackModel)
            } else {
                // Last resort: create minimal container (will fail to load stores)
                fatalError("Missing Core Data model '\(modelName)' and no fallback available")
            }
            return
        }
        container = NSPersistentContainer(name: modelName, managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.persistentStoreDescriptions.forEach { description in
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            // Enable lightweight migration
            description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        }

        var storeLoadError: Error?
        container.loadPersistentStores { description, error in
            if let error = error {
                print("CRITICAL: Failed to load persistent store at \(description.url?.path ?? "unknown"): \(error)")
                storeLoadError = error
                
                // Attempt recovery: delete corrupted store and retry
                if let storeURL = description.url {
                    do {
                        try FileManager.default.removeItem(at: storeURL)
                        print("Deleted corrupted store, attempting to recreate...")
                        
                        // Try loading again after deletion
                        self.container.loadPersistentStores { _, retryError in
                            if let retryError = retryError {
                                print("CRITICAL: Recovery failed: \(retryError)")
                                storeLoadError = retryError
                            } else {
                                print("Successfully recovered by recreating store")
                                storeLoadError = nil
                            }
                        }
                    } catch {
                        print("Failed to delete corrupted store: \(error)")
                    }
                }
            }
        }
        
        // If still failed after recovery attempt, this is unrecoverable
        if let error = storeLoadError {
            fatalError("Unresolved persistent store error after recovery attempt: \(error)")
        }
        
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Run placeholder cleanup on first launch
        cleanupPlaceholderData()
    }
    
    private func cleanupPlaceholderData() {
        let context = container.viewContext
        let request: NSFetchRequest<SpotEntity> = SpotEntity.fetchRequest()
        
        // Find placeholder spots based on heuristics
        let placeholderPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "title == %@ OR title == %@ OR title == %@", "Untitled", "New Spot", ""),
            NSPredicate(format: "title == %@ AND details == %@ AND images == nil", "Untitled", ""),
            NSPredicate(format: "title == %@ AND details == %@ AND images == nil", "New Spot", "")
        ])
        
        // Only clean up spots created before a cutoff date (e.g., 1 week ago)
        let cutoffDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        let datePredicate = NSPredicate(format: "createdAt < %@", cutoffDate as NSDate)
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            placeholderPredicate,
            datePredicate,
            NSPredicate(format: "isMarkedDeleted == NO")
        ])
        
        do {
            let placeholderSpots = try context.fetch(request)
            if !placeholderSpots.isEmpty {
                print("Cleaning up \(placeholderSpots.count) placeholder spots")
                for spot in placeholderSpots {
                    spot.isMarkedDeleted = true
                    spot.updatedAt = Date()
                }
                try context.save()
                print("Successfully cleaned up placeholder data")
            }
        } catch {
            print("Failed to cleanup placeholder data: \(error)")
        }
    }
}
