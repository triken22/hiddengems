import SwiftUI

/// Airbnb-inspired color palette for HiddenGems
struct AppColors {
    // MARK: - Primary Colors
    static let primary = Color(hex: "#FF385C") // Airbnb red
    static let primaryLight = Color(hex: "#FF5A7F")
    static let primaryDark = Color(hex: "#E31C5F")
    
    // MARK: - Background Colors
    static let background = Color(hex: "#FFFFFF")
    static let surface = Color(hex: "#F7F7F7")
    static let surfaceElevated = Color(hex: "#FFFFFF")
    
    // MARK: - Text Colors
    static let textPrimary = Color(hex: "#222222")
    static let textSecondary = Color(hex: "#717171")
    static let textTertiary = Color(hex: "#B0B0B0")
    static let textInverse = Color(hex: "#FFFFFF")
    
    // MARK: - Border Colors
    static let border = Color(hex: "#DDDDDD")
    static let borderLight = Color(hex: "#F0F0F0")
    static let borderDark = Color(hex: "#CCCCCC")
    
    // MARK: - Status Colors
    static let success = Color(hex: "#008A05")
    static let warning = Color(hex: "#C13515")
    static let error = Color(hex: "#C13515")
    static let info = Color(hex: "#0066CC")
    
    // MARK: - Overlay Colors
    static let overlay = Color.black.opacity(0.4)
    static let overlayLight = Color.black.opacity(0.2)
    static let overlayDark = Color.black.opacity(0.6)
    
    // MARK: - Gradient Colors
    static let primaryGradient = LinearGradient(
        colors: [primary, primaryLight],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let surfaceGradient = LinearGradient(
        colors: [surface, background],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Color Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Semantic Color Names
extension AppColors {
    // For better semantic meaning in UI
    static let accent = primary
    static let destructive = error
    static let secondary = textSecondary
    static let muted = textTertiary
}
