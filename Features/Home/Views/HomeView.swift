import SwiftUI

/// Main home view with photo-centric feed (replaces HomeTabView)
struct HomeView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    @State private var showingFilters = false
    @State private var isTabBarHidden = false
    var onNavigateToMap: (() -> Void)? = nil
    
    private let categories = ["All", "Restaurants", "Parks", "Museums", "Beaches", "Mountains", "Coffee", "Shopping"]
    
    var body: some View {
        NavigationStack {
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
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Image
            RoundedImageView(
                imageURL: spot.images.first?.remoteURL,
                placeholder: "photo",
                aspectRatio: 1.2
            )
            .frame(height: 150)
            .overlay(
                // Heart button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            // Handle save
                        }) {
                            Image(systemName: "heart")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.black.opacity(0.3)))
                        }
                        .padding(AppSpacing.sm)
                    }
                    Spacer()
                }
            )
            
            // Content
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(spot.title)
                    .font(AppTypography.cardTitle)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                
                if let subtitle = spot.subtitle {
                    Text(subtitle)
                        .font(AppTypography.cardSubtitle)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
                
                HStack {
                    // Rating (placeholder)
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(AppColors.warning)
                        Text("4.8")
                            .font(AppTypography.ratingText)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Distance (placeholder)
                    Text("2.5 km")
                        .appFont(.caption, color: AppColors.textSecondary)
                }
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.bottom, AppSpacing.sm)
        }
        .background(AppColors.surfaceElevated)
        .cornerRadius(AppSpacing.cardCornerRadius)
        .shadow(
            color: AppSpacing.cardShadow.color,
            radius: AppSpacing.cardShadow.radius,
            x: AppSpacing.cardShadow.x,
            y: AppSpacing.cardShadow.y
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Filters View (Placeholder)
struct FiltersView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Filters")
                    .appFont(.title2)
                
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
