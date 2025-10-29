import SwiftUI
import MapKit
import UIKit

/// Main app container with custom tab bar navigation
struct MainAppView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    @EnvironmentObject private var groupListViewModel: GroupListViewModel
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    
    @State private var selectedTab: TabItem = TabItem(
        title: "Explore",
        icon: "house",
        selectedIcon: "house.fill",
        tag: 0
    )
    
    private let tabs = [
        TabItem(title: "Explore", icon: "house", selectedIcon: "house.fill", tag: 0),
        TabItem(title: "Map", icon: "map", selectedIcon: "map.fill", tag: 1),
        TabItem(title: "Saved", icon: "heart", selectedIcon: "heart.fill", tag: 2),
        TabItem(title: "Profile", icon: "person", selectedIcon: "person.fill", tag: 3)
    ]
    
    var body: some View {
        NavigationStack {
            TabBarContainer(selectedTab: $selectedTab, tabs: tabs) { tab in
                switch tab.tag {
                case 0:
                    HomeView(onNavigateToMap: {
                        selectedTab = TabItem(title: "Map", icon: "map", selectedIcon: "map.fill", tag: 1)
                    })
                        .environmentObject(homeViewModel)
                case 1:
                    ExploreMapView()
                        .environmentObject(homeViewModel)
                case 2:
                    SavedView(onNavigateToExplore: {
                        selectedTab = TabItem(title: "Explore", icon: "house", selectedIcon: "house.fill", tag: 0)
                    })
                        .environmentObject(homeViewModel)
                case 3:
                    ProfileView()
                        .environmentObject(homeViewModel)
                default:
                    HomeView()
                        .environmentObject(homeViewModel)
                }
            }
        }
        .withAppTheme()
        .preferredColorScheme(.light)
    }
}

// MARK: - Explore Map View
struct ExploreMapView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    @State private var selectedSpot: Spot? = nil
    @State private var showingBottomSheet = false
    @State private var showingCreateSpot = false
    @State private var selectedCoordinate: CLLocationCoordinate2D? = nil
    @State private var searchText = ""
    @State private var showingSearch = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: $viewModel.region,
                annotationItems: viewModel.mapSpots) { spot in
                MapAnnotation(coordinate: spot.coordinate) {
                    SpotMapMarker(
                        spot: spot,
                        isSelected: selectedSpot?.id == spot.id
                    ) {
                        withAnimation(.spring()) {
                            selectedSpot = spot
                            showingBottomSheet = true
                        }
                    }
                    .onTapGesture {
                        // Direct navigation to detail view
                        selectedSpot = spot
                        showingBottomSheet = true
                    }
                }
            }
            .task {
                await viewModel.centerOnUser()
            }
            .onTapGesture { location in
                withAnimation(.spring()) {
                    selectedSpot = nil
                    showingBottomSheet = false
                }
            }
            .onLongPressGesture(minimumDuration: 0.6) {
                let coordinate = viewModel.region.center
                selectedCoordinate = coordinate
                showingCreateSpot = true
                
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
            
            // Search Bar
            VStack {
                HStack {
                    SearchBarView(
                        searchText: $searchText,
                        placeholder: "Search spots on map..."
                    ) {
                        // Handle search
                        filterMapSpots()
                    } onTextChanged: { text in
                        filterMapSpots()
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.sm)
                }
                Spacer()
            }
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton(icon: "plus") {
                        // Use current map center or user location
                        Task {
                            // Use map center for now, user location will be handled by CreateSpotView
                            selectedCoordinate = viewModel.region.center
                            showingCreateSpot = true
                        }
                    }
                    .padding(.trailing, AppSpacing.lg)
                    .padding(.bottom, showingBottomSheet ? 200 : AppSpacing.lg)
                }
            }
            
            // Bottom Sheet
            if showingBottomSheet {
                VStack {
                    Spacer()
                    MapBottomSheet(spot: selectedSpot) {
                        withAnimation(.spring()) {
                            selectedSpot = nil
                            showingBottomSheet = false
                        }
                    }
                    .environmentObject(viewModel)
                }
            }
        }
        .navigationTitle("Map")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task {
                        await viewModel.centerOnUser()
                    }
                }) {
                    Image(systemName: "location.fill")
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .sheet(isPresented: $showingCreateSpot) {
            if let coordinate = selectedCoordinate {
                CreateSpotView(viewModel: viewModel.createSpotViewModel(initialLocation: coordinate))
            } else {
                CreateSpotView(viewModel: viewModel.createSpotViewModel())
            }
        }
    }
    
    private func filterMapSpots() {
        // This will be handled by the HomeViewModel's filterSpots method
        // The map will show all spots, but the search affects the overall filtering
        viewModel.updateSearchText(searchText)
    }
}


// MARK: - Saved View
struct SavedView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    var onNavigateToExplore: (() -> Void)? = nil

    @State private var searchText = ""
    @State private var sortOption: SortOption = .dateSaved
    @State private var showingSortOptions = false
    
    enum SortOption: String, CaseIterable {
        case dateSaved = "Date Saved"
        case alphabetical = "A-Z"
        case distance = "Distance"
        
        var displayName: String { rawValue }
    }
    
    private var savedSpots: [Spot] {
        var spots = viewModel.spots.filter { $0.saved && !$0.deleted }
        
        // Filter by search text
        if !searchText.isEmpty {
            spots = spots.filter { spot in
                spot.title.localizedCaseInsensitiveContains(searchText) ||
                spot.subtitle?.localizedCaseInsensitiveContains(searchText) ?? false ||
                spot.details.localizedCaseInsensitiveContains(searchText) ||
                spot.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Sort based on selected option
        switch sortOption {
        case .dateSaved:
            spots = spots.sorted { $0.updatedAt > $1.updatedAt }
        case .alphabetical:
            spots = spots.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .distance:
            // For now, keep original order (would need user location for proper distance sorting)
            break
        }
        
        return spots
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with search and sort
            VStack(spacing: AppSpacing.md) {
                // Search Bar
                SearchBarView(
                    searchText: $searchText,
                    placeholder: "Search saved spots..."
                ) {
                    // Handle search
                } onTextChanged: { text in
                    // Text changed, filtered automatically via computed property
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
                
                // Sort options
                HStack {
                    Text("\(savedSpots.count) saved spots")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    Button(action: { showingSortOptions = true }) {
                        HStack(spacing: AppSpacing.xs) {
                            Text("Sort: \(sortOption.displayName)")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.primary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10))
                                .foregroundColor(AppColors.primary)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
            
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    if savedSpots.isEmpty {
                        EmptyStateView(
                            icon: searchText.isEmpty ? "heart" : "magnifyingglass",
                            title: searchText.isEmpty ? "No saved spots" : "No results",
                            message: searchText.isEmpty ? "Start exploring and save spots you love" : "No spots match '\(searchText)'",
                            actionTitle: searchText.isEmpty ? "Explore" : "Clear Search"
                        ) {
                            if searchText.isEmpty {
                                onNavigateToExplore?()
                            } else {
                                searchText = ""
                            }
                        }
                        .padding(.top, AppSpacing.xxl)
                    } else {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: AppSpacing.md),
                                GridItem(.flexible(), spacing: AppSpacing.md)
                            ],
                            spacing: AppSpacing.lg
                        ) {
                            ForEach(savedSpots) { spot in
                                NavigationLink(destination: SpotDetailView(spot: spot)
                                    .environmentObject(viewModel)) {
                                    SpotCardView(spot: spot)
                                        .environmentObject(viewModel)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.tabBarHeight + AppSpacing.lg)
                    }
                }
            }
            .refreshable {
                await viewModel.loadSpots()
            }
        }
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingSortOptions) {
                SortOptionsView(selectedOption: $sortOption)
            }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    
    private var savedSpotsCount: Int {
        viewModel.spots.filter { $0.saved && !$0.deleted }.count
    }
    
    private var createdSpotsCount: Int {
        viewModel.spots.filter { !$0.deleted }.count
    }
    
    private var totalPhotosCount: Int {
        viewModel.spots.reduce(0) { total, spot in
            total + spot.images.count
        }
    }
    
    private var memberSinceDate: String {
        // Get the earliest spot creation date or default to 2024
        let earliestDate = viewModel.spots
            .filter { !$0.deleted }
            .map { $0.createdAt }
            .min() ?? Date()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: earliestDate)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Profile Header
                VStack(spacing: AppSpacing.md) {
                    // Avatar
                    Circle()
                        .fill(AppColors.surface)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.title)
                                .foregroundColor(AppColors.textTertiary)
                        )
                    
                    VStack(spacing: AppSpacing.xs) {
                        Text("Hidden Gem Explorer")
                            .font(AppTypography.profileName)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Member since \(memberSinceDate)")
                            .font(AppTypography.profileBio)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(.top, AppSpacing.lg)
                
                // Stats
                VStack(spacing: AppSpacing.md) {
                    HStack(spacing: AppSpacing.lg) {
                        StatCard(
                            value: "\(createdSpotsCount)",
                            label: "Spots Created",
                            icon: "location.fill"
                        )
                        
                        StatCard(
                            value: "\(savedSpotsCount)",
                            label: "Saved",
                            icon: "heart.fill",
                            color: AppColors.success
                        )
                    }
                    
                    HStack(spacing: AppSpacing.lg) {
                        StatCard(
                            value: "\(totalPhotosCount)",
                            label: "Photos",
                            icon: "camera.fill",
                            color: AppColors.warning
                        )
                        
                        StatCard(
                            value: "\(viewModel.spots.filter { !$0.deleted && $0.images.count > 0 }.count)",
                            label: "With Photos",
                            icon: "photo.fill",
                            color: AppColors.info
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                
                // Created Spots Section
                if createdSpotsCount > 0 {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Your Spots")
                            .font(AppTypography.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, AppSpacing.lg)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppSpacing.md) {
                                ForEach(viewModel.spots.prefix(5)) { spot in
                                    NavigationLink(destination: SpotDetailView(spot: spot)
                                        .environmentObject(viewModel)) {
                                        SpotCardView(spot: spot)
                                            .environmentObject(viewModel)
                                            .frame(width: 200)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, AppSpacing.lg)
                        }
                    }
                }
                
                // Settings
                VStack(spacing: 0) {
                    NavigationLink(destination: CollectionsView()) {
                        InfoCard(
                            title: "Collections",
                            subtitle: "Organize your saved spots",
                            icon: "folder.fill"
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    InfoCard(
                        title: "Settings",
                        subtitle: "Manage your preferences",
                        icon: "gearshape.fill"
                    ) {
                        // Navigate to settings
                    }
                    
                    InfoCard(
                        title: "Help & Support",
                        subtitle: "Get help and contact us",
                        icon: "questionmark.circle.fill"
                    ) {
                        // Navigate to help
                    }
                    
                    InfoCard(
                        title: "About",
                        subtitle: "Learn more about HiddenGems",
                        icon: "info.circle.fill"
                    ) {
                        // Navigate to about
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.tabBarHeight + AppSpacing.lg)
            }
        }
        .refreshable {
            await viewModel.loadSpots()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Sort Options View
struct SortOptionsView: View {
    @Binding var selectedOption: SavedView.SortOption
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(SavedView.SortOption.allCases, id: \.self) { option in
                    Button(action: {
                        selectedOption = option
                        dismiss()
                    }) {
                        HStack {
                            Text(option.displayName)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Spacer()
                            
                            if selectedOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Sort By")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct MainAppView_Previews: PreviewProvider {
    static var previews: some View {
        MainAppView()
            .environmentObject(AppEnvironment().homeViewModel)
            .environmentObject(AppEnvironment().groupListViewModel)
            .environmentObject(AppEnvironment().settingsViewModel)
    }
}
#endif
