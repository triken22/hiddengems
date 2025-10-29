import Foundation
import MapKit
import CoreLocation

@MainActor
final class HomeViewModel: ObservableObject {
    enum Tab {
        case map
        case groups
        case settings
    }
    
    @Published var spots: [Spot] = []
    @Published var mapSpots: [Spot] = []
    @Published var selectedSpot: Spot?
    @Published var selectedTab: Tab = .map
    @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    @Published var isQuickAddPresented = false

    let groupListViewModel: GroupListViewModel
    let settingsViewModel: SettingsViewModel

    let spotRepository: SpotRepository
    let groupRepository: GroupRepository

    private let locationService: LocationService
    private let syncCoordinator: SyncCoordinator
    private let mediaService: MediaService
    private let aiService: HybridAIService

    init(spotRepository: SpotRepository,
         groupRepository: GroupRepository,
         locationService: LocationService,
         syncCoordinator: SyncCoordinator,
         mediaService: MediaService,
         aiService: HybridAIService,
         groupListViewModel: GroupListViewModel,
         settingsViewModel: SettingsViewModel) {
        self.spotRepository = spotRepository
        self.groupRepository = groupRepository
        self.locationService = locationService
        self.syncCoordinator = syncCoordinator
        self.mediaService = mediaService
        self.aiService = aiService
        self.groupListViewModel = groupListViewModel
        self.settingsViewModel = settingsViewModel

        Task {
            await loadSpots()
        }
    }

    func loadSpots() async {
        let spots = await spotRepository.fetchAll()
        await MainActor.run {
            self.spots = spots
            self.mapSpots = spots.filter { !$0.deleted }
        }
    }

    func centerOnUser() async {
        if let location = await locationService.currentLocation() {
            region = MKCoordinateRegion(center: location.coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.05,
                                                             longitudeDelta: 0.05))
        }
    }

    func selectSpot(_ spot: Spot) {
        selectedSpot = spot
    }

    func deleteSpot(_ spot: Spot) async {
        do {
            try await spotRepository.delete(id: spot.id)
            await loadSpots()
        } catch {
            print("Error deleting spot: \(error)")
        }
    }
    
    func openQuickAdd() {
        isQuickAddPresented = true
    }
    
    func quickAddViewModel() -> QuickAddViewModel {
        QuickAddViewModel(spotRepository: spotRepository,
                         mediaService: mediaService,
                         aiService: aiService,
                         locationService: locationService)
    }
    
    func onAppear() {
        Task {
            await loadSpots()
        }
    }
}
