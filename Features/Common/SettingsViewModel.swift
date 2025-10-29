import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    enum AIProvider: String, CaseIterable {
        case auto
        case openAI
        case groq

        var displayName: String {
            switch self {
            case .auto: return "Auto"
            case .openAI: return "OpenAI"
            case .groq: return "Groq"
            }
        }
    }

    @Published var isBackgroundSyncEnabled = true
    @Published var selectedAIProvider: AIProvider = .auto

    private let preferences = UserDefaults.standard

    init() {
        if let stored = preferences.string(forKey: "ai_provider"),
           let provider = AIProvider(rawValue: stored) {
            selectedAIProvider = provider
        }
        isBackgroundSyncEnabled = preferences.object(forKey: "background_sync") as? Bool ?? true
    }

    func syncNow() async {
        NotificationCenter.default.post(name: .manualSyncRequested, object: nil)
    }

    func persist() {
        preferences.set(selectedAIProvider.rawValue, forKey: "ai_provider")
        preferences.set(isBackgroundSyncEnabled, forKey: "background_sync")
    }
}

extension Notification.Name {
    static let manualSyncRequested = Notification.Name("ManualSyncRequested")
}
