import SwiftUI

/// A pill-shaped button component for categories and filters
struct PillButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(
        title: String,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                action()
            }
        }) {
            Text(title)
                .font(AppTypography.categoryPill)
                .foregroundColor(textColor)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.sm)
                .background(backgroundColor)
                .cornerRadius(AppSpacing.pillCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.pillCornerRadius)
                        .stroke(borderColor, lineWidth: 1)
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return AppColors.primary
        } else {
            return AppColors.surface
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return AppColors.textInverse
        } else {
            return AppColors.textPrimary
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return AppColors.primary
        } else {
            return AppColors.border
        }
    }
}

// MARK: - Pill Button Group
struct PillButtonGroup: View {
    let items: [String]
    @Binding var selectedItem: String?
    let onSelectionChanged: (String?) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(items, id: \.self) { item in
                    PillButton(
                        title: item,
                        isSelected: selectedItem == item
                    ) {
                        if selectedItem == item {
                            selectedItem = nil
                            onSelectionChanged(nil)
                        } else {
                            selectedItem = item
                            onSelectionChanged(item)
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }
}

// MARK: - Preview
#if DEBUG
struct PillButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                PillButton(title: "All", isSelected: true) {}
                PillButton(title: "Restaurants", isSelected: false) {}
                PillButton(title: "Parks", isSelected: false) {}
            }
            
            PillButtonGroup(
                items: ["All", "Restaurants", "Parks", "Museums", "Beaches", "Mountains"],
                selectedItem: .constant("Restaurants")
            ) { _ in }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
