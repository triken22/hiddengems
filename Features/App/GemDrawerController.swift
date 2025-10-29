import Foundation
import Combine
import SwiftUI

/// Controller for managing the gem details drawer presentation and state
@MainActor
class GemDrawerController: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isPresented = false
    @Published var detent: DrawerDetent = .collapsed
    @Published var selectedIndex = 0
    @Published var source: DrawerSource = .explore
    @Published var spots: [Spot] = []
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Enums
    
    enum DrawerDetent: CaseIterable {
        case collapsed
        case medium
        case expanded
        
        var height: CGFloat {
            switch self {
            case .collapsed:
                return 140
            case .medium:
                return UIScreen.main.bounds.height * 0.5
            case .expanded:
                return UIScreen.main.bounds.height * 0.9
            }
        }
    }
    
    enum DrawerSource: CaseIterable {
        case explore
        case map
        case saved
    }
    
    // MARK: - Initialization
    
    init() {
        setupHapticFeedback()
    }
    
    // MARK: - Public Methods
    
    /// Present the drawer with a list of spots
    func present(spots: [Spot], startAt index: Int, source: DrawerSource) {
        guard !spots.isEmpty, index >= 0, index < spots.count else { return }
        
        self.spots = spots
        self.selectedIndex = index
        self.source = source
        self.detent = .collapsed
        self.isPresented = true
        
        // Haptic feedback for presentation
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    /// Dismiss the drawer
    func dismiss() {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.isPresented = false
        }
        
        // Haptic feedback for dismissal
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    /// Move to a specific spot index
    func move(to index: Int) {
        guard index >= 0, index < spots.count else { return }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            self.selectedIndex = index
        }
        
        // Haptic feedback for page change
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
    
    /// Move to next spot
    func next() {
        let nextIndex = min(selectedIndex + 1, spots.count - 1)
        move(to: nextIndex)
    }
    
    /// Move to previous spot
    func prev() {
        let prevIndex = max(selectedIndex - 1, 0)
        move(to: prevIndex)
    }
    
    /// Update detent with animation
    func updateDetent(_ newDetent: DrawerDetent) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            self.detent = newDetent
        }
        
        // Haptic feedback for detent change
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    /// Get current spot
    var currentSpot: Spot? {
        guard selectedIndex >= 0, selectedIndex < spots.count else { return nil }
        return spots[selectedIndex]
    }
    
    /// Check if can move to next spot
    var canMoveNext: Bool {
        selectedIndex < spots.count - 1
    }
    
    /// Check if can move to previous spot
    var canMovePrev: Bool {
        selectedIndex > 0
    }
    
    // MARK: - Private Methods
    
    private func setupHapticFeedback() {
        // Configure haptic feedback generators for better performance
        UIImpactFeedbackGenerator().prepare()
        UISelectionFeedbackGenerator().prepare()
    }
}

// MARK: - Preview Support

#if DEBUG
extension GemDrawerController {
    static let preview = GemDrawerController()
}
#endif

