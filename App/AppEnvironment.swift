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
    let gemDrawer: GemDrawerController

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
        
        // Load repository data explicitly after initialization
        Task {
            await spotRepository.load()
            await groupRepository.load()
        }
        
        // Load configuration from Info.plist with production defaults
        let bundle = Bundle.main
        let apiBaseURLString = (bundle.object(forInfoDictionaryKey: "API_BASE_URL") as? String) ?? "https://api.hiddengems.app"
        let syncToken = (bundle.object(forInfoDictionaryKey: "APP_SYNC_TOKEN") as? String) ?? ""
        
        guard let baseURL = URL(string: apiBaseURLString), !apiBaseURLString.isEmpty else {
            print("ERROR: Invalid or missing API_BASE_URL in Info.plist. Using fallback.")
            let fallbackURL = URL(string: "https://api.hiddengems.app")!
            let syncConfig = SyncConfiguration(baseURL: fallbackURL, bearerToken: syncToken)
            let syncService = DefaultSyncService(configuration: syncConfig)
            self.syncCoordinator = SyncCoordinator(syncService: syncService, persistenceController: persistenceController)
            
            self.groupListViewModel = GroupListViewModel(groupRepository: groupRepository, syncCoordinator: syncCoordinator)
            self.settingsViewModel = SettingsViewModel()
            self.gemDrawer = GemDrawerController()
            
            self.homeViewModel = HomeViewModel(spotRepository: spotRepository,
                                             groupRepository: groupRepository,
                                             locationService: locationService,
                                             syncCoordinator: syncCoordinator,
                                             mediaService: mediaService,
                                             aiService: aiService,
                                             groupListViewModel: groupListViewModel,
                                             settingsViewModel: settingsViewModel)
            return
        }
        
        if syncToken.isEmpty {
            print("WARNING: APP_SYNC_TOKEN is empty. Sync may fail without authentication.")
        }
        
        let syncConfig = SyncConfiguration(baseURL: baseURL, bearerToken: syncToken)
        let syncService = DefaultSyncService(configuration: syncConfig)
        self.syncCoordinator = SyncCoordinator(syncService: syncService, persistenceController: persistenceController)
        
        self.groupListViewModel = GroupListViewModel(groupRepository: groupRepository, syncCoordinator: syncCoordinator)
        self.settingsViewModel = SettingsViewModel()
        self.gemDrawer = GemDrawerController()
        
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
