import SwiftUI

/// Loading states and skeleton loaders for the app
struct LoadingView: View {
    let style: LoadingStyle
    let message: String?
    
    init(style: LoadingStyle = .spinner, message: String? = nil) {
        self.style = style
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            switch style {
            case .spinner:
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                
            case .dots:
                DotsLoadingView()
                
            case .pulse:
                PulseLoadingView()
            }
            
            if let message = message {
                Text(message)
                    .appFont(.callout, color: AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

// MARK: - Loading Styles
enum LoadingStyle {
    case spinner
    case dots
    case pulse
}

// MARK: - Dots Loading Animation
struct DotsLoadingView: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 8, height: 8)
                    .offset(y: animationOffset)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animationOffset
                    )
            }
        }
        .onAppear {
            animationOffset = -10
        }
    }
}

// MARK: - Pulse Loading Animation
struct PulseLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(AppColors.primary.opacity(0.3))
            .frame(width: 40, height: 40)
            .scaleEffect(isAnimating ? 1.2 : 0.8)
            .opacity(isAnimating ? 0.3 : 0.8)
            .animation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Skeleton Loader
struct SkeletonView: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat
    
    @State private var isAnimating = false
    
    init(
        width: CGFloat? = nil,
        height: CGFloat = 20,
        cornerRadius: CGFloat = 4
    ) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        AppColors.surface,
                        AppColors.borderLight,
                        AppColors.surface
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius)
            .opacity(isAnimating ? 0.3 : 0.7)
            .animation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Skeleton Card
struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SkeletonView(width: nil, height: 200, cornerRadius: AppSpacing.cardCornerRadius)
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                SkeletonView(width: 150, height: 16)
                SkeletonView(width: 100, height: 14)
                SkeletonView(width: 80, height: 12)
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surfaceElevated)
        .cornerRadius(AppSpacing.cardCornerRadius)
        .shadow(
            color: AppSpacing.cardShadow.color,
            radius: AppSpacing.cardShadow.radius,
            x: AppSpacing.cardShadow.x,
            y: AppSpacing.cardShadow.y
        )
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(AppColors.textTertiary)
            
            VStack(spacing: AppSpacing.sm) {
                Text(title)
                    .appFont(.title3, weight: .semibold, color: AppColors.textPrimary)
                
                Text(message)
                    .appFont(.body, color: AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppTypography.buttonText)
                        .foregroundColor(AppColors.textInverse)
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.primary)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                }
            }
        }
        .padding(AppSpacing.xxl)
    }
}

// MARK: - Preview
#if DEBUG
struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            LoadingView(style: .spinner, message: "Loading spots...")
                .frame(height: 100)
            
            LoadingView(style: .dots)
                .frame(height: 50)
            
            SkeletonCard()
                .frame(height: 300)
            
            EmptyStateView(
                icon: "location.slash",
                title: "No spots found",
                message: "Try adjusting your search or explore a new area",
                actionTitle: "Explore Map"
            ) {
                print("Explore tapped")
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
