import SwiftUI

/// Main home view with photo-centric feed (replaces HomeTabView)
struct HomeView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    @State private var showingFilters = false
    @State private var isTabBarHidden = false
    var onNavigateToMap: (() -> Void)? = nil
    
    private let categories = ["All", "Restaurants", "Parks", "Museums", "Beaches", "Mountains", "Coffee", "Shopping"]
    
    var body: some View {
        ZStack(alignment: .bottom) {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Search Bar
                        SearchBarWithFilters(
                            searchText: $viewModel.searchText,
                            placeholder: "Where to?",
                            filterCount: 0
                        ) {
                            // Handle search
                        } onTextChanged: { text in
                            viewModel.updateSearchText(text)
                        } onFiltersTapped: {
                            showingFilters = true
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.sm)
                        .padding(.bottom, AppSpacing.md)
                        
                        // Category Pills
                        PillButtonGroup(
                            items: categories,
                            selectedItem: $viewModel.selectedCategory
                        ) { category in
                            viewModel.updateSelectedCategory(category)
                        }
                        .padding(.bottom, AppSpacing.lg)
                        
                        // Spots Grid
                        if viewModel.isLoading {
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: AppSpacing.md),
                                    GridItem(.flexible(), spacing: AppSpacing.md)
                                ],
                                spacing: AppSpacing.lg
                            ) {
                                ForEach(0..<6, id: \.self) { _ in
                                    SkeletonCard()
                                }
                            }
                            .padding(.horizontal, AppSpacing.lg)
                        } else if viewModel.filteredSpots.isEmpty {
                            EmptyStateView(
                                icon: "magnifyingglass",
                                title: viewModel.searchText.isEmpty ? "No spots found" : "No results for '\(viewModel.searchText)'",
                                message: viewModel.searchText.isEmpty ? "Start exploring and discover hidden gems around you" : "Try adjusting your search or explore a different category",
                                actionTitle: viewModel.searchText.isEmpty ? "Explore Map" : "Clear Search"
                            ) {
                                if viewModel.searchText.isEmpty {
                                    onNavigateToMap?()
                                } else {
                                    viewModel.updateSearchText("")
                                }
                            }
                            .padding(.horizontal, AppSpacing.lg)
                        } else {
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: AppSpacing.md),
                                    GridItem(.flexible(), spacing: AppSpacing.md)
                                ],
                                spacing: AppSpacing.lg
                            ) {
                                ForEach(viewModel.filteredSpots) { spot in
                                    NavigationLink(destination: SpotDetailView(spot: spot)) {
                                        SpotCardView(spot: spot)
                                            .environmentObject(viewModel)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, AppSpacing.md)
                        }
                        
                        // Bottom padding for tab bar
                        if !viewModel.isLoading && !viewModel.filteredSpots.isEmpty {
                            Color.clear
                                .frame(height: AppSpacing.tabBarHeight + AppSpacing.lg)
                        }
                    }
                }
                .coordinateSpace(name: "scroll")
                .hideTabBarOnScroll($isTabBarHidden)
                .refreshable {
                    await viewModel.loadSpots()
                }
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton(icon: "plus") {
                            viewModel.openQuickAdd()
                        }
                        .padding(.trailing, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.tabBarHeight + AppSpacing.lg)
                    }
                }
            }
            .navigationTitle("HiddenGems")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Handle notifications
                    }) {
                        Image(systemName: "bell")
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
        .sheet(isPresented: $viewModel.isQuickAddPresented) {
            CreateSpotView(viewModel: viewModel.createSpotViewModel())
        }
        .sheet(isPresented: $showingFilters) {
            FiltersView()
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}

// MARK: - Spot Card View
struct SpotCardView: View {
    let spot: Spot
    @EnvironmentObject private var viewModel: HomeViewModel
    @State private var isPressed = false
    @State private var imageLoaded = false
    @State private var isSaved = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Large hero image with better showcase
            ZStack(alignment: .topTrailing) {
                // Image display with priority to local images
                if let localImage = spot.images.first?.localImage {
                    Image(uiImage: localImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .opacity(imageLoaded ? 1.0 : 0.8)
                        .onAppear {
                            withAnimation(.easeIn(duration: 0.3)) {
                                imageLoaded = true
                            }
                        }
                } else if let imageURL = spot.images.first?.remoteURL {
                    AsyncImage(url: imageURL) { phase in
                        imageDisplayView(phase: phase)
                    }
                    .frame(height: 200)
                } else {
                    placeholderImageView
                }
                
                // Interactive save/like button
                Button(action: {
                    toggleSave()
                }) {
                    Image(systemName: isSaved ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(isSaved ? AppColors.primary : Color.black.opacity(0.4))
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .padding(AppSpacing.md)
                .buttonStyle(PlainButtonStyle())
            }
            .clipped()
            
            // Content with improved spacing
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(spot.title)
                    .font(AppTypography.cardTitle)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)
                
                if let subtitle = spot.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppTypography.cardSubtitle)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                } else if !spot.details.isEmpty {
                    Text(spot.details)
                        .font(AppTypography.cardSubtitle)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                }
                
                // Tags row
                if !spot.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.xs) {
                            ForEach(spot.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.primary)
                                    .padding(.horizontal, AppSpacing.sm)
                                    .padding(.vertical, 4)
                                    .background(AppColors.primary.opacity(0.12))
                                    .cornerRadius(AppSpacing.pillCornerRadius)
                            }
                        }
                    }
                }
                
                // Bottom info row
                HStack(alignment: .center, spacing: AppSpacing.md) {
                    // Rating
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.warning)
                        Text("4.8")
                            .font(AppTypography.ratingText)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    Spacer()
                    
                    // Distance
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.textSecondary)
                        Text("2.4 km")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
        .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onAppear {
            isSaved = spot.saved
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    @ViewBuilder
    private func imageDisplayView(phase: AsyncImagePhase) -> some View {
        switch phase {
        case .empty:
            Rectangle()
                .fill(AppColors.surface)
                .frame(height: 200)
                .overlay(
                    ProgressView()
                        .tint(AppColors.primary)
                )
        case .success(let image):
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 200)
                .clipped()
        case .failure:
            placeholderImageView
        @unknown default:
            EmptyView()
        }
    }
    
    private var placeholderImageView: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        AppColors.primary.opacity(0.3),
                        AppColors.primary.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 200)
            .overlay(
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.primary.opacity(0.6))
                    Text("No Photo")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            )
    }
    
    private func toggleSave() {
        print("🔵 toggleSave called for spot: \(spot.title), current saved: \(isSaved)")
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Toggle local state immediately for responsiveness
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isSaved.toggle()
        }
        
        print("🔵 After toggle, isSaved: \(isSaved)")
        
        // Update the spot in the repository
        Task {
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
                saved: isSaved,
                version: spot.version + 1,
                createdAt: spot.createdAt,
                updatedAt: Date()
            )
            
            do {
                // Save will trigger Combine publisher which updates UI instantly
                try await viewModel.spotRepository.save(spot: updatedSpot)
            } catch {
                // Revert on error
                await MainActor.run {
                    withAnimation {
                        isSaved.toggle()
                    }
                }
                print("Error toggling save: \(error)")
            }
        }
    }
}

// MARK: - Filters View (Placeholder)
struct FiltersView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Filters")
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppEnvironment().homeViewModel)
    }
}
#endif
