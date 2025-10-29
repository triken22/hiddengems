import Foundation
import MapKit
import CoreLocation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    enum Tab {
        case map
        case groups
        case settings
    }
    
    @Published var spots: [Spot] = []
    @Published var mapSpots: [Spot] = []
    @Published var filteredSpots: [Spot] = []
    @Published var selectedSpot: Spot?
    @Published var selectedTab: Tab = .map
    @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    @Published var isQuickAddPresented = false
    @Published var searchText = ""
    @Published var selectedCategory: String? = nil
    @Published var isLoading = false
    @Published var currentLocation: CLLocation?

    let groupListViewModel: GroupListViewModel
    let settingsViewModel: SettingsViewModel

    let spotRepository: SpotRepository
    let groupRepository: GroupRepository

    private let locationService: LocationService
    private let syncCoordinator: SyncCoordinator
    private let mediaService: MediaService
    private let aiService: HybridAIService
    private var cancellables = Set<AnyCancellable>()

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

        // Subscribe to spot repository updates for instant reactivity
        spotRepository.spotsPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedSpots in
                guard let self = self else { return }
                self.spots = updatedSpots
                self.mapSpots = updatedSpots.filter { !$0.deleted }
                self.filterSpots()
            }
            .store(in: &cancellables)

        Task {
            await loadSpots()
            await updateCurrentLocation()
        }
    }

    func loadSpots() async {
        isLoading = true
        let spots = await spotRepository.fetchAll()
        await MainActor.run {
            self.spots = spots
            self.mapSpots = spots.filter { !$0.deleted }
            self.filteredSpots = spots.filter { !$0.deleted }
            self.isLoading = false
        }
    }
    
    func filterSpots() {
        var filtered = spots.filter { !$0.deleted }
        
        // Filter by search text with enhanced search
        if !searchText.isEmpty {
            let searchTerms = searchText.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
            
            filtered = filtered.filter { spot in
                let searchableText = [
                    spot.title,
                    spot.subtitle ?? "",
                    spot.details,
                    spot.tags.joined(separator: " "),
                    spot.topics.joined(separator: " ")
                ].joined(separator: " ").lowercased()
                
                // Check if all search terms are found in the searchable text
                return searchTerms.allSatisfy { term in
                    searchableText.contains(term)
                }
            }
        }
        
        // Filter by category
        if let category = selectedCategory, category != "All" {
            filtered = filtered.filter { spot in
                spot.tags.contains { $0.localizedCaseInsensitiveContains(category) } ||
                spot.topics.contains { $0.localizedCaseInsensitiveContains(category) }
            }
        }
        
        // Sort by relevance (exact matches first, then partial matches)
        if !searchText.isEmpty {
            filtered = filtered.sorted { spot1, spot2 in
                let score1 = calculateRelevanceScore(spot: spot1, searchText: searchText)
                let score2 = calculateRelevanceScore(spot: spot2, searchText: searchText)
                return score1 > score2
            }
        }
        
        filteredSpots = filtered
    }
    
    private func calculateRelevanceScore(spot: Spot, searchText: String) -> Int {
        let searchableText = [
            spot.title,
            spot.subtitle ?? "",
            spot.details,
            spot.tags.joined(separator: " "),
            spot.topics.joined(separator: " ")
        ].joined(separator: " ").lowercased()
        
        let searchLower = searchText.lowercased()
        var score = 0
        
        // Exact title match gets highest score
        if spot.title.lowercased().contains(searchLower) {
            score += 100
        }
        
        // Subtitle match
        if let subtitle = spot.subtitle, subtitle.lowercased().contains(searchLower) {
            score += 50
        }
        
        // Tag matches
        for tag in spot.tags {
            if tag.lowercased().contains(searchLower) {
                score += 30
            }
        }
        
        // Topic matches
        for topic in spot.topics {
            if topic.lowercased().contains(searchLower) {
                score += 20
            }
        }
        
        // Details match
        if spot.details.lowercased().contains(searchLower) {
            score += 10
        }
        
        return score
    }
    
    func updateSearchText(_ text: String) {
        searchText = text
        filterSpots()
    }
    
    func updateSelectedCategory(_ category: String?) {
        selectedCategory = category
        filterSpots()
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
    
    func createSpotViewModel(initialLocation: CLLocationCoordinate2D? = nil) -> CreateSpotViewModel {
        CreateSpotViewModel(
            spotRepository: spotRepository,
            mediaService: mediaService,
            aiService: aiService,
            locationService: locationService,
            initialLocation: initialLocation
        )
    }
    
    func onAppear() {
        Task {
            await loadSpots()
            await updateCurrentLocation()
        }
    }
    
    // MARK: - Distance Computation
    
    private func updateCurrentLocation() async {
        if let location = await locationService.currentLocation() {
            await MainActor.run {
                self.currentLocation = location
                self.updateDistances()
            }
        }
    }
    
    private func updateDistances() {
        guard let currentLocation = currentLocation else { return }
        
        // Update distances for all spots
        for i in 0..<spots.count {
            let spot = spots[i]
            let spotLocation = CLLocation(latitude: spot.coordinate.latitude, longitude: spot.coordinate.longitude)
            let distance = currentLocation.distance(from: spotLocation)
            spots[i].distanceMeters = distance
        }
        
        // Update distances for map spots
        for i in 0..<mapSpots.count {
            let spot = mapSpots[i]
            let spotLocation = CLLocation(latitude: spot.coordinate.latitude, longitude: spot.coordinate.longitude)
            let distance = currentLocation.distance(from: spotLocation)
            mapSpots[i].distanceMeters = distance
        }
        
        // Update distances for filtered spots
        for i in 0..<filteredSpots.count {
            let spot = filteredSpots[i]
            let spotLocation = CLLocation(latitude: spot.coordinate.latitude, longitude: spot.coordinate.longitude)
            let distance = currentLocation.distance(from: spotLocation)
            filteredSpots[i].distanceMeters = distance
        }
    }
    
    func refreshLocation() async {
        await updateCurrentLocation()
    }
}
