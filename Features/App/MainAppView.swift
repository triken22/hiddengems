import SwiftUI
import MapKit

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
        .withAppTheme()
        .preferredColorScheme(.light)
    }
}

// MARK: - Explore Map View
struct ExploreMapView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    @State private var selectedSpot: Spot? = nil
    @State private var showingBottomSheet = false
    @State private var showingAddLocation = false
    @State private var selectedCoordinate: CLLocationCoordinate2D? = nil
    
    var body: some View {
        NavigationStack {
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
                .gesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in
                            // For now, use region center - in a real implementation,
                            // you'd convert the tap location to coordinates
                            let coordinate = viewModel.region.center
                            selectedCoordinate = coordinate
                            showingAddLocation = true
                        }
                )
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton(icon: "camera.fill") {
                            viewModel.openQuickAdd()
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
        }
        .sheet(isPresented: $showingAddLocation) {
            if let coordinate = selectedCoordinate {
                NavigationStack {
                    QuickAddView(viewModel: viewModel.quickAddViewModel())
                        .navigationTitle("Add at \(coordinate.latitude, specifier: "%.4f"), \(coordinate.longitude, specifier: "%.4f")")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingAddLocation = false
                                    selectedCoordinate = nil
                                }
                            }
                        }
                }
            }
        }
    }
}


// MARK: - Saved View
struct SavedView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    var onNavigateToExplore: (() -> Void)? = nil
    
    private var savedSpots: [Spot] {
        viewModel.spots.filter { $0.saved && !$0.deleted }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if savedSpots.isEmpty {
                    EmptyStateView(
                        icon: "heart",
                        title: "No saved spots",
                        message: "Start exploring and save spots you love",
                        actionTitle: "Explore"
                    ) {
                        onNavigateToExplore?()
                    }
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: AppSpacing.md),
                            GridItem(.flexible(), spacing: AppSpacing.md)
                        ],
                        spacing: AppSpacing.lg
                    ) {
                        ForEach(savedSpots) { spot in
                            NavigationLink(destination: SpotDetailView(spot: spot)) {
                                SpotCardView(spot: spot)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
            }
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    
    var body: some View {
        NavigationStack {
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
                            Text("Your Name")
                                .font(AppTypography.profileName)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Member since 2024")
                                .font(AppTypography.profileBio)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .padding(.top, AppSpacing.lg)
                    
                    // Stats
                    HStack(spacing: AppSpacing.lg) {
                        StatCard(
                            value: "\(viewModel.spots.count)",
                            label: "Spots Discovered",
                            icon: "location.fill"
                        )
                        
                        StatCard(
                            value: "12",
                            label: "Photos Taken",
                            icon: "camera.fill",
                            color: AppColors.success
                        )
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    
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
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
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
