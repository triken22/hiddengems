import Foundation
import SwiftUI
import MapKit
import CoreLocation

/// View model for spot detail view
@MainActor
final class SpotDetailViewModel: ObservableObject {
    @Published var spot: Spot
    @Published var isSaved = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let spotRepository: SpotRepository
    
    init(spot: Spot, spotRepository: SpotRepository) {
        self.spot = spot
        self.spotRepository = spotRepository
    }
    
    func toggleSave() async {
        isLoading = true
        defer { isLoading = false }
        
        if isSaved {
            // Remove from saved
            // Implementation depends on how saved spots are stored
            isSaved = false
        } else {
            // Add to saved
            // Implementation depends on how saved spots are stored
            isSaved = true
        }
    }
    
    func shareSpot() {
        // Implementation for sharing spot
        let activityViewController = UIActivityViewController(
            activityItems: [spot.title, spot.details],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityViewController, animated: true)
        }
    }
    
    func reportSpot() {
        // Implementation for reporting spot
        errorMessage = "Report functionality coming soon"
    }
    
    func getDirections() {
        // Implementation for getting directions
        let coordinate = spot.coordinate
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = spot.title
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}

// MARK: - Preview
#if DEBUG
extension SpotDetailViewModel {
    static var preview: SpotDetailViewModel {
        let spot = Spot(
            id: "1",
            title: "Secret Garden Cafe",
            subtitle: "Hidden coffee shop with amazing views",
            details: "Tucked away in a quiet alley, this charming cafe offers the perfect escape from the city hustle.",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            address: "123 Hidden Lane, San Francisco, CA",
            tags: ["Coffee", "Garden", "Quiet"],
            topics: ["Food & Drink"],
            images: [],
            groupId: nil,
            userId: nil,
            deleted: false,
            version: 1,
            createdAt: Date(),
            updatedAt: Date()
        )
        let repository = AppEnvironment().homeViewModel.spotRepository
        
        return SpotDetailViewModel(spot: spot, spotRepository: repository)
    }
}
#endif
