import SwiftUI

/// Main theme configuration for HiddenGems app
struct AppTheme {
    
    // MARK: - Theme Configuration
    static let isDarkModeSupported = true
    static let supportsDynamicType = true
    static let supportsAccessibility = true
    
    // MARK: - Animation Configuration
    static let defaultAnimation = Animation.easeInOut(duration: 0.3)
    static let springAnimation = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let quickAnimation = Animation.easeInOut(duration: 0.2)
    static let slowAnimation = Animation.easeInOut(duration: 0.5)
    
    // MARK: - Haptic Feedback
    static let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    static let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    static let heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)
    static let selectionHaptic = UISelectionFeedbackGenerator()
    static let notificationHaptic = UINotificationFeedbackGenerator()
}

// MARK: - Theme Environment
struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppTheme()
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - View Extensions for Theme
extension View {
    func withAppTheme() -> some View {
        self.environment(\.appTheme, AppTheme())
    }
    
    func appAnimation(_ animation: Animation = AppTheme.defaultAnimation) -> some View {
        self.animation(animation, value: UUID())
    }
    
    func appSpringAnimation() -> some View {
        self.animation(AppTheme.springAnimation, value: UUID())
    }
    
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.onTapGesture {
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        }
    }
}

// MARK: - Common View Modifiers
extension View {
    func appCardBackground() -> some View {
        self
            .background(AppColors.surfaceElevated)
            .cornerRadius(AppSpacing.cardCornerRadius)
            .shadow(
                color: AppSpacing.cardShadow.color,
                radius: AppSpacing.cardShadow.radius,
                x: AppSpacing.cardShadow.x,
                y: AppSpacing.cardShadow.y
            )
    }
    
    func appButtonBackground(color: Color = AppColors.primary) -> some View {
        self
            .background(color)
            .cornerRadius(AppSpacing.buttonCornerRadius)
            .shadow(
                color: AppSpacing.buttonShadow.color,
                radius: AppSpacing.buttonShadow.radius,
                x: AppSpacing.buttonShadow.x,
                y: AppSpacing.buttonShadow.y
            )
    }
    
    func appPillBackground(color: Color = AppColors.surface) -> some View {
        self
            .background(color)
            .cornerRadius(AppSpacing.pillCornerRadius)
    }
    
    func appDivider() -> some View {
        Rectangle()
            .fill(AppColors.borderLight)
            .frame(height: 1)
    }
}

// MARK: - Accessibility
extension AppTheme {
    static func configureAccessibility() {
        // Configure accessibility settings
        // VoiceOver is automatically enabled by iOS
    }
}

// MARK: - Dynamic Type Support
extension AppTheme {
    static func scaledFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight)
    }
}

// MARK: - Color Scheme Support
extension AppTheme {
    static func colors(for colorScheme: ColorScheme) -> AppColors.Type {
        return AppColors.self
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension AppTheme {
    static let preview = AppTheme()
}
#endif
