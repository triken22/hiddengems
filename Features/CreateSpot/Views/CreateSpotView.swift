import SwiftUI
import PhotosUI
import CoreLocation

/// Multi-step spot creation flow with photo emphasis
struct CreateSpotView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateSpotViewModel
    
    init(viewModel: CreateSpotViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress Indicator
                    ProgressIndicatorView(
                        currentStep: viewModel.currentStep,
                        totalSteps: viewModel.totalSteps
                    )
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.sm)
                    
                    // Content
                    TabView(selection: $viewModel.currentStep) {
                        // Step 1: Photos
                        PhotoSelectionView(
                            selectedImages: $viewModel.selectedImages,
                            onNext: viewModel.nextStep
                        )
                        .tag(1)
                        
                        // Step 2: Details
                        SpotDetailsFormView(
                            title: $viewModel.title,
                            subtitle: $viewModel.subtitle,
                            details: $viewModel.details,
                            onNext: viewModel.nextStep,
                            onPrevious: viewModel.previousStep
                        )
                        .tag(2)
                        
                        // Step 3: Location
                        LocationSelectionView(
                            selectedLocation: $viewModel.selectedLocation,
                            onNext: viewModel.nextStep,
                            onPrevious: viewModel.previousStep
                        )
                        .tag(3)
                        
                        // Step 4: Tags & Categories
                        TagsAndCategoriesView(
                            selectedTags: $viewModel.selectedTags,
                            selectedCategory: $viewModel.selectedCategory,
                            suggestedTags: viewModel.suggestedTags,
                            onNext: viewModel.nextStep,
                            onPrevious: viewModel.previousStep
                        )
                        .tag(4)
                        
                        // Step 5: Preview
                        SpotPreviewView(
                            spot: viewModel.previewSpot,
                            onSave: viewModel.saveSpot,
                            onPrevious: viewModel.previousStep,
                            isSaving: viewModel.isSaving
                        )
                        .tag(5)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: viewModel.currentStep)
                }
            }
            .navigationTitle("Create Spot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Progress Indicator
struct ProgressIndicatorView: View {
    let currentStep: Int
    let totalSteps: Int
    
    private var progress: Double {
        Double(currentStep) / Double(totalSteps)
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack {
                Text("Step \(currentStep) of \(totalSteps)")
                    .appFont(.callout, color: AppColors.textSecondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .appFont(.callout, weight: .semibold, color: AppColors.primary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primary))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
    }
}

// MARK: - Photo Selection View
struct PhotoSelectionView: View {
    @Binding var selectedImages: [UIImage]
    let onNext: () -> Void
    
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 48))
                    .foregroundColor(AppColors.primary)
                
                Text("Add Photos")
                    .appFont(.title2, color: AppColors.textPrimary)
                
                Text("Show others what makes this place special")
                    .appFont(.body, color: AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, AppSpacing.xxl)
            
            if selectedImages.isEmpty {
                // Photo selection buttons
                VStack(spacing: AppSpacing.md) {
                    Button(action: { showingCamera = true }) {
                        HStack {
                            Image(systemName: "camera")
                            Text("Take Photo")
                        }
                        .font(AppTypography.buttonText)
                        .foregroundColor(AppColors.textInverse)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.primary)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                    }
                    
                    Button(action: { showingImagePicker = true }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Choose from Library")
                        }
                        .font(AppTypography.buttonText)
                    .foregroundColor(AppColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.primary.opacity(0.1))
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            } else {
                // Selected photos grid
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.md) {
                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .cornerRadius(AppSpacing.buttonCornerRadius)
                                    .clipped()
                                
                                Button(action: {
                                    selectedImages.remove(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                }
                                .padding(4)
                            }
                        }
                        
                        // Add more button
                        Button(action: { showingImagePicker = true }) {
                            RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius)
                                .stroke(AppColors.border, style: StrokeStyle(lineWidth: 2, dash: [8]))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    VStack {
                                        Image(systemName: "plus")
                                            .font(.title2)
                                        Text("Add More")
                                            .appFont(.caption, color: AppColors.textSecondary)
                                    }
                                )
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
            }
            
            Spacer()
            
            // Next button
            if !selectedImages.isEmpty {
                Button(action: onNext) {
                    Text("Continue")
                        .font(AppTypography.buttonText)
                        .foregroundColor(AppColors.textInverse)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.primary)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImages: $selectedImages)
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(selectedImage: Binding(
                get: { selectedImages.first },
                set: { if let image = $0 { selectedImages = [image] } }
            ))
        }
    }
}

// MARK: - Spot Details Form View
struct SpotDetailsFormView: View {
    @Binding var title: String
    @Binding var subtitle: String
    @Binding var details: String
    let onNext: () -> Void
    let onPrevious: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Tell us about this place")
                    .appFont(.title2, color: AppColors.textPrimary)
                
                Text("Help others discover what makes this spot special")
                    .appFont(.body, color: AppColors.textSecondary)
            }
            .padding(.top, AppSpacing.lg)
            
            VStack(spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Title *")
                        .appFont(.callout, weight: .semibold, color: AppColors.textPrimary)
                    
                    TextField("What is this place?", text: $title)
                        .appFont(.body, color: AppColors.textPrimary)
                        .padding(AppSpacing.md)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                }
                
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Subtitle")
                        .appFont(.callout, weight: .semibold, color: AppColors.textPrimary)
                    
                    TextField("A short description", text: $subtitle)
                        .appFont(.body, color: AppColors.textPrimary)
                        .padding(AppSpacing.md)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                }
                
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Description *")
                        .appFont(.callout, weight: .semibold, color: AppColors.textPrimary)
                    
                    TextField("Tell us more about this place...", text: $details, axis: .vertical)
                        .appFont(.body, color: AppColors.textPrimary)
                        .padding(AppSpacing.md)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                        .lineLimit(5...10)
                }
            }
            
            Spacer()
            
            // Navigation buttons
            HStack(spacing: AppSpacing.md) {
                Button(action: onPrevious) {
                    Text("Back")
                        .font(AppTypography.buttonText)
                    .foregroundColor(AppColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.primary.opacity(0.1))
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                }
                
                Button(action: onNext) {
                    Text("Continue")
                        .font(AppTypography.buttonText)
                        .foregroundColor(AppColors.textInverse)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(title.isEmpty || details.isEmpty ? AppColors.border : AppColors.primary)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                }
                .disabled(title.isEmpty || details.isEmpty)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)
        }
        .padding(.horizontal, AppSpacing.lg)
    }
}

// MARK: - Location Selection View
struct LocationSelectionView: View {
    @Binding var selectedLocation: CLLocationCoordinate2D?
    let onNext: () -> Void
    let onPrevious: () -> Void
    
    @State private var searchText = ""
    @State private var showingMap = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Where is this place?")
                    .appFont(.title2, color: AppColors.textPrimary)
                
                Text("Help others find this hidden gem")
                    .appFont(.body, color: AppColors.textSecondary)
            }
            .padding(.top, AppSpacing.lg)
            
            VStack(spacing: AppSpacing.lg) {
                SearchBarView(
                    searchText: $searchText,
                    placeholder: "Search for a location..."
                ) {
                    // Handle search
                } onTextChanged: { _ in
                    // Handle text change
                }
                
                Button(action: { showingMap = true }) {
                    HStack {
                        Image(systemName: "map")
                        Text("Select on Map")
                    }
                    .font(AppTypography.buttonText)
                    .foregroundColor(AppColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(AppColors.primary.opacity(0.1))
                    .cornerRadius(AppSpacing.buttonCornerRadius)
                }
                
                if let location = selectedLocation {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Selected Location")
                            .appFont(.callout, weight: .semibold, color: AppColors.textPrimary)
                        
                        Text("Lat: \(location.latitude, specifier: "%.4f"), Lng: \(location.longitude, specifier: "%.4f")")
                            .appFont(.caption, color: AppColors.textSecondary)
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.buttonCornerRadius)
                }
            }
            
            Spacer()
            
            // Navigation buttons
            HStack(spacing: AppSpacing.md) {
                Button(action: onPrevious) {
                    Text("Back")
                        .font(AppTypography.buttonText)
                    .foregroundColor(AppColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.primary.opacity(0.1))
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                }
                
                Button(action: onNext) {
                    Text("Continue")
                        .font(AppTypography.buttonText)
                        .foregroundColor(AppColors.textInverse)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(selectedLocation == nil ? AppColors.border : AppColors.primary)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                }
                .disabled(selectedLocation == nil)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)
        }
        .padding(.horizontal, AppSpacing.lg)
        .sheet(isPresented: $showingMap) {
            LocationMapView(selectedLocation: $selectedLocation)
        }
    }
}

// MARK: - Tags and Categories View
struct TagsAndCategoriesView: View {
    @Binding var selectedTags: [String]
    @Binding var selectedCategory: String
    let suggestedTags: [String]
    let onNext: () -> Void
    let onPrevious: () -> Void
    
    private let categories = ["Restaurants", "Parks", "Museums", "Beaches", "Mountains", "Coffee", "Shopping", "Other"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Categorize your spot")
                    .appFont(.title2, color: AppColors.textPrimary)
                
                Text("Help others find spots they're interested in")
                    .appFont(.body, color: AppColors.textSecondary)
            }
            .padding(.top, AppSpacing.lg)
            
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Category selection
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Category *")
                            .appFont(.callout, weight: .semibold, color: AppColors.textPrimary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: AppSpacing.sm) {
                            ForEach(categories, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category
                                }) {
                                    Text(category)
                                        .appFont(.callout, color: selectedCategory == category ? AppColors.textInverse : AppColors.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, AppSpacing.sm)
                                        .background(selectedCategory == category ? AppColors.primary : AppColors.surface)
                                        .cornerRadius(AppSpacing.buttonCornerRadius)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius)
                                                .stroke(AppColors.border, lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                    
                    // Tags selection
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Tags")
                            .appFont(.callout, weight: .semibold, color: AppColors.textPrimary)
                        
                        Text("Add tags to help describe this place")
                            .appFont(.caption, color: AppColors.textSecondary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: AppSpacing.sm) {
                            ForEach(suggestedTags, id: \.self) { tag in
                                Button(action: {
                                    if selectedTags.contains(tag) {
                                        selectedTags.removeAll { $0 == tag }
                                    } else {
                                        selectedTags.append(tag)
                                    }
                                }) {
                                    Text(tag)
                                        .appFont(.caption, color: selectedTags.contains(tag) ? AppColors.textInverse : AppColors.textPrimary)
                                        .padding(.horizontal, AppSpacing.sm)
                                        .padding(.vertical, AppSpacing.xs)
                                        .background(selectedTags.contains(tag) ? AppColors.primary : AppColors.surface)
                                        .cornerRadius(AppSpacing.pillCornerRadius)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppSpacing.pillCornerRadius)
                                                .stroke(AppColors.border, lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                }
            }
            
            // Navigation buttons
            HStack(spacing: AppSpacing.md) {
                Button(action: onPrevious) {
                    Text("Back")
                        .font(AppTypography.buttonText)
                    .foregroundColor(AppColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.primary.opacity(0.1))
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                }
                
                Button(action: onNext) {
                    Text("Continue")
                        .font(AppTypography.buttonText)
                        .foregroundColor(AppColors.textInverse)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(selectedCategory.isEmpty ? AppColors.border : AppColors.primary)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                }
                .disabled(selectedCategory.isEmpty)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)
        }
        .padding(.horizontal, AppSpacing.lg)
    }
}

// MARK: - Spot Preview View
struct SpotPreviewView: View {
    let spot: Spot?
    let onSave: () -> Void
    let onPrevious: () -> Void
    let isSaving: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Preview your spot")
                    .appFont(.title2, color: AppColors.textPrimary)
                
                Text("This is how others will see your discovery")
                    .appFont(.body, color: AppColors.textSecondary)
            }
            .padding(.top, AppSpacing.lg)
            
            if let spot = spot {
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Preview card
                        SpotCardView(spot: spot)
                        
                        // Details
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Details")
                                .appFont(.headline, color: AppColors.textPrimary)
                            
                            Text(spot.details)
                                .appFont(.body, color: AppColors.textSecondary)
                            
                            if !spot.tags.isEmpty {
                                HStack {
                                    ForEach(spot.tags, id: \.self) { tag in
                                        Text(tag)
                                            .appFont(.caption, color: AppColors.primary)
                                            .padding(.horizontal, AppSpacing.sm)
                                            .padding(.vertical, AppSpacing.xs)
                                            .background(AppColors.primary.opacity(0.1))
                                            .cornerRadius(AppSpacing.pillCornerRadius)
                                    }
                                }
                            }
                        }
                        .padding(AppSpacing.lg)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                    }
                }
            } else {
                Spacer()
                
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(AppColors.warning)
                    
                    Text("Unable to create preview")
                        .appFont(.headline, color: AppColors.textPrimary)
                    
                    Text("Please go back and check your information")
                        .appFont(.body, color: AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
            }
            
            // Navigation buttons
            HStack(spacing: AppSpacing.md) {
                Button(action: onPrevious) {
                    Text("Back")
                        .font(AppTypography.buttonText)
                    .foregroundColor(AppColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.primary.opacity(0.1))
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                }
                
                Button(action: onSave) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isSaving ? "Saving..." : "Save Spot")
                    }
                    .font(AppTypography.buttonText)
                    .foregroundColor(AppColors.textInverse)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(spot == nil ? AppColors.border : AppColors.primary)
                    .cornerRadius(AppSpacing.buttonCornerRadius)
                }
                .disabled(spot == nil || isSaving)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)
        }
        .padding(.horizontal, AppSpacing.lg)
    }
}

// MARK: - Preview
#if DEBUG
struct CreateSpotView_Previews: PreviewProvider {
    static var previews: some View {
        let env = AppEnvironment()
        return CreateSpotView(
            viewModel: env.homeViewModel.createSpotViewModel()
        )
    }
}
#endif
