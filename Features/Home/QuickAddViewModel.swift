import Foundation
import CoreLocation
import PhotosUI

@MainActor
final class QuickAddViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var details: String = ""
    @Published var selectedAssets: [String] = []
    @Published var selectedLocation: CLLocationCoordinate2D?
    @Published var suggestedTags: [String] = []
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let spotRepository: SpotRepository
    private let mediaService: MediaService
    private let aiService: HybridAIService
    private let locationService: LocationService

    init(spotRepository: SpotRepository,
         mediaService: MediaService,
         aiService: HybridAIService,
         locationService: LocationService) {
        self.spotRepository = spotRepository
        self.mediaService = mediaService
        self.aiService = aiService
        self.locationService = locationService
        Task { await bootstrap() }
    }

    private func bootstrap() async {
        if selectedLocation == nil, let location = await locationService.currentLocation() {
            selectedLocation = location.coordinate
        }
    }

    func analyzeMediaIfNeeded() async {
        guard !selectedAssets.isEmpty else { return }
        do {
            let media = try await mediaService.loadMediaItems()
            let result = try await aiService.suggestMetadata(for: media,
                                                             title: title,
                                                             coordinate: selectedLocation)
            await MainActor.run {
                if title.isEmpty { title = result.title }
                details = result.details
                suggestedTags = result.tags
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save() async {
        guard let coordinate = selectedLocation else {
            errorMessage = "Location required"
            return
        }

        isSaving = true
        do {
            let spot = Spot(id: UUID().uuidString,
                            title: title,
                            subtitle: nil,
                            details: details,
                            coordinate: coordinate,
                            address: nil,
                            tags: suggestedTags,
                            topics: [],
                            images: [],
                            groupId: nil,
                            userId: nil,
                            deleted: false,
                            version: 0,
                            createdAt: Date(),
                            updatedAt: Date())
            try await spotRepository.save(spot: spot)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
