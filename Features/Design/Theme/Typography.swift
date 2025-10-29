import SwiftUI

/// Airbnb-inspired typography system for HiddenGems
struct AppTypography {
    
    // MARK: - Font Weights
    enum Weight {
        case light
        case regular
        case medium
        case semibold
        case bold
        
        var fontWeight: Font.Weight {
            switch self {
            case .light: return .light
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            case .bold: return .bold
            }
        }
    }
    
    // MARK: - Font Sizes
    enum Size {
        case caption2    // 10pt
        case caption     // 12pt
        case footnote    // 13pt
        case subheadline // 15pt
        case callout     // 16pt
        case body        // 17pt
        case headline    // 17pt (semibold)
        case title3      // 20pt
        case title2      // 22pt
        case title1      // 28pt
        case largeTitle  // 34pt
        
        var pointSize: CGFloat {
            switch self {
            case .caption2: return 10
            case .caption: return 12
            case .footnote: return 13
            case .subheadline: return 15
            case .callout: return 16
            case .body: return 17
            case .headline: return 17
            case .title3: return 20
            case .title2: return 22
            case .title1: return 28
            case .largeTitle: return 34
            }
        }
    }
    
    // MARK: - Predefined Text Styles
    static let largeTitle = Font.system(size: Size.largeTitle.pointSize, weight: Weight.bold.fontWeight, design: .default)
    static let title1 = Font.system(size: Size.title1.pointSize, weight: Weight.bold.fontWeight, design: .default)
    static let title2 = Font.system(size: Size.title2.pointSize, weight: Weight.bold.fontWeight, design: .default)
    static let title3 = Font.system(size: Size.title3.pointSize, weight: Weight.semibold.fontWeight, design: .default)
    
    static let headline = Font.system(size: Size.headline.pointSize, weight: Weight.semibold.fontWeight, design: .default)
    static let body = Font.system(size: Size.body.pointSize, weight: Weight.regular.fontWeight, design: .default)
    static let callout = Font.system(size: Size.callout.pointSize, weight: Weight.regular.fontWeight, design: .default)
    static let subheadline = Font.system(size: Size.subheadline.pointSize, weight: Weight.regular.fontWeight, design: .default)
    static let footnote = Font.system(size: Size.footnote.pointSize, weight: Weight.regular.fontWeight, design: .default)
    static let caption = Font.system(size: Size.caption.pointSize, weight: Weight.regular.fontWeight, design: .default)
    static let caption2 = Font.system(size: Size.caption2.pointSize, weight: Weight.regular.fontWeight, design: .default)
    
    // MARK: - Custom Text Styles
    static let cardTitle = Font.system(size: 16, weight: Weight.semibold.fontWeight, design: .default)
    static let cardSubtitle = Font.system(size: 14, weight: Weight.regular.fontWeight, design: .default)
    static let buttonText = Font.system(size: 16, weight: Weight.semibold.fontWeight, design: .default)
    static let tabBarText = Font.system(size: 10, weight: Weight.medium.fontWeight, design: .default)
    static let searchText = Font.system(size: 16, weight: Weight.regular.fontWeight, design: .default)
    static let priceText = Font.system(size: 18, weight: Weight.bold.fontWeight, design: .default)
    static let ratingText = Font.system(size: 14, weight: Weight.medium.fontWeight, design: .default)
}

// MARK: - View Extensions
extension View {
    func appFont(_ style: Font, color: Color = AppColors.textPrimary) -> some View {
        self.font(style).foregroundColor(color)
    }
    
    func appFont(_ size: AppTypography.Size, weight: AppTypography.Weight = .regular, color: Color = AppColors.textPrimary) -> some View {
        self.font(.system(size: size.pointSize, weight: weight.fontWeight))
            .foregroundColor(color)
    }
}

// MARK: - Additional Font Helpers for Custom Styles
extension Text {
    func cardTitleStyle() -> some View {
        self.font(AppTypography.cardTitle)
            .foregroundColor(AppColors.textPrimary)
    }
    
    func cardSubtitleStyle() -> some View {
        self.font(AppTypography.cardSubtitle)
            .foregroundColor(AppColors.textSecondary)
    }
}

// MARK: - Text Style Presets
extension AppTypography {
    // Common text combinations used throughout the app
    static let spotCardTitle = Font.system(size: 16, weight: .semibold, design: .default)
    static let spotCardSubtitle = Font.system(size: 14, weight: .regular, design: .default)
    static let spotCardPrice = Font.system(size: 15, weight: .semibold, design: .default)
    static let spotCardRating = Font.system(size: 12, weight: .medium, design: .default)
    
    static let searchPlaceholder = Font.system(size: 16, weight: .regular, design: .default)
    static let categoryPill = Font.system(size: 14, weight: .medium, design: .default)
    static let navigationTitle = Font.system(size: 20, weight: .semibold, design: .default)
    
    static let profileName = Font.system(size: 24, weight: .bold, design: .default)
    static let profileBio = Font.system(size: 16, weight: .regular, design: .default)
    static let profileStats = Font.system(size: 14, weight: .semibold, design: .default)
}
