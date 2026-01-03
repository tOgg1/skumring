import SwiftUI

/// A SwiftUI view that displays an image from a URL with disk caching.
///
/// CachedAsyncImage checks the ArtworkCache first before downloading.
/// If the image is not cached, it downloads it using AsyncImage and
/// caches the result for future use.
///
/// Usage:
/// ```swift
/// CachedAsyncImage(url: imageURL, cache: artworkCache) { phase in
///     switch phase {
///     case .empty:
///         ProgressView()
///     case .success(let image):
///         image.resizable().aspectRatio(contentMode: .fit)
///     case .failure:
///         Image(systemName: "photo")
///     @unknown default:
///         EmptyView()
///     }
/// }
/// ```
struct CachedAsyncImage<Content: View>: View {
    
    // MARK: - Properties
    
    private let url: URL?
    private let cache: ArtworkCache
    private let content: (AsyncImagePhase) -> Content
    
    @State private var phase: AsyncImagePhase = .empty
    @State private var loadTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    /// Creates a cached async image view.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to display
    ///   - cache: The ArtworkCache instance to use
    ///   - content: A closure that takes the current phase and returns a view
    init(
        url: URL?,
        cache: ArtworkCache,
        @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
    ) {
        self.url = url
        self.cache = cache
        self.content = content
    }
    
    // MARK: - Body
    
    var body: some View {
        content(phase)
            .onAppear {
                loadImage()
            }
            .onChange(of: url) { _, _ in
                loadTask?.cancel()
                phase = .empty
                loadImage()
            }
            .onDisappear {
                loadTask?.cancel()
            }
    }
    
    // MARK: - Image Loading
    
    private func loadImage() {
        guard let url else {
            phase = .failure(CachedImageError.invalidURL)
            return
        }
        
        // Check cache synchronously first
        if let cachedImage = cache.cachedImage(for: url) {
            phase = .success(Image(nsImage: cachedImage))
            return
        }
        
        // Load asynchronously
        loadTask = Task {
            if let image = await cache.fetchAndCache(url: url) {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    phase = .success(Image(nsImage: image))
                }
            } else {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    phase = .failure(CachedImageError.loadFailed)
                }
            }
        }
    }
}

// MARK: - Error Type

private enum CachedImageError: Error {
    case invalidURL
    case loadFailed
}

// MARK: - Convenience Initializers

extension CachedAsyncImage {
    
    /// Creates a cached async image with a default placeholder and error view.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to display
    ///   - cache: The ArtworkCache instance to use
    init(url: URL?, cache: ArtworkCache) where Content == _DefaultCachedAsyncImageContent {
        self.init(url: url, cache: cache) { phase in
            _DefaultCachedAsyncImageContent(phase: phase)
        }
    }
}

/// Default content view for CachedAsyncImage when no custom content is provided.
struct _DefaultCachedAsyncImageContent: View {
    let phase: AsyncImagePhase
    
    var body: some View {
        switch phase {
        case .empty:
            ProgressView()
        case .success(let image):
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
        case .failure:
            Image(systemName: "photo")
                .foregroundStyle(.secondary)
        @unknown default:
            EmptyView()
        }
    }
}
