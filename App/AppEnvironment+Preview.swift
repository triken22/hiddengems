import Foundation

extension AppEnvironment {
    static func preview() -> AppEnvironment {
        let configuration = AppConfiguration()
        let persistenceController = PersistenceController(inMemory: true, modelName: "HiddenGems")
        let locationService = PreviewLocationService()
        let mediaService = PreviewMediaService()
        let vectorStore = try! SQLiteVectorStore.inMemory()
        let aiService = HybridAIService(configuration: configuration.aiConfiguration)
        let syncService = PreviewSyncService()
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
        let groupVM = GroupListViewModel(groupRepository: groupRepository,
                                         syncCoordinator: syncCoordinator)

        return AppEnvironment(persistenceController: persistenceController,
                              locationService: locationService,
                              mediaService: mediaService,
                              aiService: aiService,
                              vectorStore: vectorStore,
                              syncCoordinator: syncCoordinator,
                              configuration: configuration,
                              homeVM: homeVM,
                              groupListVM: groupVM)
    }
}
