import SwiftUI

/// Horizontal pager view for browsing gems in the drawer
struct GemDrawerPagerView: View {
    
    // MARK: - Properties
    
    let spots: [Spot]
    @Binding var selectedIndex: Int
    let onOpenFullDetails: (Spot) -> Void
    let onNavigate: (Spot) -> Void
    let onSave: (Spot) -> Void
    let onShare: (Spot) -> Void
    let onRate: (Spot, Double) -> Void
    
    @EnvironmentObject private var spotRepository: SpotRepository
    @State private var dragOffset: CGFloat = 0
    
    // MARK: - Constants
    
    private let pageWidth: CGFloat = UIScreen.main.bounds.width
    private let pageSpacing: CGFloat = 16
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: pageSpacing) {
                ForEach(Array(spots.enumerated()), id: \.element.id) { index, spot in
                    SpotDetailCompactView(
                        spot: spot,
                        onOpenFullDetails: {
                            onOpenFullDetails(spot)
                        },
                        onNavigate: {
                            onNavigate(spot)
                        },
                        onSave: {
                            onSave(spot)
                        },
                        onShare: {
                            onShare(spot)
                        },
                        onRate: { rating in
                            onRate(spot, rating)
                        }
                    )
                    .frame(width: pageWidth - pageSpacing * 2)
                    .scaleEffect(selectedIndex == index ? 1.0 : 0.95)
                    .opacity(selectedIndex == index ? 1.0 : 0.7)
                    .animation(.easeInOut(duration: 0.2), value: selectedIndex)
                }
            }
            .offset(x: -CGFloat(selectedIndex) * pageWidth + dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.x
                    }
                    .onEnded { value in
                        handleDragEnd(value, geometry: geometry)
                    }
            )
        }
        .clipped()
    }
    
    // MARK: - Private Methods
    
    private func handleDragEnd(_ value: DragGesture.Value, geometry: GeometryProxy) {
        let velocity = value.velocity.x
        let translation = value.translation.x
        let threshold: CGFloat = 50
        
        var newIndex = selectedIndex
        
        if abs(translation) > threshold || abs(velocity) > 500 {
            if translation > 0 && selectedIndex > 0 {
                // Swipe right - go to previous
                newIndex = selectedIndex - 1
            } else if translation < 0 && selectedIndex < spots.count - 1 {
                // Swipe left - go to next
                newIndex = selectedIndex + 1
            }
        }
        
        // Animate to new index
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedIndex = newIndex
            dragOffset = 0
        }
        
        // Haptic feedback for page change
        if newIndex != selectedIndex {
            let selectionFeedback = UISelectionFeedbackGenerator()
            selectionFeedback.selectionChanged()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct GemDrawerPagerView_Previews: PreviewProvider {
    @State static var selectedIndex = 0
    
    static var previews: some View {
        GemDrawerPagerView(
            spots: [
                Spot(
                    id: "1",
                    title: "Sunset Point",
                    subtitle: "Beautiful views",
                    details: "Great spot for sunset photography",
                    latitude: 37.7749,
                    longitude: -122.4194,
                    address: "123 Ocean View Drive",
                    tags: ["sunset", "photography"],
                    topics: ["nature"],
                    images: ["https://example.com/sunset.jpg"],
                    userId: "user1",
                    groupId: "group1",
                    isMarkedDeleted: false,
                    version: 1,
                    createdAt: Date(),
                    updatedAt: Date(),
                    globalRating: 4.5,
                    ratingUpdatedAt: Date(),
                    saved: false
                ),
                Spot(
                    id: "2",
                    title: "Mountain Trail",
                    subtitle: "Hiking spot",
                    details: "Scenic mountain trail with great views",
                    latitude: 37.7849,
                    longitude: -122.4094,
                    address: "456 Mountain Road",
                    tags: ["hiking", "nature"],
                    topics: ["outdoor"],
                    images: ["https://example.com/mountain.jpg"],
                    userId: "user2",
                    groupId: "group2",
                    isMarkedDeleted: false,
                    version: 1,
                    createdAt: Date(),
                    updatedAt: Date(),
                    globalRating: 4.2,
                    ratingUpdatedAt: Date(),
                    saved: true
                )
            ],
            selectedIndex: $selectedIndex,
            onOpenFullDetails: { _ in },
            onNavigate: { _ in },
            onSave: { _ in },
            onShare: { _ in },
            onRate: { _, _ in }
        )
        .environmentObject(AppEnvironment().spotRepository)
        .previewLayout(.sizeThatFits)
    }
}
#endif

