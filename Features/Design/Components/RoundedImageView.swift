import SwiftUI

/// A rounded image view with consistent styling and loading states
struct RoundedImageView: View {
    let imageURL: URL?
    let placeholder: String
    let cornerRadius: CGFloat
    let aspectRatio: CGFloat?
    let contentMode: ContentMode
    
    @State private var isLoading = true
    @State private var hasError = false
    
    init(
        imageURL: URL?,
        placeholder: String = "photo",
        cornerRadius: CGFloat = AppSpacing.cardCornerRadius,
        aspectRatio: CGFloat? = nil,
        contentMode: ContentMode = .fill
    ) {
        self.imageURL = imageURL
        self.placeholder = placeholder
        self.cornerRadius = cornerRadius
        self.aspectRatio = aspectRatio
        self.contentMode = contentMode
    }
    
    var body: some View {
        ZStack {
            if hasError {
                placeholderView
            } else if let imageURL = imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(aspectRatio, contentMode: contentMode)
                        .clipped()
                } placeholder: {
                    if isLoading {
                        loadingView
                    } else {
                        placeholderView
                    }
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isLoading = false
                    }
                }
            } else {
                placeholderView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(aspectRatio, contentMode: .fit)
        .background(AppColors.surface)
        .cornerRadius(cornerRadius)
        .clipped()
    }
    
    private var placeholderView: some View {
        ZStack {
            AppColors.surface
            Image(systemName: placeholder)
                .font(.title2)
                .foregroundColor(AppColors.textTertiary)
        }
    }
    
    private var loadingView: some View {
        ZStack {
            AppColors.surface
            ProgressView()
                .scaleEffect(0.8)
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
        }
    }
}

// MARK: - AsyncImage Error Handling
extension AsyncImage {
    func onError(_ action: @escaping (Error) -> Void) -> some View {
        self.overlay(
            Color.clear
                .onReceive(NotificationCenter.default.publisher(for: .imageLoadError)) { notification in
                    if let error = notification.object as? Error {
                        action(error)
                    }
                }
        )
    }
}

// MARK: - Image Load Error Notification
extension Notification.Name {
    static let imageLoadError = Notification.Name("imageLoadError")
}

// MARK: - Preview
#if DEBUG
struct RoundedImageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            RoundedImageView(
                imageURL: URL(string: "https://picsum.photos/300/200"),
                aspectRatio: 1.5
            )
            .frame(height: 200)
            
            RoundedImageView(
                imageURL: nil,
                placeholder: "photo.fill",
                aspectRatio: 1.0
            )
            .frame(width: 100, height: 100)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
