import SwiftUI

/// Custom tab bar with Airbnb-style design
struct CustomTabBar: View {
    @Binding var selectedTab: TabItem
    let tabs: [TabItem]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.id) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab.id == tab.id
                ) {
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tab
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.top, AppSpacing.md)
        .padding(.bottom, AppSpacing.sm)
        .background(AppColors.surfaceElevated)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: -2)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let tab: TabItem
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(iconColor)
                    .scaleEffect(isPressed ? 0.85 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                
                Text(tab.title)
                    .font(AppTypography.tabBarText)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(height: 56)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isSelected ? "Currently selected" : "Tap to switch to \(tab.title)")
        .accessibilityElement(children: .combine)
    }
    
    private var iconColor: Color {
        isSelected ? AppColors.primary : AppColors.textTertiary
    }
    
    private var textColor: Color {
        isSelected ? AppColors.primary : AppColors.textTertiary
    }
}

// MARK: - Tab Item Model
struct TabItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let icon: String
    let selectedIcon: String
    let tag: Int
    
    init(title: String, icon: String, selectedIcon: String? = nil, tag: Int) {
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon ?? icon
        self.tag = tag
    }
    
    static func == (lhs: TabItem, rhs: TabItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Tab Bar Container
struct TabBarContainer<Content: View>: View {
    @Binding var selectedTab: TabItem
    let tabs: [TabItem]
    let content: (TabItem) -> Content
    
    init(
        selectedTab: Binding<TabItem>,
        tabs: [TabItem],
        @ViewBuilder content: @escaping (TabItem) -> Content
    ) {
        self._selectedTab = selectedTab
        self.tabs = tabs
        self.content = content
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            content(selectedTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            VStack(spacing: 0) {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab, tabs: tabs)
                    .background(AppColors.surfaceElevated)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 0)
        }
    }
}

// MARK: - Tab Bar Hide on Scroll
struct TabBarHideOnScrollModifier: ViewModifier {
    @Binding var isHidden: Bool
    let threshold: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scroll")).minY
                        )
                }
            )
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                withAnimation(.easeInOut(duration: 0.3)) {
                    isHidden = value < -threshold
                }
            }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    func hideTabBarOnScroll(_ isHidden: Binding<Bool>, threshold: CGFloat = 100) -> some View {
        self.modifier(TabBarHideOnScrollModifier(isHidden: isHidden, threshold: threshold))
    }
}

// MARK: - Preview
#if DEBUG
struct CustomTabBar_Previews: PreviewProvider {
    static let tabs = [
        TabItem(title: "Explore", icon: "house", selectedIcon: "house.fill", tag: 0),
        TabItem(title: "Map", icon: "map", selectedIcon: "map.fill", tag: 1),
        TabItem(title: "Saved", icon: "heart", selectedIcon: "heart.fill", tag: 2),
        TabItem(title: "Profile", icon: "person", selectedIcon: "person.fill", tag: 3)
    ]
    
    static var previews: some View {
        TabBarContainer(selectedTab: .constant(tabs[0]), tabs: tabs) { tab in
            VStack {
                Text("\(tab.title) View")
                    .appFont(.title1)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.background)
        }
        .previewLayout(.sizeThatFits)
    }
}
#endif
