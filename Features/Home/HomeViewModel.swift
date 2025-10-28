import Foundation
import Combine
import MapKit

@MainActor
final class HomeViewModel: ObservableObject {
    enum Tab: Hashable { case map, groups, settings }

    @Published var selectedTab: Tab = .map
    @Published var mapSpots: [Spot] = []
    @Published var selectedSpot: Spot?
    @Published var cameraPosition: MapCameraPosition = .automatic
    @Published var isQuickAddPresented = false

    let groupListViewModel: GroupListViewModel
    let settingsViewModel: SettingsViewModel

    let spotRepository: SpotRepository
    let groupRepository: GroupRepository

    private let locationService: LocationService
    private let syncCoordinator: SyncCoordinator
    private let mediaService: MediaService
    private let aiService: HybridAIService

    private var cancellables: Set<AnyCancellable> = []

    init(spots: SpotRepository,
         groups: GroupRepository,
         locationService: LocationService,
         syncCoordinator: SyncCoordinator,
         mediaService: MediaService,
         aiService: HybridAIService) {
        self.spotRepository = spots
        self.groupRepository = groups
        self.locationService = locationService
        self.syncCoordinator = syncCoordinator
        self.mediaService = mediaService
        self.aiService = aiService
        self.groupListViewModel = GroupListViewModel(groupRepository: groups,
                                                     syncCoordinator: syncCoordinator)
        self.settingsViewModel = SettingsViewModel()
        observeSpots()
    }

    func onAppear() {
        Task {
            await syncCoordinator.performInitialSync()
        }
    }

    func observeSpots() {
        spotRepository.spotsPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] spots in
                self?.mapSpots = spots
            }
            .store(in: &cancellables)
    }

    func centerOnUser() async {
        if let location = await locationService.currentLocation() {
            cameraPosition = .region(MKCoordinateRegion(center: location.coordinate,
                                                        span: MKCoordinateSpan(latitudeDelta: 0.05,
                                                                                 longitudeDelta: 0.05)))
        }
    }

    func quickAddViewModel() -> QuickAddViewModel {
        QuickAddViewModel(spotRepository: spotRepository,
                          mediaService: mediaService,
                          aiService: aiService,
                          locationService: locationService)
    }

    func openQuickAdd() {
        isQuickAddPresented = true
    }

    func dismissQuickAdd() {
        isQuickAddPresented = false
    }
}
