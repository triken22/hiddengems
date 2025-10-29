import SwiftUI

@main
struct HiddenGemsApp: App {
    @State private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            MainAppView()
                .environmentObject(environment.homeViewModel)
                .environmentObject(environment.groupListViewModel)
                .environmentObject(environment.settingsViewModel)
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}
