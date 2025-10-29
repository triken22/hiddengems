import SwiftUI

struct HomeTabView: View {
    @EnvironmentObject private var viewModel: HomeViewModel

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            HomeMapView(viewModel: viewModel)
                .tabItem {
                    Label("Map", systemImage: "map")
                }
                .tag(HomeViewModel.Tab.map)

            GroupListView(viewModel: viewModel.groupListViewModel)
                .tabItem {
                    Label("Groups", systemImage: "person.3")
                }
                .tag(HomeViewModel.Tab.groups)

            SettingsView(viewModel: viewModel.settingsViewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(HomeViewModel.Tab.settings)
        }
    }
}
