import SwiftUI
import UIKit

/// Reusable action bar for spot interactions
struct SpotActionBar: View {
    
    // MARK: - Properties
    
    let spot: Spot
    let onNavigate: () -> Void
    let onSave: () -> Void
    let onShare: () -> Void
    let onAddToCollection: () -> Void
    let onRate: (Double) -> Void
    
    @State private var showingRatingSheet = false
    @State private var currentRating: Double = 0
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // Navigate button
            actionButton(
                icon: "location.fill",
                title: "Navigate",
                color: .blue,
                action: onNavigate
            )
            
            // Save button
            actionButton(
                icon: spot.saved ? "heart.fill" : "heart",
                title: spot.saved ? "Saved" : "Save",
                color: spot.saved ? .red : .blue,
                action: onSave
            )
            
            // Share button
            actionButton(
                icon: "square.and.arrow.up",
                title: "Share",
                color: .blue,
                action: onShare
            )
            
            // Rate button
            actionButton(
                icon: "star.fill",
                title: spot.globalRating > 0 ? String(format: "%.1f", spot.globalRating) : "Rate",
                color: spot.globalRating > 0 ? .orange : .blue,
                action: {
                    currentRating = spot.globalRating
                    showingRatingSheet = true
                }
            )
            
            // Add to collection button
            actionButton(
                icon: "folder.badge.plus",
                title: "Collection",
                color: .green,
                action: onAddToCollection
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .sheet(isPresented: $showingRatingSheet) {
            RatingSheet(
                currentRating: $currentRating,
                onSave: { rating in
                    onRate(rating)
                    showingRatingSheet = false
                },
                onCancel: {
                    showingRatingSheet = false
                }
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func actionButton(
        icon: String,
        title: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Rating Sheet

struct RatingSheet: View {
    @Binding var currentRating: Double
    let onSave: (Double) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("Rate this spot")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("How would you rate your experience?")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 16) {
                    // Star rating display
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(currentRating) ? "star.fill" : "star")
                                .font(.system(size: 32))
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    // Rating value
                    Text(String(format: "%.1f", currentRating))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                // Slider
                VStack(spacing: 8) {
                    Slider(
                        value: $currentRating,
                        in: 0...5,
                        step: 0.5
                    )
                    .accentColor(.yellow)
                    
                    HStack {
                        Text("0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("5")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("Rate Spot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(currentRating)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct SpotActionBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SpotActionBar(
                spot: Spot(
                    id: "preview",
                    title: "Beautiful Sunset Point",
                    subtitle: "Perfect for photography",
                    details: "This hidden gem offers stunning sunset views",
                    latitude: 37.7749,
                    longitude: -122.4194,
                    address: "123 Ocean View Drive",
                    tags: ["sunset", "photography"],
                    topics: ["nature"],
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
                onNavigate: {},
                onSave: {},
                onShare: {},
                onAddToCollection: {},
                onRate: { _ in }
            )
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif

