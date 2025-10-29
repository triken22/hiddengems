import SwiftUI
import CoreLocation
import MapKit

/// Immersive spot detail view with photo gallery and parallax effects
struct SpotDetailView: View {
    let spot: Spot
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: HomeViewModel
    @State private var selectedImageIndex = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var isShowingFullScreen = false
    @State private var isSaved = false
    
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
                    
                    // Heart Button
                    HStack {
                        Spacer()
                        Button(action: {
                            toggleSave()
                        }) {
                            Image(systemName: isSaved ? "heart.fill" : "heart")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(isSaved ? .red : .white)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.black.opacity(0.3)))
                        }
                        .padding(.trailing, AppSpacing.lg)
                        .accessibilityLabel(isSaved ? "Remove from saved" : "Save spot")
                        .accessibilityHint(isSaved ? "Tap to unsave this spot" : "Tap to save this spot")
                    }
                    .padding(.top, -AppSpacing.xl)
                    
                    // Content
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        // Header
                        SpotHeaderView(spot: spot)
                        
                        // Details
                        SpotDetailsView(spot: spot)
                        
                        // Rating Editor
                        RatingEditorView(spot: spot)
                        
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
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
        .onAppear {
            isSaved = spot.saved
        }
    }
    
    private func toggleSave() {
        Task {
            // Create updated spot with toggled saved state
            let updatedSpot = Spot(
                id: spot.id,
                title: spot.title,
                subtitle: spot.subtitle,
                details: spot.details,
                coordinate: spot.coordinate,
                address: spot.address,
                tags: spot.tags,
                topics: spot.topics,
                images: spot.images,
                groupId: spot.groupId,
                userId: spot.userId,
                deleted: spot.deleted,
                saved: !spot.saved,
                version: spot.version + 1,
                createdAt: spot.createdAt,
                updatedAt: Date()
            )
            
            do {
                try await viewModel.spotRepository.save(spot: updatedSpot)
                await MainActor.run {
                    isSaved = updatedSpot.saved
                }
            } catch {
                // Handle error
                print("Error saving spot: \(error)")
            }
        }
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
                ForEach(Array(images.enumerated()), id: \.offset) { index, spotImage in
                    if let localImage = spotImage.localImage {
                        // Show local image
                        Image(uiImage: localImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: imageHeight)
                            .clipped()
                            .tag(index)
                    } else if let remoteURL = spotImage.remoteURL {
                        // Show remote image
                        AsyncImage(url: remoteURL) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(AppColors.surface)
                                    .frame(height: imageHeight)
                                    .overlay(ProgressView().tint(AppColors.primary))
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: imageHeight)
                                    .clipped()
                            case .failure:
                                Rectangle()
                                    .fill(AppColors.surface)
                                    .frame(height: imageHeight)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.system(size: 60))
                                            .foregroundColor(AppColors.textSecondary)
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .tag(index)
                    } else {
                        // Placeholder
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.primary.opacity(0.3), AppColors.primary.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: imageHeight)
                            .overlay(
                                VStack(spacing: AppSpacing.md) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(AppColors.primary.opacity(0.6))
                                    Text("No Photo")
                                        .font(AppTypography.body)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            )
                            .tag(index)
                    }
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
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Image \(selectedIndex + 1) of \(images.count)")
            }
            
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
                        .font(AppTypography.title1)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    
                    if let subtitle = spot.subtitle {
                        Text(subtitle)
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Rating
                VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(AppColors.warning)
                        Text(spot.globalRating > 0 ? String(format: "%.1f", spot.globalRating) : "No rating")
                            .font(AppTypography.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    if spot.globalRating > 0 {
                        Text("Global rating")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    } else {
                        Text("Tap to rate")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            
            // Tags
            if !spot.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(spot.tags, id: \.self) { tag in
                            Text(tag)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.primary)
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
                .font(AppTypography.headline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            Text(spot.details)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(isExpanded ? nil : 3)
            
            if spot.details.count > 150 {
                Button(isExpanded ? "Show less" : "Show more") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }
                .font(AppTypography.callout)
                .fontWeight(.medium)
                .foregroundColor(AppColors.primary)
            }
            
            // Amenities (placeholder)
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("What this place offers")
                    .font(AppTypography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
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
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
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
                    .font(AppTypography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button("See all") {
                    // Navigate to all reviews
                }
                .font(AppTypography.callout)
                .fontWeight(.medium)
                .foregroundColor(AppColors.primary)
            }
            
            // Sample review
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Circle()
                        .fill(AppColors.surface)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text("A")
                                .font(AppTypography.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Alex M.")
                            .font(AppTypography.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                        
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
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Text("Amazing hidden gem! The atmosphere is incredible and the staff is super friendly. Definitely coming back.")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
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
    @State private var region: MKCoordinateRegion
    
    init(spot: Spot) {
        self.spot = spot
        _region = State(initialValue: MKCoordinateRegion(
            center: spot.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Location")
                .font(AppTypography.headline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            // Map with pin
            Map(coordinateRegion: $region,
                annotationItems: [spot]) { spot in
                MapAnnotation(coordinate: spot.coordinate) {
                    VStack(spacing: 0) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title)
                            .foregroundColor(AppColors.primary)
                        Image(systemName: "arrowtriangle.down.fill")
                            .font(.caption)
                            .foregroundColor(AppColors.primary)
                            .offset(y: -5)
                    }
                }
            }
            .frame(height: 200)
            .cornerRadius(AppSpacing.buttonCornerRadius)
            .allowsHitTesting(false)
            
            if let address = spot.address {
                Text(address)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Get Directions Button
            Button(action: {
                openInMaps()
            }) {
                HStack {
                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                    Text("Get Directions")
                }
                .font(AppTypography.buttonText)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textInverse)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(AppColors.primary)
                .cornerRadius(AppSpacing.buttonCornerRadius)
            }
        }
    }
    
    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: spot.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = spot.title
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
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

// MARK: - Rating Editor View
struct RatingEditorView: View {
    let spot: Spot
    @EnvironmentObject private var viewModel: HomeViewModel
    @State private var currentRating: Double = 0
    @State private var isUpdating = false
    @State private var showSuccessMessage = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Rate this spot")
                .font(AppTypography.headline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.md) {
                // Star Rating Display
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= Int(currentRating) ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundColor(AppColors.warning)
                    }
                    
                    Text(String(format: "%.1f", currentRating))
                        .font(AppTypography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.leading, AppSpacing.sm)
                }
                
                // Rating Slider
                VStack(spacing: AppSpacing.sm) {
                    HStack {
                        Text("0")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Slider(value: $currentRating, in: 0...5, step: 0.5)
                            .accentColor(AppColors.primary)
                        
                        Text("5")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Text("Slide to adjust rating")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                // Save Button
                Button(action: {
                    saveRating()
                }) {
                    HStack {
                        if isUpdating {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "star.fill")
                        }
                        Text(isUpdating ? "Saving..." : "Save Rating")
                    }
                    .font(AppTypography.buttonText)
                    .foregroundColor(AppColors.textInverse)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(currentRating > 0 ? AppColors.primary : AppColors.border)
                    .cornerRadius(AppSpacing.buttonCornerRadius)
                }
                .disabled(currentRating == 0 || isUpdating)
                
                if showSuccessMessage {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.success)
                        Text("Rating saved successfully!")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.success)
                    }
                    .transition(.opacity)
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.buttonCornerRadius)
        }
        .onAppear {
            currentRating = spot.globalRating
        }
    }
    
    private func saveRating() {
        guard currentRating > 0 else { return }
        
        isUpdating = true
        showSuccessMessage = false
        
        Task {
            do {
                try await viewModel.spotRepository.updateRating(spotId: spot.id, newRating: currentRating)
                
                await MainActor.run {
                    isUpdating = false
                    showSuccessMessage = true
                    
                    // Hide success message after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showSuccessMessage = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                    // Handle error - could show an alert
                    print("Error updating rating: \(error)")
                }
            }
        }
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
        saved: false,
        version: 1,
        globalRating: 4.5,
        ratingUpdatedAt: Date(),
        createdAt: Date(),
        updatedAt: Date()
    )
    
    static var previews: some View {
        SpotDetailView(spot: sampleSpot)
            .environmentObject(AppEnvironment().homeViewModel)
    }
}
#endif
