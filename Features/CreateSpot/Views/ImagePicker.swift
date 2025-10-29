import SwiftUI
import PhotosUI
import MapKit
import CoreLocation

/// Image picker for selecting multiple photos from the library
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 10
        configuration.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard !results.isEmpty else { return }
            
            let group = DispatchGroup()
            var images: [UIImage] = []
            
            for result in results {
                group.enter()
                
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                        defer { group.leave() }
                        
                        if let image = object as? UIImage {
                            DispatchQueue.main.async {
                                images.append(image)
                            }
                        }
                    }
                } else {
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.parent.selectedImages.append(contentsOf: images)
            }
        }
    }
}

/// Camera view for taking photos
struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

/// Location map view for selecting coordinates
struct LocationMapView: View {
    @Binding var selectedLocation: CLLocationCoordinate2D?
    @Binding var selectedAddress: String?
    @Environment(\.dismiss) private var dismiss
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var mapLocation: CLLocationCoordinate2D?
    @State private var isGettingAddress = false
    
    private let locationService = DefaultLocationService()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: .constant(.region(region))) {
                    if let location = mapLocation {
                        Annotation("Selected Location", coordinate: location) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(AppColors.primary)
                        }
                    }
                }
                .onTapGesture { location in
                    let coordinate = region.center
                    mapLocation = coordinate
                    selectedLocation = coordinate
                    getAddressForCoordinate(coordinate)
                }
                .onLongPressGesture {
                    let coordinate = region.center
                    mapLocation = coordinate
                    selectedLocation = coordinate
                    getAddressForCoordinate(coordinate)
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            if let location = mapLocation {
                                selectedLocation = location
                            }
                            dismiss()
                        }) {
                            Text("Select Location")
                                .font(AppTypography.buttonText)
                                .foregroundColor(AppColors.textInverse)
                                .padding(.horizontal, AppSpacing.lg)
                                .padding(.vertical, AppSpacing.md)
                                .background(AppColors.primary)
                                .cornerRadius(AppSpacing.buttonCornerRadius)
                        }
                        .padding(.trailing, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.lg)
                    }
                }
                
                // Current location button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: centerOnCurrentLocation) {
                            Image(systemName: "location.fill")
                                .font(.title2)
                                .foregroundColor(AppColors.primary)
                                .padding(AppSpacing.md)
                                .background(AppColors.background)
                                .cornerRadius(AppSpacing.buttonCornerRadius)
                                .shadow(radius: 2)
                        }
                        .padding(.trailing, AppSpacing.lg)
                        .padding(.top, AppSpacing.lg)
                    }
                    Spacer()
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if let location = selectedLocation {
                mapLocation = location
                region.center = location
            }
        }
    }
    
    private func centerOnCurrentLocation() {
        Task {
            if let location = await locationService.currentLocation() {
                await MainActor.run {
                    region.center = location.coordinate
                    mapLocation = location.coordinate
                    selectedLocation = location.coordinate
                    getAddressForCoordinate(location.coordinate)
                }
            }
        }
    }
    
    private func getAddressForCoordinate(_ coordinate: CLLocationCoordinate2D) {
        isGettingAddress = true
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                isGettingAddress = false
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
}
