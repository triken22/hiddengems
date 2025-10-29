import SwiftUI
import MapKit

/// Custom map marker for spots with Airbnb-style design
struct SpotMapMarker: View {
    let spot: Spot
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Marker pin
                ZStack {
                    Circle()
                        .fill(markerColor)
                        .frame(width: 40, height: 40)
                        .shadow(
                            color: Color.black.opacity(0.3),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                    
                    if let imageURL = spot.images.first?.remoteURL {
                        AsyncImage(url: imageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        } placeholder: {
                            Image(systemName: "location.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                    } else {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                
                // Marker tail
                Triangle()
                    .fill(markerColor)
                    .frame(width: 12, height: 8)
                    .offset(y: -2)
            }
        }
        .scaleEffect(isPressed ? 0.9 : (isSelected ? 1.2 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    private var markerColor: Color {
        if isSelected {
            return AppColors.primary
        } else {
            return AppColors.success
        }
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Cluster Marker
struct ClusterMarker: View {
    let count: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(isSelected ? AppColors.primary : AppColors.warning)
                    .frame(width: 50, height: 50)
                    .shadow(
                        color: Color.black.opacity(0.3),
                        radius: 6,
                        x: 0,
                        y: 3
                    )
                
                Text("\(count)")
                    .appFont(.callout, weight: .bold, color: .white)
            }
        }
        .scaleEffect(isPressed ? 0.9 : (isSelected ? 1.1 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Map Bottom Sheet
struct MapBottomSheet: View {
    let spot: Spot?
    let onDismiss: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var isExpanded = false
    
    private let minHeight: CGFloat = 120
    private let maxHeight: CGFloat = 400
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2)
                .fill(AppColors.border)
                .frame(width: 40, height: 4)
                .padding(.top, AppSpacing.sm)
            
            if let spot = spot {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    // Spot info
                    HStack(alignment: .top, spacing: AppSpacing.md) {
                        RoundedImageView(
                            imageURL: spot.images.first?.remoteURL,
                            placeholder: "photo",
                            aspectRatio: 1.0
                        )
                        .frame(width: 80, height: 80)
                        
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(spot.title)
                                .appFont(.headline, color: AppColors.textPrimary)
                                .lineLimit(2)
                            
                            if let subtitle = spot.subtitle {
                                Text(subtitle)
                                    .appFont(.callout, color: AppColors.textSecondary)
                                    .lineLimit(1)
                            }
                            
                            HStack {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(AppColors.warning)
                                Text("4.8")
                                    .appFont(.caption, color: AppColors.textSecondary)
                                
                                Spacer()
                                
                                Text("2.5 km")
                                    .appFont(.caption, color: AppColors.textSecondary)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // Action buttons
                    HStack(spacing: AppSpacing.md) {
                        Button(action: {
                            // Handle directions
                        }) {
                            HStack {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                Text("Directions")
                                    .appFont(.callout, color: AppColors.primary)
                            }
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.vertical, AppSpacing.sm)
                            .background(AppColors.primary.opacity(0.1))
                            .cornerRadius(AppSpacing.buttonCornerRadius)
                        }
                        
                        Button(action: {
                            // Handle save
                        }) {
                            HStack {
                                Image(systemName: "heart")
                                    .font(.caption)
                                Text("Save")
                                    .appFont(.callout, color: AppColors.primary)
                            }
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.vertical, AppSpacing.sm)
                            .background(AppColors.primary.opacity(0.1))
                            .cornerRadius(AppSpacing.buttonCornerRadius)
                        }
                        
                        Spacer()
                    }
                }
                .padding(AppSpacing.lg)
            } else {
                // Empty state
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "location.slash")
                        .font(.title)
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text("Select a spot to see details")
                        .appFont(.callout, color: AppColors.textSecondary)
                }
                .padding(AppSpacing.xl)
            }
        }
        .background(AppColors.surfaceElevated)
        .cornerRadius(AppSpacing.cardCornerRadius, corners: [.topLeft, .topRight])
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 8,
            x: 0,
            y: -2
        )
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.height
                }
                .onEnded { value in
                    withAnimation(.spring()) {
                        if value.translation.height > 50 {
                            onDismiss()
                        } else {
                            dragOffset = 0
                        }
                    }
                }
        )
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview
#if DEBUG
struct SpotMapMarker_Previews: PreviewProvider {
    static let sampleSpot = Spot(
        id: "1",
        title: "Secret Garden Cafe",
        subtitle: "Hidden coffee shop",
        details: "A charming cafe",
        coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        address: "123 Hidden Lane",
        tags: ["Coffee"],
        topics: ["Food & Drink"],
        images: [],
        groupId: nil,
        userId: nil,
        deleted: false,
        version: 1,
        createdAt: Date(),
        updatedAt: Date()
    )
    
    static var previews: some View {
        VStack(spacing: 20) {
            SpotMapMarker(spot: sampleSpot, isSelected: false) {}
            SpotMapMarker(spot: sampleSpot, isSelected: true) {}
            ClusterMarker(count: 5, isSelected: false) {}
            MapBottomSheet(spot: sampleSpot) {}
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
