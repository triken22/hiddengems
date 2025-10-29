import SwiftUI
import MapKit
import CoreLocation

/// Quick add sheet for long-press on map - optimized for keyboard and UX
struct QuickAddLocationSheet: View {
    let coordinate: CLLocationCoordinate2D
    let onDismiss: () -> Void
    
    @EnvironmentObject private var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var details = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var address: String?
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title, details
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Location Preview Card
                    LocationPreviewCard(coordinate: coordinate, address: address)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.md)
                    
                    // Form Fields
                    VStack(spacing: AppSpacing.md) {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Name this spot *")
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("e.g., Secret Beach, Hidden Cafe", text: $title)
                                .focused($focusedField, equals: .title)
                                .textFieldStyle(CustomTextFieldStyle())
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .details
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Description (optional)")
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("What makes this place special?", text: $details, axis: .vertical)
                                .focused($focusedField, equals: .details)
                                .textFieldStyle(CustomTextFieldStyle(minHeight: 80))
                                .lineLimit(3...6)
                                .submitLabel(.done)
                                .onSubmit {
                                    if !title.isEmpty {
                                        saveSpot()
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    
                    // Save Button (above keyboard)
                    Button(action: saveSpot) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Saving...")
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save This Spot")
                            }
                        }
                        .font(AppTypography.buttonText)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(title.isEmpty ? AppColors.textTertiary : AppColors.primary)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                    }
                    .disabled(title.isEmpty || isSaving)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
            .navigationTitle("Add Hidden Gem")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            focusedField = nil
                        }
                        .foregroundColor(AppColors.primary)
                    }
                }
            }
        }
        .task {
            await reverseGeocodeLocation()
            // Auto-focus title field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = .title
            }
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
        
        focusedField = nil // Dismiss keyboard
        isSaving = true
        
        Task {
            do {
                let spot = Spot(
                    id: UUID().uuidString,
                    title: title,
                    subtitle: nil,
                    details: details.isEmpty ? "Added from map" : details,
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

// MARK: - Location Preview Card
struct LocationPreviewCard: View {
    let coordinate: CLLocationCoordinate2D
    let address: String?
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Map Preview
            Map(position: .constant(.region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )))) {
                Annotation("", coordinate: coordinate) {
                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        )
                }
            }
            .frame(height: 120)
            .cornerRadius(AppSpacing.cardCornerRadius)
            .allowsHitTesting(false)
            
            // Location Info
            VStack(spacing: AppSpacing.xs) {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(AppColors.primary)
                        .font(.system(size: 16))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        if let address = address {
                            Text(address)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textPrimary)
                        } else {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Finding address...")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        
                        Text("\(coordinate.latitude, specifier: "%.5f"), \(coordinate.longitude, specifier: "%.5f")")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    
                    Spacer()
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.cardCornerRadius)
        }
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    var minHeight: CGFloat = 44
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .frame(minHeight: minHeight)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.buttonCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius)
                    .stroke(AppColors.border, lineWidth: 1)
            )
    }
}

#Preview {
    QuickAddLocationSheet(
        coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    ) {
        // Preview dismiss
    }
    .environmentObject(AppEnvironment().homeViewModel)
}

