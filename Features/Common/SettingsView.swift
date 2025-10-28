import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Synchronization") {
                    Toggle("Background Sync", isOn: $viewModel.isBackgroundSyncEnabled)
                        .onChange(of: viewModel.isBackgroundSyncEnabled) { _ in viewModel.persist() }
                    Button("Sync Now") {
                        Task { await viewModel.syncNow() }
                    }
                }

                Section("AI") {
                    Picker("AI Provider", selection: $viewModel.selectedAIProvider) {
                        ForEach(SettingsViewModel.AIProvider.allCases, id: \.self) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                    .onChange(of: viewModel.selectedAIProvider) { _ in viewModel.persist() }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
