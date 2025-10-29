import Foundation
import SwiftUI
import CoreLocation

/// View model for the spot creation flow
@MainActor
final class CreateSpotViewModel: ObservableObject {
    @Published var currentStep = 1
    @Published var selectedImages: [UIImage] = []
    @Published var title = ""
    @Published var subtitle = ""
    @Published var details = ""
    @Published var selectedLocation: CLLocationCoordinate2D?
    @Published var selectedTags: [String] = []
    @Published var selectedCategory = ""
    @Published var suggestedTags: [String] = []
    @Published var isSaving = false
    @Published var saveSuccess = false
    @Published var errorMessage: String?
    
    let totalSteps = 5
    
    private let spotRepository: SpotRepository
    private let mediaService: MediaService
    private let aiService: HybridAIService
    private let locationService: LocationService
    
    init(
        spotRepository: SpotRepository,
        mediaService: MediaService,
        aiService: HybridAIService,
        locationService: LocationService,
        initialLocation: CLLocationCoordinate2D? = nil
    ) {
        self.spotRepository = spotRepository
        self.mediaService = mediaService
        self.aiService = aiService
        self.locationService = locationService
        self.selectedLocation = initialLocation
    }
    
    var previewSpot: Spot? {
        guard let location = selectedLocation,
              !title.isEmpty,
              !details.isEmpty else {
            return nil
        }
        
        return Spot(
            id: UUID().uuidString,
            title: title,
            subtitle: subtitle.isEmpty ? nil : subtitle,
            details: details,
            coordinate: location,
            address: nil, // Would be populated from reverse geocoding
            tags: selectedTags,
            topics: [selectedCategory],
            images: selectedImages.map { image in
                SpotImage(
                    id: UUID(),
                    localIdentifier: nil,
                    remoteURL: nil, // Would be populated after upload
                    localImage: image // Store the actual UIImage for preview
                )
            },
            groupId: nil,
            userId: nil,
            deleted: false,
            version: 1,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    func nextStep() {
        guard currentStep < totalSteps else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep += 1
        }
        
        // Generate AI suggestions when moving to tags step
        if currentStep == 4 {
            generateAISuggestions()
        }
    }
    
    func previousStep() {
        guard currentStep > 1 else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep -= 1
        }
    }
    
    func generateAISuggestions() {
        Task {
            do {
                let suggestions = await aiService.generateTags(
                    title: title,
                    description: details,
                    category: selectedCategory
                )
                
                await MainActor.run {
                    self.suggestedTags = suggestions
                }
            } catch {
                // Fallback to default tags
                await MainActor.run {
                    self.suggestedTags = getDefaultTags(for: selectedCategory)
                }
            }
        }
    }
    
    private func getDefaultTags(for category: String) -> [String] {
        switch category.lowercased() {
        case "restaurants":
            return ["Food", "Dining", "Local", "Authentic", "Cozy", "Outdoor Seating"]
        case "parks":
            return ["Nature", "Outdoor", "Peaceful", "Family", "Walking", "Scenic"]
        case "museums":
            return ["Culture", "Art", "History", "Educational", "Quiet", "Architecture"]
        case "beaches":
            return ["Ocean", "Sand", "Sunset", "Relaxing", "Swimming", "Scenic"]
        case "mountains":
            return ["Hiking", "Nature", "Views", "Adventure", "Peaceful", "Challenging"]
        case "coffee":
            return ["Coffee", "Cozy", "Work", "Quiet", "Local", "Artisanal"]
        case "shopping":
            return ["Shopping", "Local", "Unique", "Boutique", "Fashion", "Gifts"]
        default:
            return ["Hidden Gem", "Local", "Unique", "Special", "Quiet", "Authentic"]
        }
    }
    
    func saveSpot() {
        guard let spot = previewSpot else {
            errorMessage = "Unable to create spot. Please check your information."
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        Task {
            do {
                // Upload images first
                var uploadedImages: [SpotImage] = []
                for image in selectedImages {
                    if let imageData = image.jpegData(compressionQuality: 0.8) {
                        // In a real app, you would upload to a server
                        // For now, we'll create a placeholder with the local image
                        let spotImage = SpotImage(
                            id: UUID(),
                            localIdentifier: nil,
                            remoteURL: nil, // Would be the uploaded URL
                            localImage: image // Keep the local image for now
                        )
                        uploadedImages.append(spotImage)
                    }
                }
                
                // Create the final spot with uploaded images
                let finalSpot = Spot(
                    id: spot.id,
                    title: spot.title,
                    subtitle: spot.subtitle,
                    details: spot.details,
                    coordinate: spot.coordinate,
                    address: spot.address,
                    tags: spot.tags,
                    topics: spot.topics,
                    images: uploadedImages,
                    groupId: spot.groupId,
                    userId: spot.userId,
                    deleted: spot.deleted,
                    version: spot.version,
                    createdAt: spot.createdAt,
                    updatedAt: spot.updatedAt
                )
                
                // Save to repository
                try await spotRepository.save(spot: finalSpot)
                
                await MainActor.run {
                    self.isSaving = false
                    self.saveSuccess = true // Trigger success state
                    
                    // Success - add haptic feedback
                    let successFeedback = UINotificationFeedbackGenerator()
                    successFeedback.notificationOccurred(.success)
                }
                
            } catch {
                await MainActor.run {
                    self.isSaving = false
                    self.errorMessage = "Failed to save spot: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func reset() {
        currentStep = 1
        selectedImages = []
        title = ""
        subtitle = ""
        details = ""
        selectedLocation = nil
        selectedTags = []
        selectedCategory = ""
        suggestedTags = []
        isSaving = false
        errorMessage = nil
    }
}

// MARK: - AI Service Extension
extension HybridAIService {
    func generateTags(title: String, description: String, category: String) async -> [String] {
        // This would call the actual AI service
        // For now, return a placeholder implementation
        return [
            "Hidden Gem",
            "Local Favorite",
            "Unique",
            "Special",
            "Authentic"
        ]
    }
}
