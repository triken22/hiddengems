import SwiftUI
import MapKit
import CoreLocation

/// View for adding a new spot at a selected map location
struct AddLocationView: View {
    let coordinate: CLLocationCoordinate2D
    let onDismiss: () -> Void
    
    @EnvironmentObject private var viewModel: HomeViewModel
    @State private var title = ""
    @State private var subtitle = ""
    @State private var details = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var address: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Add New Spot")
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Add a hidden gem at this location")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.top, AppSpacing.lg)
                    
                    // Location Preview
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Location")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(AppColors.primary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Lat: \(coordinate.latitude, specifier: "%.4f")")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                Text("Lng: \(coordinate.longitude, specifier: "%.4f")")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            if let address = address {
                                Text(address)
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                    .multilineTextAlignment(.trailing)
                            } else {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        .padding(AppSpacing.md)
                        .background(AppColors.surfaceElevated)
                        .cornerRadius(AppSpacing.cardCornerRadius)
                    }
                    
                    // Form Fields
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Title *")
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("Enter spot title", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(AppTypography.body)
                        }
                        
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Subtitle")
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("Enter subtitle (optional)", text: $subtitle)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(AppTypography.body)
                        }
                        
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Details")
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("Describe this hidden gem", text: $details, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(AppTypography.body)
                                .lineLimit(3...6)
                        }
                    }
                    
                    Spacer(minLength: AppSpacing.xl)
                }
                .padding(.horizontal, AppSpacing.lg)
            }
            .navigationTitle("Add Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSpot()
                    }
                    .disabled(title.isEmpty || isSaving)
                    .foregroundColor(title.isEmpty ? AppColors.textSecondary : AppColors.primary)
                }
            }
        }
        .task {
            await reverseGeocodeLocation()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func saveSpot() {
        guard !title.isEmpty else { return }
        
        isSaving = true
        
        Task {
            do {
                let spot = Spot(
                    id: UUID().uuidString,
                    title: title,
                    subtitle: subtitle.isEmpty ? nil : subtitle,
                    details: details,
                    coordinate: coordinate,
                    address: address,
                    tags: [],
                    topics: [],
                    images: [],
                    groupId: nil,
                    userId: nil,
                    deleted: false,
                    version: 0,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                try await viewModel.spotRepository.save(spot: spot)
                
                await MainActor.run {
                    isSaving = false
                    onDismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func reverseGeocodeLocation() async {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                let components = [
                    placemark.name,
                    placemark.locality,
                    placemark.administrativeArea
                ].compactMap { $0 }
                
                await MainActor.run {
                    address = components.joined(separator: ", ")
                }
            }
        } catch {
            // Silently fail - address is optional
        }
    }
}

#Preview {
    AddLocationView(
        coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    ) {
        // Preview dismiss action
    }
    .environmentObject(AppEnvironment().homeViewModel)
}
