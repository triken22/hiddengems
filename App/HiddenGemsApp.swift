import SwiftUI

@main
struct HiddenGemsApp: App {
    @StateObject private var environment = AppEnvironment.live()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(environment)
                .task {
                    await environment.syncCoordinator.performInitialSync()
                }
        }
    }
}

private struct RootView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        HomeTabView()
            .environmentObject(environment.homeViewModel())
    }
}
