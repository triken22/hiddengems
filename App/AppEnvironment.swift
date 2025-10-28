import Foundation
import CoreData
import Combine

@MainActor
final class AppEnvironment: ObservableObject {
    let persistenceController: PersistenceController
    let locationService: LocationService
    let mediaService: MediaService
    let aiService: HybridAIService
    let vectorStore: VectorStore
    let syncCoordinator: SyncCoordinator
    let configuration: AppConfiguration

    private let homeVM: HomeViewModel
    private let groupListVM: GroupListViewModel

    static func live() -> AppEnvironment {
        let configuration = AppConfiguration()
        let persistenceController = PersistenceController(modelName: "HiddenGems")
        let locationService = DefaultLocationService()
        let mediaService = DefaultMediaService()
        let vectorStore = try! SQLiteVectorStore(location: .defaultStore)
        let aiService = HybridAIService(configuration: configuration.aiConfiguration)
        let syncService = DefaultSyncService(configuration: configuration.syncConfiguration)
        let syncCoordinator = SyncCoordinator(syncService: syncService,
                                              persistenceController: persistenceController)

        let spotRepository = SpotRepository(context: persistenceController.container.viewContext,
                                            vectorStore: vectorStore,
                                            aiService: aiService)
        let groupRepository = GroupRepository(context: persistenceController.container.viewContext)

        let homeVM = HomeViewModel(spots: spotRepository,
                                   groups: groupRepository,
                                   locationService: locationService,
                                   syncCoordinator: syncCoordinator,
                                   mediaService: mediaService,
                                   aiService: aiService)
        let groupListVM = GroupListViewModel(groupRepository: groupRepository,
                                             syncCoordinator: syncCoordinator)

        let environment = AppEnvironment(persistenceController: persistenceController,
                                         locationService: locationService,
                                         mediaService: mediaService,
                                         aiService: aiService,
                                         vectorStore: vectorStore,
                                         syncCoordinator: syncCoordinator,
                                         configuration: configuration,
                                         homeVM: homeVM,
                                         groupListVM: groupListVM)
        return environment
    }

    init(persistenceController: PersistenceController,
         locationService: LocationService,
         mediaService: MediaService,
         aiService: HybridAIService,
         vectorStore: VectorStore,
         syncCoordinator: SyncCoordinator,
         configuration: AppConfiguration,
         homeVM: HomeViewModel,
         groupListVM: GroupListViewModel) {
        self.persistenceController = persistenceController
        self.locationService = locationService
        self.mediaService = mediaService
        self.aiService = aiService
        self.vectorStore = vectorStore
        self.syncCoordinator = syncCoordinator
        self.configuration = configuration
        self.homeVM = homeVM
        self.groupListVM = groupListVM
    }

    func homeViewModel() -> HomeViewModel { homeVM }
    func groupListViewModel() -> GroupListViewModel { groupListVM }
}

struct AppConfiguration {
    let apiBaseURL: URL
    let syncToken: String
    let aiConfiguration: HybridAIConfiguration
    let syncConfiguration: SyncConfiguration

    init(bundle: Bundle = .main) {
        let apiBaseURL = (bundle.object(forInfoDictionaryKey: "API_BASE_URL") as? String).flatMap(URL.init) ?? URL(string: "https://example.com")!
        let syncToken = bundle.object(forInfoDictionaryKey: "APP_SYNC_TOKEN") as? String ?? ""
        self.apiBaseURL = apiBaseURL
        self.syncToken = syncToken
        self.aiConfiguration = HybridAIConfiguration(openAIKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"],
                                                     groqKey: ProcessInfo.processInfo.environment["GROQ_API_KEY"],
                                                     embeddingDimension: 1536)
        self.syncConfiguration = SyncConfiguration(baseURL: apiBaseURL, bearerToken: syncToken)
    }
}
