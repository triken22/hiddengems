import Foundation

extension AppEnvironment {
    @MainActor
    static var preview: AppEnvironment {
        AppEnvironment()
    }
}
