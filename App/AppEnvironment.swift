import Foundation
import CoreData

@MainActor
final class AppEnvironment {
    let spotRepository: SpotRepository
    let groupRepository: GroupRepository
    let locationService: LocationService
    let syncCoordinator: SyncCoordinator
    let mediaService: MediaService
    let aiService: HybridAIService
    let homeViewModel: HomeViewModel
    let groupListViewModel: GroupListViewModel
    let settingsViewModel: SettingsViewModel

    init() {
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext
        
        // Initialize vector store safely (no force-unwraps)
        let vectorStore: SQLiteVectorStore
        if let store = try? SQLiteVectorStore(location: .defaultStore) {
            vectorStore = store
        } else if let inMemory = try? SQLiteVectorStore.inMemory() {
            vectorStore = inMemory
        } else {
            // As a last resort, create a temp file store
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("vector_store.sqlite")
            vectorStore = (try? SQLiteVectorStore(location: .init(url: tempURL))) ?? {
                fatalError("Failed to initialize VectorStore")
            }()
        }
        let aiConfig = HybridAIConfiguration(openAIKey: nil, groqKey: nil, embeddingDimension: 1536)
        self.aiService = HybridAIService(configuration: aiConfig)
        
        self.spotRepository = SpotRepository(context: context, vectorStore: vectorStore, aiService: aiService)
        self.groupRepository = GroupRepository(context: context)
        self.locationService = DefaultLocationService()
        self.mediaService = DefaultMediaService()
        
        let syncConfig = SyncConfiguration(baseURL: URL(string: "https://localhost:8787")!, bearerToken: "debug-token")
        let syncService = DefaultSyncService(configuration: syncConfig)
        self.syncCoordinator = SyncCoordinator(syncService: syncService, persistenceController: persistenceController)
        
        self.groupListViewModel = GroupListViewModel(groupRepository: groupRepository, syncCoordinator: syncCoordinator)
        self.settingsViewModel = SettingsViewModel()
        
        self.homeViewModel = HomeViewModel(spotRepository: spotRepository,
                                         groupRepository: groupRepository,
                                         locationService: locationService,
                                         syncCoordinator: syncCoordinator,
                                         mediaService: mediaService,
                                         aiService: aiService,
                                         groupListViewModel: groupListViewModel,
                                         settingsViewModel: settingsViewModel)
    }
}
