import SwiftUI

/// A custom bottom drawer component with drag gestures and snap detents
struct BottomDrawer<Content: View>: View {
    
    // MARK: - Properties
    
    @Binding var isPresented: Bool
    @Binding var detent: GemDrawerController.DrawerDetent
    let onScrimTap: () -> Void
    let content: () -> Content
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    // MARK: - Constants
    
    private let minHeight: CGFloat = 100
    private let maxHeight: CGFloat = UIScreen.main.bounds.height * 0.95
    private let cornerRadius: CGFloat = 16
    private let handleHeight: CGFloat = 6
    private let handleWidth: CGFloat = 40
    
    // MARK: - Computed Properties
    
    private var currentHeight: CGFloat {
        let baseHeight = detent.height
        return max(minHeight, min(maxHeight, baseHeight + dragOffset))
    }
    
    private var scrimOpacity: Double {
        isPresented ? 0.4 : 0
    }
    
    private var shouldReduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Scrim background
            if isPresented {
                Color.black
                    .opacity(scrimOpacity)
                    .ignoresSafeArea()
                    .onTapGesture {
                        onScrimTap()
                    }
                    .animation(shouldReduceMotion ? .none : .easeInOut(duration: 0.3), value: isPresented)
            }
            
            // Drawer content
            if isPresented {
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        // Handle
                        RoundedRectangle(cornerRadius: handleHeight / 2)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: handleWidth, height: handleHeight)
                            .padding(.top, 12)
                            .padding(.bottom, 8)
                            .accessibilityLabel("Drawer handle")
                            .accessibilityHint("Drag to resize drawer")
                        
                        // Content
                        content()
                            .frame(maxHeight: currentHeight - 50) // Account for handle and padding
                    }
                    .frame(height: currentHeight)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
                    )
                    .offset(y: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDragging = true
                                let translation = value.translation.y
                                
                                // Only allow upward drag when at collapsed
                                if detent == .collapsed {
                                    dragOffset = max(0, translation)
                                } else {
                                    // Allow both directions when not collapsed
                                    dragOffset = translation
                                }
                            }
                            .onEnded { value in
                                isDragging = false
                                handleDragEnd(value)
                            }
                    )
                }
                .transition(.move(edge: .bottom))
                .animation(shouldReduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.8), value: isDragging ? nil : detent)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func handleDragEnd(_ value: DragGesture.Value) {
        let velocity = value.velocity.y
        let translation = value.translation.y
        
        // Determine target detent based on velocity and translation
        let targetDetent: GemDrawerController.DrawerDetent
        
        if velocity > 500 {
            // Fast downward swipe - collapse
            targetDetent = .collapsed
        } else if velocity < -500 {
            // Fast upward swipe - expand
            targetDetent = .expanded
        } else {
            // Slow drag - snap to nearest detent
            let currentHeight = detent.height + translation
            let collapsedHeight = GemDrawerController.DrawerDetent.collapsed.height
            let mediumHeight = GemDrawerController.DrawerDetent.medium.height
            let expandedHeight = GemDrawerController.DrawerDetent.expanded.height
            
            if currentHeight < (collapsedHeight + mediumHeight) / 2 {
                targetDetent = .collapsed
            } else if currentHeight < (mediumHeight + expandedHeight) / 2 {
                targetDetent = .medium
            } else {
                targetDetent = .expanded
            }
        }
        
        // Animate to target detent
        withAnimation(shouldReduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.8)) {
            detent = targetDetent
            dragOffset = 0
        }
    }
}

// MARK: - Preview

#if DEBUG
struct BottomDrawer_Previews: PreviewProvider {
    @State static var isPresented = true
    @State static var detent = GemDrawerController.DrawerDetent.medium
    
    static var previews: some View {
        ZStack {
            Color.blue.ignoresSafeArea()
            
            BottomDrawer(
                isPresented: $isPresented,
                detent: $detent,
                onScrimTap: { isPresented = false }
            ) {
                VStack {
                    Text("Drawer Content")
                        .font(.title2)
                        .padding()
                    
                    Spacer()
                }
            }
        }
    }
}
#endif
