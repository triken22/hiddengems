import SwiftUI
import MapKit

/// Compact spot detail view optimized for the drawer
struct SpotDetailCompactView: View {
    
    // MARK: - Properties
    
    let spot: Spot
    let onOpenFullDetails: () -> Void
    let onNavigate: () -> Void
    let onSave: () -> Void
    let onShare: () -> Void
    let onRate: (Double) -> Void
    
    @State private var showingFullDetails = false
    
    // MARK: - Constants
    
    private let imageHeight: CGFloat = 200
    private let cornerRadius: CGFloat = 12
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Hero image
                heroImageView
                
                // Content
                VStack(alignment: .leading, spacing: 12) {
                    // Title and rating
                    titleAndRatingView
                    
                    // Distance and address
                    locationInfoView
                    
                    // Tags
                    if !spot.tags.isEmpty {
                        tagsView
                    }
                    
                    // Brief details
                    if !spot.details.isEmpty {
                        detailsView
                    }
                    
                    // Action bar
                    actionBarView
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Subviews
    
    private var heroImageView: some View {
        AsyncImage(url: URL(string: spot.images.first ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                )
        }
        .frame(height: imageHeight)
        .clipped()
        .cornerRadius(cornerRadius, corners: [.topLeft, .topRight])
        .overlay(
            // Gradient overlay for better text readability
            LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.3)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .cornerRadius(cornerRadius, corners: [.topLeft, .topRight])
        )
    }
    
    private var titleAndRatingView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(spot.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                if spot.globalRating > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        
                        Text(String(format: "%.1f", spot.globalRating))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(8)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Rating \(String(format: "%.1f", spot.globalRating)) stars")
                }
            }
            
            if !spot.subtitle.isEmpty {
                Text(spot.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Subtitle: \(spot.subtitle)")
            }
        }
    }
    
    private var locationInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Text(spot.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let distance = spot.formattedDistance {
                    Text(distance)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private var tagsView: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 80), spacing: 8)
        ], spacing: 8) {
            ForEach(spot.tags.prefix(6), id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)
            }
        }
    }
    
    private var detailsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About this spot")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(spot.details)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            Button("View more") {
                onOpenFullDetails()
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
    }
    
    private var actionBarView: some View {
        HStack(spacing: 16) {
            // Navigate button
            Button(action: onNavigate) {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                    Text("Navigate")
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .cornerRadius(20)
            }
            .accessibilityLabel("Navigate to \(spot.title)")
            .accessibilityHint("Opens Apple Maps with directions to this location")
            
            // Save button
            Button(action: onSave) {
                HStack(spacing: 6) {
                    Image(systemName: spot.saved ? "heart.fill" : "heart")
                    Text(spot.saved ? "Saved" : "Save")
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(spot.saved ? .red : .blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(spot.saved ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                .cornerRadius(20)
            }
            .accessibilityLabel(spot.saved ? "Remove from saved" : "Save spot")
            .accessibilityHint(spot.saved ? "Tap to unsave this spot" : "Tap to save this spot")
            
            // Share button
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)
            }
            .accessibilityLabel("Share spot")
            .accessibilityHint("Opens share sheet to share this spot")
            
            Spacer()
            
            // Open full details button
            Button("Full Details") {
                onOpenFullDetails()
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.blue)
            .accessibilityLabel("Open full details")
            .accessibilityHint("Opens detailed view of this spot")
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Extensions

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
struct SpotDetailCompactView_Previews: PreviewProvider {
    static var previews: some View {
        SpotDetailCompactView(
            spot: Spot(
                id: "preview",
                title: "Beautiful Sunset Point",
                subtitle: "Perfect for photography",
                details: "This hidden gem offers stunning sunset views over the ocean. The golden hour light creates magical reflections on the water, making it a favorite spot for photographers and nature lovers alike.",
                latitude: 37.7749,
                longitude: -122.4194,
                address: "123 Ocean View Drive, San Francisco, CA",
                tags: ["sunset", "photography", "ocean", "nature", "scenic"],
                topics: ["nature", "photography"],
                images: ["https://example.com/sunset.jpg"],
                userId: "user123",
                groupId: "group123",
                isMarkedDeleted: false,
                version: 1,
                createdAt: Date(),
                updatedAt: Date(),
                globalRating: 4.5,
                ratingUpdatedAt: Date(),
                saved: false
            ),
            onOpenFullDetails: {},
            onNavigate: {},
            onSave: {},
            onShare: {},
            onRate: { _ in }
        )
        .previewLayout(.sizeThatFits)
    }
}
#endif
