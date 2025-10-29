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
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tab
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.lg)
        .background(
            Rectangle()
                .fill(AppColors.surfaceElevated)
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 8,
                    x: 0,
                    y: -2
                )
        )
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
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconColor)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                
                Text(tab.title)
                    .font(AppTypography.tabBarText)
                    .foregroundColor(textColor)
                    .lineLimit(1)
            }
            .frame(height: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
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
