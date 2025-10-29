import SwiftUI
import UIKit

/// High-performance image caching service
@MainActor
class ImageCacheService: ObservableObject {
    static let shared = ImageCacheService()
    
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // Configure cache
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        // Setup cache directory
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("ImageCache")
        
        // Create cache directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func image(for url: URL) async -> UIImage? {
        let key = url.absoluteString as NSString
        
        // Check memory cache first
        if let cachedImage = cache.object(forKey: key) {
            return cachedImage
        }
        
        // Check disk cache
        if let diskImage = await loadFromDisk(url: url) {
            cache.setObject(diskImage, forKey: key)
            return diskImage
        }
        
        // Download and cache
        if let downloadedImage = await downloadImage(from: url) {
            cache.setObject(downloadedImage, forKey: key)
            await saveToDisk(image: downloadedImage, url: url)
            return downloadedImage
        }
        
        return nil
    }
    
    private func loadFromDisk(url: URL) async -> UIImage? {
        let fileName = url.lastPathComponent
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                if let data = try? Data(contentsOf: fileURL),
                   let image = UIImage(data: data) {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    private func saveToDisk(image: UIImage, url: URL) async {
        let fileName = url.lastPathComponent
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                if let data = image.jpegData(compressionQuality: 0.8) {
                    try? data.write(to: fileURL)
                }
                continuation.resume()
            }
        }
    }
    
    private func downloadImage(from url: URL) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data,
                      let image = UIImage(data: data) else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: image)
            }.resume()
        }
    }
    
    func clearCache() {
        cache.removeAllObjects()
        
        // Clear disk cache
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func getCacheSize() -> Int64 {
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(fileSize)
            }
        }
        
        return totalSize
    }
}

// MARK: - Optimized AsyncImage
struct OptimizedAsyncImage: View {
    let url: URL?
    let placeholder: String
    let aspectRatio: CGFloat?
    let contentMode: ContentMode
    
    @StateObject private var imageCache = ImageCacheService.shared
    @State private var image: UIImage?
    @State private var isLoading = true
    
    init(
        url: URL?,
        placeholder: String = "photo",
        aspectRatio: CGFloat? = nil,
        contentMode: ContentMode = .fill
    ) {
        self.url = url
        self.placeholder = placeholder
        self.aspectRatio = aspectRatio
        self.contentMode = contentMode
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(aspectRatio, contentMode: contentMode)
                    .clipped()
            } else if isLoading {
                ZStack {
                    AppColors.surface
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                }
            } else {
                ZStack {
                    AppColors.surface
                    Image(systemName: placeholder)
                        .font(.title2)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
        .frame(aspectRatio: aspectRatio)
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let url = url else {
            isLoading = false
            return
        }
        
        if let cachedImage = await imageCache.image(for: url) {
            image = cachedImage
            isLoading = false
        } else {
            isLoading = false
        }
    }
}

// MARK: - Lazy Loading Grid
struct LazyLoadingGrid<Content: View, Item: Identifiable>: View {
    let items: [Item]
    let columns: [GridItem]
    let spacing: CGFloat
    let content: (Item) -> Content
    
    @State private var visibleItems: Set<Item.ID> = []
    
    init(
        items: [Item],
        columns: [GridItem],
        spacing: CGFloat = 16,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.columns = columns
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(items) { item in
                content(item)
                    .onAppear {
                        visibleItems.insert(item.id)
                    }
                    .onDisappear {
                        visibleItems.remove(item.id)
                    }
            }
        }
    }
}

// MARK: - Performance Monitoring
class PerformanceMonitor: ObservableObject {
    @Published var averageLoadTime: TimeInterval = 0
    @Published var cacheHitRate: Double = 0
    
    private var loadTimes: [TimeInterval] = []
    private var cacheHits = 0
    private var totalRequests = 0
    
    func recordLoadTime(_ time: TimeInterval) {
        loadTimes.append(time)
        if loadTimes.count > 100 {
            loadTimes.removeFirst()
        }
        averageLoadTime = loadTimes.reduce(0, +) / Double(loadTimes.count)
    }
    
    func recordCacheHit() {
        cacheHits += 1
        totalRequests += 1
        cacheHitRate = Double(cacheHits) / Double(totalRequests)
    }
    
    func recordCacheMiss() {
        totalRequests += 1
        cacheHitRate = Double(cacheHits) / Double(totalRequests)
    }
}
