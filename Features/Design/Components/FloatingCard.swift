import SwiftUI

/// A floating card component with elevation and shadow
struct FloatingCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let shadowStyle: ShadowStyle
    let padding: EdgeInsets
    
    init(
        cornerRadius: CGFloat = AppSpacing.cardCornerRadius,
        shadowStyle: ShadowStyle = .card,
        padding: EdgeInsets = AppSpacing.cardContentPadding,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.shadowStyle = shadowStyle
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(AppColors.surfaceElevated)
            .cornerRadius(cornerRadius)
            .shadow(
                color: shadowStyle.color,
                radius: shadowStyle.radius,
                x: shadowStyle.offsetX,
                y: shadowStyle.offsetY
            )
    }
}

// MARK: - Shadow Styles
enum ShadowStyle {
    case card
    case button
    case floating
    case none
    
    var color: Color {
        switch self {
        case .card:
            return AppSpacing.cardShadow.color
        case .button:
            return AppSpacing.buttonShadow.color
        case .floating:
            return AppSpacing.floatingShadow.color
        case .none:
            return Color.clear
        }
    }
    
    var radius: CGFloat {
        switch self {
        case .card:
            return AppSpacing.cardShadow.radius
        case .button:
            return AppSpacing.buttonShadow.radius
        case .floating:
            return AppSpacing.floatingShadow.radius
        case .none:
            return 0
        }
    }
    
    var offsetX: CGFloat {
        switch self {
        case .card:
            return AppSpacing.cardShadow.x
        case .button:
            return AppSpacing.buttonShadow.x
        case .floating:
            return AppSpacing.floatingShadow.x
        case .none:
            return 0
        }
    }
    
    var offsetY: CGFloat {
        switch self {
        case .card:
            return AppSpacing.cardShadow.y
        case .button:
            return AppSpacing.buttonShadow.y
        case .floating:
            return AppSpacing.floatingShadow.y
        case .none:
            return 0
        }
    }
}

// MARK: - Card Variants
struct InfoCard: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let action: (() -> Void)?
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        FloatingCard {
            HStack(spacing: AppSpacing.md) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(AppColors.primary)
                        .frame(width: 24, height: 24)
                }
                
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .font(AppTypography.cardTitle)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppTypography.cardSubtitle)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
        .onTapGesture {
            action?()
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String?
    let color: Color
    
    init(
        value: String,
        label: String,
        icon: String? = nil,
        color: Color = AppColors.primary
    ) {
        self.value = value
        self.label = label
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        FloatingCard {
            VStack(spacing: AppSpacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                Text(value)
                    .appFont(.title2, weight: .bold, color: AppColors.textPrimary)
                
                Text(label)
                    .appFont(.caption, color: AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct FloatingCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            FloatingCard {
                Text("Basic Card Content")
                    .appFont(.body)
            }
            
            InfoCard(
                title: "Settings",
                subtitle: "Manage your preferences",
                icon: "gearshape.fill"
            ) {
                print("Tapped settings")
            }
            
            HStack(spacing: 12) {
                StatCard(
                    value: "24",
                    label: "Spots Discovered",
                    icon: "location.fill"
                )
                
                StatCard(
                    value: "156",
                    label: "Photos Taken",
                    icon: "camera.fill",
                    color: AppColors.success
                )
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
