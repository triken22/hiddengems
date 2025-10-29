import SwiftUI

/// Airbnb-inspired spacing system for HiddenGems
struct AppSpacing {
    
    // MARK: - Base Spacing Scale (4pt grid system)
    static let xs: CGFloat = 4      // 4pt
    static let sm: CGFloat = 8      // 8pt
    static let md: CGFloat = 12     // 12pt
    static let lg: CGFloat = 16     // 16pt
    static let xl: CGFloat = 20     // 20pt
    static let xxl: CGFloat = 24    // 24pt
    static let xxxl: CGFloat = 32   // 32pt
    static let xxxxl: CGFloat = 40  // 40pt
    static let xxxxxl: CGFloat = 48 // 48pt
    
    // MARK: - Semantic Spacing
    static let cardPadding = lg
    static let cardSpacing = md
    static let sectionSpacing = xxl
    static let itemSpacing = sm
    static let buttonPadding = md
    static let inputPadding = lg
    
    // MARK: - Layout Spacing
    static let screenPadding = lg
    static let tabBarHeight: CGFloat = 84
    static let navigationBarHeight: CGFloat = 44
    static let searchBarHeight: CGFloat = 44
    static let cardCornerRadius: CGFloat = 12
    static let buttonCornerRadius: CGFloat = 8
    static let pillCornerRadius: CGFloat = 20
    
    // MARK: - Shadow Values
    static let shadowRadius: CGFloat = 8
    static let shadowOpacity: Double = 0.1
    static let shadowOffsetSize = CGSize(width: 0, height: 2)
    
    static let cardShadow = Shadow(
        color: .black.opacity(shadowOpacity),
        radius: shadowRadius,
        x: shadowOffsetSize.width,
        y: shadowOffsetSize.height
    )
    
    static let buttonShadow = Shadow(
        color: .black.opacity(0.15),
        radius: 4,
        x: 0,
        y: 2
    )
    
    static let floatingShadow = Shadow(
        color: .black.opacity(0.2),
        radius: 12,
        x: 0,
        y: 4
    )
}

// MARK: - Shadow Helper
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extensions
extension View {
    func appPadding(_ spacing: CGFloat = AppSpacing.lg) -> some View {
        self.padding(spacing)
    }
    
    func appPadding(_ edges: Edge.Set = .all, _ spacing: CGFloat = AppSpacing.lg) -> some View {
        self.padding(edges, spacing)
    }
    
    func appCardStyle() -> some View {
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
    
    func appButtonStyle() -> some View {
        self
            .cornerRadius(AppSpacing.buttonCornerRadius)
            .shadow(
                color: AppSpacing.buttonShadow.color,
                radius: AppSpacing.buttonShadow.radius,
                x: AppSpacing.buttonShadow.x,
                y: AppSpacing.buttonShadow.y
            )
    }
    
    func appFloatingStyle() -> some View {
        self
            .shadow(
                color: AppSpacing.floatingShadow.color,
                radius: AppSpacing.floatingShadow.radius,
                x: AppSpacing.floatingShadow.x,
                y: AppSpacing.floatingShadow.y
            )
    }
}

// MARK: - Layout Helpers
extension AppSpacing {
    // Common layout combinations
    static let cardContentPadding = EdgeInsets(
        top: cardPadding,
        leading: cardPadding,
        bottom: cardPadding,
        trailing: cardPadding
    )
    
    static let screenContentPadding = EdgeInsets(
        top: screenPadding,
        leading: screenPadding,
        bottom: screenPadding,
        trailing: screenPadding
    )
    
    static let listItemPadding = EdgeInsets(
        top: md,
        leading: lg,
        bottom: md,
        trailing: lg
    )
    
    static let searchBarPadding = EdgeInsets(
        top: sm,
        leading: lg,
        bottom: sm,
        trailing: lg
    )
}
