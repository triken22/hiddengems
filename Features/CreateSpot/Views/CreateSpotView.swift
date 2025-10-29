import SwiftUI
import PhotosUI
import CoreLocation
import MapKit

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
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Step \(viewModel.currentStep) of \(viewModel.totalSteps)")
                    
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
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                }
            }
            .navigationTitle("Create Spot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel spot creation")
                    .accessibilityHint("Tap to cancel and return")
                }
            }
            .overlay {
                if viewModel.saveSuccess {
                    SuccessOverlayView {
                        dismiss()
                    }
                }
            }
            .onChange(of: viewModel.saveSuccess) { _, isSuccess in
                if isSuccess {
                    // Auto-dismiss after showing success animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        dismiss()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                // Handle keyboard appearance
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                // Handle keyboard dismissal
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
            headerSection
            contentSection
            Spacer()
            continueButton
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
        .onChange(of: selectedImages) { _, newImages in
            // Auto-advance to next step when first photo is selected
            if !newImages.isEmpty && newImages.count == 1 {
                // Add haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onNext()
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundColor(AppColors.primary)
            
            Text("Add Photos")
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Show others what makes this place special")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppSpacing.xxl)
    }
    
    @ViewBuilder
    private var contentSection: some View {
        if selectedImages.isEmpty {
            photoSelectionButtons
        } else {
            selectedPhotosGrid
        }
    }
    
    private var photoSelectionButtons: some View {
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
    }
    
    private var selectedPhotosGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.md) {
                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                    photoThumbnail(image: image, index: index)
                }
                
                addMoreButton
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }
    
    private func photoThumbnail(image: UIImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 120, height: 120)
                .cornerRadius(AppSpacing.buttonCornerRadius)
                .clipped()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    var images = selectedImages
                    images.remove(at: index)
                    selectedImages = images
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.6)))
            }
            .padding(4)
        }
    }
    
    private var addMoreButton: some View {
        Button(action: { showingImagePicker = true }) {
            RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius)
                .stroke(AppColors.border, style: StrokeStyle(lineWidth: 2, dash: [8]))
                .frame(width: 120, height: 120)
                .overlay(
                    VStack {
                        Image(systemName: "plus")
                            .font(.title2)
                        Text("Add More")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                )
        }
    }
    
    private var continueButton: some View {
        Button(action: onNext) {
            Text("Continue")
                .font(AppTypography.buttonText)
                .foregroundColor(AppColors.textInverse)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(selectedImages.isEmpty ? AppColors.border : AppColors.primary)
                .cornerRadius(AppSpacing.buttonCornerRadius)
        }
        .disabled(selectedImages.isEmpty)
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.lg)
    }
}

// MARK: - Spot Details Form View
struct SpotDetailsFormView: View {
    @Binding var title: String
    @Binding var subtitle: String
    @Binding var details: String
    let onNext: () -> Void
    let onPrevious: () -> Void
    @FocusState private var focusedField: DetailField?
    @State private var keyboardHeight: CGFloat = 0
    
    enum DetailField {
        case title, subtitle, details
    }
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Tell us about this place")
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Help others discover what makes this spot special")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.top, AppSpacing.lg)
                    
                    VStack(spacing: AppSpacing.lg) {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Title *")
                                .font(AppTypography.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("What is this place?", text: $title)
                                .focused($focusedField, equals: .title)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(AppSpacing.md)
                                .background(AppColors.surface)
                                .cornerRadius(AppSpacing.buttonCornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius)
                                        .stroke(title.isEmpty ? AppColors.error : AppColors.border, lineWidth: 1)
                                )
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .subtitle
                                }
                            
                            if title.isEmpty {
                                Text("Title is required")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.error)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Subtitle")
                                .font(AppTypography.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("A short description", text: $subtitle)
                                .focused($focusedField, equals: .subtitle)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(AppSpacing.md)
                                .background(AppColors.surface)
                                .cornerRadius(AppSpacing.buttonCornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius)
                                        .stroke(AppColors.border, lineWidth: 1)
                                )
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .details
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Description *")
                                .font(AppTypography.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("Tell us more about this place...", text: $details, axis: .vertical)
                                .focused($focusedField, equals: .details)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(AppSpacing.md)
                                .background(AppColors.surface)
                                .cornerRadius(AppSpacing.buttonCornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius)
                                        .stroke(details.isEmpty ? AppColors.error : AppColors.border, lineWidth: 1)
                                )
                                .lineLimit(5...10)
                                .submitLabel(.done)
                                .onSubmit {
                                    focusedField = nil
                                }
                            
                            if details.isEmpty {
                                Text("Description is required")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.error)
                            }
                        }
                    }
                    
                    Spacer(minLength: 100) // Ensure space for fixed bottom buttons
                }
                .padding(.horizontal, AppSpacing.lg)
            }
            
            // Fixed bottom navigation buttons
            VStack(spacing: 0) {
                Divider()
                    .background(AppColors.border)
                
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
                            .background(isFormValid ? AppColors.primary : AppColors.border)
                            .cornerRadius(AppSpacing.buttonCornerRadius)
                    }
                    .disabled(!isFormValid)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
                .background(AppColors.background)
            }
        }
        .toolbar {
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
}

// MARK: - Location Selection View
struct LocationSelectionView: View {
    @Binding var selectedLocation: CLLocationCoordinate2D?
    let onNext: () -> Void
    let onPrevious: () -> Void
    
    @State private var searchText = ""
    @State private var showingMap = false
    @State private var isGettingLocation = false
    @State private var locationError: String?
    @State private var selectedAddress: String?
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var showingSearchResults = false
    
    private let locationService = DefaultLocationService()
    private let searchCompleter = MKLocalSearchCompleter()
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Where is this place?")
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Help others find this hidden gem")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.top, AppSpacing.lg)
            
            VStack(spacing: AppSpacing.lg) {
                // Use My Location button
                Button(action: getCurrentLocation) {
                    HStack {
                        if isGettingLocation {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "location.fill")
                        }
                        Text(isGettingLocation ? "Getting Location..." : "Use My Location")
                    }
                    .font(AppTypography.buttonText)
                    .foregroundColor(AppColors.textInverse)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(AppColors.primary)
                    .cornerRadius(AppSpacing.buttonCornerRadius)
                }
                .disabled(isGettingLocation)
                
                // Search bar with results
                VStack(spacing: 0) {
                    SearchBarView(
                        searchText: $searchText,
                        placeholder: "Search for a location..."
                    ) {
                        performSearch()
                    } onTextChanged: { text in
                        if text.count > 2 {
                            performSearch()
                        } else {
                            searchResults = []
                            showingSearchResults = false
                        }
                    }
                    
                    // Search results
                    if showingSearchResults && !searchResults.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(searchResults, id: \.self) { mapItem in
                                    Button(action: {
                                        selectLocation(mapItem)
                                    }) {
                                        HStack(alignment: .top, spacing: AppSpacing.md) {
                                            Image(systemName: "location.fill")
                                                .foregroundColor(AppColors.primary)
                                                .font(.system(size: 16))
                                            
                                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                                Text(mapItem.name ?? "Unknown Location")
                                                    .font(AppTypography.body)
                                                    .foregroundColor(AppColors.textPrimary)
                                                    .multilineTextAlignment(.leading)
                                                
                                                if let address = mapItem.placemark.title {
                                                    Text(address)
                                                        .font(AppTypography.caption)
                                                        .foregroundColor(AppColors.textSecondary)
                                                        .multilineTextAlignment(.leading)
                                                }
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal, AppSpacing.lg)
                                        .padding(.vertical, AppSpacing.md)
                                        .background(AppColors.surface)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if mapItem != searchResults.last {
                                        Divider()
                                            .background(AppColors.border)
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                        .shadow(color: AppColors.shadow, radius: 4, x: 0, y: 2)
                    }
                }
                
                // Map selection button
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
                
                // Error message
                if let error = locationError {
                    Text(error)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.error)
                        .multilineTextAlignment(.center)
                }
                
                // Selected location display
                if let location = selectedLocation {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Selected Location")
                            .font(AppTypography.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        if let address = selectedAddress {
                            Text(address)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textSecondary)
                        } else {
                            Text("Lat: \(location.latitude, specifier: "%.4f"), Lng: \(location.longitude, specifier: "%.4f")")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
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
            LocationMapView(selectedLocation: $selectedLocation, selectedAddress: $selectedAddress)
        }
        .onAppear {
            // If location is already set, reverse geocode it
            if let location = selectedLocation, selectedAddress == nil {
                reverseGeocode(coordinate: location)
            }
        }
    }
    
    private func getCurrentLocation() {
        isGettingLocation = true
        locationError = nil
        
        Task {
            do {
                if let location = await locationService.currentLocation() {
                    await MainActor.run {
                        selectedLocation = location.coordinate
                        isGettingLocation = false
                        // Reverse geocode to get address
                        reverseGeocode(coordinate: location.coordinate)
                    }
                } else {
                    await MainActor.run {
                        locationError = "Unable to get your location. Please check location permissions in Settings."
                        isGettingLocation = false
                    }
                }
            }
        }
    }
    
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                if let placemark = placemarks?.first {
                    var addressComponents: [String] = []
                    if let name = placemark.name { addressComponents.append(name) }
                    if let locality = placemark.locality { addressComponents.append(locality) }
                    if let administrativeArea = placemark.administrativeArea { addressComponents.append(administrativeArea) }
                    
                    selectedAddress = addressComponents.joined(separator: ", ")
                }
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            showingSearchResults = false
            return
        }
        
        isSearching = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to SF
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                isSearching = false
                if let error = error {
                    print("Search error: \(error.localizedDescription)")
                    searchResults = []
                } else if let response = response {
                    searchResults = Array(response.mapItems.prefix(5))
                    showingSearchResults = !searchResults.isEmpty
                }
            }
        }
    }
    
    private func selectLocation(_ mapItem: MKMapItem) {
        selectedLocation = mapItem.placemark.coordinate
        selectedAddress = mapItem.placemark.title
        searchText = mapItem.name ?? ""
        showingSearchResults = false
        searchResults = []
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
    @State private var selectedImageIndex = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Preview your spot")
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("This is how others will see your discovery")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.top, AppSpacing.lg)
            
            if let spot = spot {
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Custom preview card with real images
                        SpotPreviewCard(spot: spot, selectedImageIndex: $selectedImageIndex)
                        
                        // Details
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Details")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text(spot.details)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textSecondary)
                            
                            if !spot.tags.isEmpty {
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: AppSpacing.sm) {
                                    ForEach(spot.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.primary)
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
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Please go back and check your information")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
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
                
                // Upload progress indicator
                if isSaving {
                    VStack(spacing: AppSpacing.sm) {
                        ProgressView(value: 0.7) // Stub progress
                            .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primary))
                            .scaleEffect(x: 1, y: 1.5, anchor: .center)
                        
                        Text("Uploading images...")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)
        }
        .padding(.horizontal, AppSpacing.lg)
    }
}

// MARK: - Spot Preview Card
struct SpotPreviewCard: View {
    let spot: Spot
    @Binding var selectedImageIndex: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image carousel
            if !spot.images.isEmpty {
                TabView(selection: $selectedImageIndex) {
                    ForEach(Array(spot.images.enumerated()), id: \.offset) { index, spotImage in
                        if let image = spotImage.localImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .frame(height: 200)
            } else {
                // Placeholder for no images
                Rectangle()
                    .fill(AppColors.surface)
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundColor(AppColors.textSecondary)
                            Text("No images")
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    )
            }
            
            // Content
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(spot.title)
                    .font(AppTypography.cardTitle)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)
                
                if let subtitle = spot.subtitle {
                    Text(subtitle)
                        .font(AppTypography.cardSubtitle)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
                
                if let address = spot.address {
                    HStack {
                        Image(systemName: "location")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text(address)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }
                
                if !spot.topics.isEmpty {
                    HStack {
                        ForEach(spot.topics.prefix(2), id: \.self) { topic in
                            Text(topic)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.primary)
                                .padding(.horizontal, AppSpacing.sm)
                                .padding(.vertical, AppSpacing.xs)
                                .background(AppColors.primary.opacity(0.1))
                                .cornerRadius(AppSpacing.pillCornerRadius)
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.buttonCornerRadius)
        .shadow(color: AppColors.shadow.opacity(0.1), radius: 4, x: 0, y: 2)
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

// MARK: - Success Overlay
struct SuccessOverlayView: View {
    let onDismiss: () -> Void
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Blur background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Success card
            VStack(spacing: AppSpacing.lg) {
                // Checkmark animation
                ZStack {
                    Circle()
                        .fill(AppColors.success)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(scale)
                
                VStack(spacing: AppSpacing.sm) {
                    Text("Success!")
                        .font(AppTypography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Your hidden gem has been saved")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(opacity)
            }
            .padding(AppSpacing.xl)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.cardCornerRadius)
            .shadow(color: AppColors.shadow, radius: 20, x: 0, y: 10)
            .padding(AppSpacing.xl)
        }
        .onAppear {
            // Animate in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
            }
            withAnimation(.easeIn(duration: 0.3).delay(0.2)) {
                opacity = 1.0
            }
        }
    }
}
