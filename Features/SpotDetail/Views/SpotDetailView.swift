import SwiftUI
import CoreLocation

/// Immersive spot detail view with photo gallery and parallax effects
struct SpotDetailView: View {
    let spot: Spot
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImageIndex = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var isShowingFullScreen = false
    
    private let imageHeight: CGFloat = 400
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            AppColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Photo Gallery
                    PhotoGalleryView(
                        images: spot.images,
                        selectedIndex: $selectedImageIndex,
                        imageHeight: imageHeight
                    )
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: geometry.frame(in: .named("scroll")).minY
                                )
                        }
                    )
                    
                    // Content
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        // Header
                        SpotHeaderView(spot: spot)
                        
                        // Details
                        SpotDetailsView(spot: spot)
                        
                        // Reviews (placeholder)
                        ReviewsSectionView(spot: spot)
                        
                        // Map Section
                        MapSectionView(spot: spot)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            
            // Navigation Bar
            NavigationBarView(
                spot: spot,
                scrollOffset: scrollOffset,
                imageHeight: imageHeight
            ) {
                dismiss()
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden(false)
    }
}

// MARK: - Photo Gallery View
struct PhotoGalleryView: View {
    let images: [SpotImage]
    @Binding var selectedIndex: Int
    let imageHeight: CGFloat
    
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Image
            TabView(selection: $selectedIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    RoundedImageView(
                        imageURL: image.remoteURL,
                        placeholder: "photo",
                        cornerRadius: 0,
                        aspectRatio: nil,
                        contentMode: .fill
                    )
                    .frame(height: imageHeight)
                    .clipped()
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: imageHeight)
            .offset(y: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.height
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
            )
            
            // Page Indicator
            if images.count > 1 {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(0..<images.count, id: \.self) { index in
                        Circle()
                            .fill(index == selectedIndex ? AppColors.textInverse : AppColors.textInverse.opacity(0.5))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, AppSpacing.lg)
            }
            
            // Heart Button
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        // Handle save
                    }) {
                        Image(systemName: "heart")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.black.opacity(0.3)))
                    }
                    .padding(.trailing, AppSpacing.lg)
                }
                Spacer()
            }
            .padding(.top, AppSpacing.lg)
        }
    }
}

// MARK: - Spot Header View
struct SpotHeaderView: View {
    let spot: Spot
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(spot.title)
                        .appFont(.title1, color: AppColors.textPrimary)
                    
                    if let subtitle = spot.subtitle {
                        Text(subtitle)
                            .appFont(.title3, color: AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Rating
                VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(AppColors.warning)
                        Text("4.8")
                            .appFont(.headline, color: AppColors.textPrimary)
                    }
                    
                    Text("(24 reviews)")
                        .appFont(.caption, color: AppColors.textSecondary)
                }
            }
            
            // Tags
            if !spot.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(spot.tags, id: \.self) { tag in
                            Text(tag)
                                .appFont(.caption, color: AppColors.primary)
                                .padding(.horizontal, AppSpacing.sm)
                                .padding(.vertical, AppSpacing.xs)
                                .background(AppColors.primary.opacity(0.1))
                                .cornerRadius(AppSpacing.pillCornerRadius)
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
                .padding(.horizontal, -AppSpacing.lg)
            }
        }
    }
}

// MARK: - Spot Details View
struct SpotDetailsView: View {
    let spot: Spot
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("About this place")
                .appFont(.headline, color: AppColors.textPrimary)
            
            Text(spot.details)
                .appFont(.body, color: AppColors.textSecondary)
                .lineLimit(isExpanded ? nil : 3)
            
            if spot.details.count > 150 {
                Button(isExpanded ? "Show less" : "Show more") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }
                .appFont(.callout, color: AppColors.primary)
            }
            
            // Amenities (placeholder)
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("What this place offers")
                    .appFont(.headline, color: AppColors.textPrimary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppSpacing.sm) {
                    ForEach(["Free WiFi", "Parking", "Pet Friendly", "Wheelchair Accessible"], id: \.self) { amenity in
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppColors.success)
                                .font(.caption)
                            Text(amenity)
                                .appFont(.caption, color: AppColors.textSecondary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Reviews Section View
struct ReviewsSectionView: View {
    let spot: Spot
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Reviews")
                    .appFont(.headline, color: AppColors.textPrimary)
                
                Spacer()
                
                Button("See all") {
                    // Navigate to all reviews
                }
                .appFont(.callout, color: AppColors.primary)
            }
            
            // Sample review
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Circle()
                        .fill(AppColors.surface)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text("A")
                                .appFont(.callout, weight: .semibold, color: AppColors.textPrimary)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Alex M.")
                            .appFont(.callout, weight: .semibold, color: AppColors.textPrimary)
                        
                        HStack(spacing: 2) {
                            ForEach(0..<5) { _ in
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(AppColors.warning)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Text("2 days ago")
                        .appFont(.caption, color: AppColors.textTertiary)
                }
                
                Text("Amazing hidden gem! The atmosphere is incredible and the staff is super friendly. Definitely coming back.")
                    .appFont(.body, color: AppColors.textSecondary)
            }
            .padding(AppSpacing.md)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.buttonCornerRadius)
        }
    }
}

// MARK: - Map Section View
struct MapSectionView: View {
    let spot: Spot
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Location")
                .appFont(.headline, color: AppColors.textPrimary)
            
            // Map placeholder
            RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius)
                .fill(AppColors.surface)
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "map.fill")
                            .font(.title)
                            .foregroundColor(AppColors.textTertiary)
                        Text("Map View")
                            .appFont(.callout, color: AppColors.textSecondary)
                    }
                )
            
            if let address = spot.address {
                Text(address)
                    .appFont(.body, color: AppColors.textSecondary)
            }
        }
    }
}

// MARK: - Navigation Bar View
struct NavigationBarView: View {
    let spot: Spot
    let scrollOffset: CGFloat
    let imageHeight: CGFloat
    let onDismiss: () -> Void
    
    private var isTransparent: Bool {
        scrollOffset > -imageHeight + 100
    }
    
    var body: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.black.opacity(0.3)))
            }
            
            Spacer()
            
            HStack(spacing: AppSpacing.sm) {
                Button(action: {
                    // Handle share
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.black.opacity(0.3)))
                }
                
                Button(action: {
                    // Handle more options
                }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.black.opacity(0.3)))
                }
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.lg)
        .background(
            Rectangle()
                .fill(isTransparent ? Color.clear : AppColors.surfaceElevated)
                .shadow(
                    color: isTransparent ? Color.clear : Color.black.opacity(0.1),
                    radius: isTransparent ? 0 : 4,
                    x: 0,
                    y: isTransparent ? 0 : 2
                )
        )
        .animation(.easeInOut(duration: 0.3), value: isTransparent)
    }
}

// MARK: - Preview
#if DEBUG
struct SpotDetailView_Previews: PreviewProvider {
    static let sampleSpot = Spot(
        id: "1",
        title: "Secret Garden Cafe",
        subtitle: "Hidden coffee shop with amazing views",
        details: "Tucked away in a quiet alley, this charming cafe offers the perfect escape from the city hustle. With its lush garden setting and artisanal coffee, it's a true hidden gem that locals love to keep secret.",
        coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        address: "123 Hidden Lane, San Francisco, CA",
        tags: ["Coffee", "Garden", "Quiet", "Local Favorite"],
        topics: ["Food & Drink"],
        images: [
            SpotImage(id: UUID(), localIdentifier: nil, remoteURL: URL(string: "https://picsum.photos/400/300")),
            SpotImage(id: UUID(), localIdentifier: nil, remoteURL: URL(string: "https://picsum.photos/400/301")),
            SpotImage(id: UUID(), localIdentifier: nil, remoteURL: URL(string: "https://picsum.photos/400/302"))
        ],
        groupId: nil,
        userId: nil,
        deleted: false,
        version: 1,
        createdAt: Date(),
        updatedAt: Date()
    )
    
    static var previews: some View {
        SpotDetailView(spot: sampleSpot)
    }
}
#endif
