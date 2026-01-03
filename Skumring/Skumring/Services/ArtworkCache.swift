import AppKit
import CryptoKit
import Foundation

/// Manages disk cache for artwork images.
///
/// ArtworkCache stores downloaded artwork images in the Application Support
/// directory under `<bundleID>/artwork/`. It provides SHA256-based cache keys,
/// automatic JPEG conversion, and LRU eviction when the cache exceeds size limits.
///
/// Usage:
/// ```swift
/// let cache = ArtworkCache()
///
/// // Check cache first
/// if let cached = cache.cachedImage(for: url) {
///     return cached
/// }
///
/// // Fetch and cache
/// if let image = await cache.fetchAndCache(url: url) {
///     return image
/// }
/// ```
final class ArtworkCache: Sendable {
    
    // MARK: - Constants
    
    /// Maximum cache size in bytes (100 MB)
    private let maxCacheSize: Int = 100 * 1024 * 1024
    
    /// JPEG compression quality for cached images
    private let compressionQuality: CGFloat = 0.8
    
    // MARK: - Properties
    
    /// Directory URL for storing cached artwork
    let cacheDirectory: URL
    
    // MARK: - Initialization
    
    /// Creates a new ArtworkCache instance.
    ///
    /// Initializes the cache directory in Application Support if it doesn't exist.
    /// Falls back to a temporary directory if the standard location is unavailable.
    init() {
        let fileManager = FileManager.default
        
        do {
            let appSupport = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            
            let bundleID = Bundle.main.bundleIdentifier ?? "app.skumring.Skumring"
            let artworkDir = appSupport
                .appendingPathComponent(bundleID, isDirectory: true)
                .appendingPathComponent("artwork", isDirectory: true)
            
            if !fileManager.fileExists(atPath: artworkDir.path) {
                try fileManager.createDirectory(
                    at: artworkDir,
                    withIntermediateDirectories: true
                )
            }
            
            self.cacheDirectory = artworkDir
        } catch {
            // Fallback to temp directory if app support is unavailable
            self.cacheDirectory = fileManager.temporaryDirectory
                .appendingPathComponent("skumring-artwork", isDirectory: true)
            
            try? fileManager.createDirectory(
                at: cacheDirectory,
                withIntermediateDirectories: true
            )
        }
    }
    
    // MARK: - Cache Key Generation
    
    /// Generates a cache key for a URL.
    ///
    /// The key is a SHA256 hash of the URL string with a `.jpg` extension.
    ///
    /// - Parameter url: The URL to generate a key for
    /// - Returns: A unique filename based on the URL hash
    func cacheKey(for url: URL) -> String {
        let urlString = url.absoluteString
        let data = Data(urlString.utf8)
        let hash = SHA256.hash(data: data)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        return "\(hashString).jpg"
    }
    
    /// Returns the full file URL for a cached image.
    ///
    /// - Parameter url: The original image URL
    /// - Returns: The local file URL where the image would be cached
    func cacheFileURL(for url: URL) -> URL {
        cacheDirectory.appendingPathComponent(cacheKey(for: url))
    }
    
    // MARK: - Cache Retrieval
    
    /// Retrieves a cached image for a URL.
    ///
    /// Checks if a cached file exists and loads it. Updates the file's
    /// modification date to support LRU eviction.
    ///
    /// - Parameter url: The original image URL
    /// - Returns: The cached image if available, nil otherwise
    func cachedImage(for url: URL) -> NSImage? {
        let fileURL = cacheFileURL(for: url)
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        // Touch the file to update access time for LRU
        try? fileManager.setAttributes(
            [.modificationDate: Date()],
            ofItemAtPath: fileURL.path
        )
        
        return NSImage(contentsOf: fileURL)
    }
    
    // MARK: - Cache Storage
    
    /// Caches an image for a URL.
    ///
    /// Converts the image to JPEG format with the configured compression quality
    /// and writes it to the cache directory. Triggers eviction if cache exceeds
    /// the size limit.
    ///
    /// - Parameters:
    ///   - image: The image to cache
    ///   - url: The original image URL (used to generate the cache key)
    func cache(image: NSImage, for url: URL) {
        guard let jpegData = jpegData(from: image) else {
            return
        }
        
        let fileURL = cacheFileURL(for: url)
        
        do {
            try jpegData.write(to: fileURL)
            evictIfNeeded()
        } catch {
            // Silently fail - caching is best-effort
        }
    }
    
    /// Converts an NSImage to JPEG data.
    ///
    /// - Parameter image: The image to convert
    /// - Returns: JPEG data or nil if conversion fails
    private func jpegData(from image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        
        return bitmap.representation(
            using: .jpeg,
            properties: [.compressionFactor: compressionQuality]
        )
    }
    
    // MARK: - Fetch and Cache
    
    /// Downloads an image from a URL and caches it.
    ///
    /// This method first checks the cache, returning any existing image.
    /// If not cached, it downloads the image, caches it, and returns it.
    ///
    /// - Parameter url: The URL to download from
    /// - Returns: The downloaded image, or nil if the download fails
    func fetchAndCache(url: URL) async -> NSImage? {
        // Check cache first
        if let cached = cachedImage(for: url) {
            return cached
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Verify we got a successful response
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return nil
            }
            
            // Create image from data
            guard let image = NSImage(data: data) else {
                return nil
            }
            
            // Cache for future use
            cache(image: image, for: url)
            
            return image
        } catch {
            return nil
        }
    }
    
    // MARK: - Cache Eviction
    
    /// Checks cache size and evicts oldest files if over limit.
    ///
    /// Uses LRU (Least Recently Used) eviction based on file modification dates.
    /// Deletes the oldest accessed files until the cache is under the size limit.
    private func evictIfNeeded() {
        let fileManager = FileManager.default
        
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else {
            return
        }
        
        // Calculate total size and collect file info
        var totalSize: Int = 0
        var fileInfos: [(url: URL, size: Int, modDate: Date)] = []
        
        for file in files {
            guard let resourceValues = try? file.resourceValues(
                forKeys: [.fileSizeKey, .contentModificationDateKey]
            ),
            let size = resourceValues.fileSize,
            let modDate = resourceValues.contentModificationDate else {
                continue
            }
            
            totalSize += size
            fileInfos.append((url: file, size: size, modDate: modDate))
        }
        
        // Check if eviction is needed
        guard totalSize > maxCacheSize else {
            return
        }
        
        // Sort by modification date (oldest first)
        fileInfos.sort { $0.modDate < $1.modDate }
        
        // Delete oldest files until under limit
        for fileInfo in fileInfos {
            guard totalSize > maxCacheSize else {
                break
            }
            
            do {
                try fileManager.removeItem(at: fileInfo.url)
                totalSize -= fileInfo.size
            } catch {
                // Continue trying other files
            }
        }
    }
    
    // MARK: - Cache Management
    
    /// Returns the current cache size in bytes.
    var currentCacheSize: Int {
        let fileManager = FileManager.default
        
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: .skipsHiddenFiles
        ) else {
            return 0
        }
        
        return files.reduce(0) { total, file in
            let size = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return total + size
        }
    }
    
    /// Clears all cached images.
    func clearCache() {
        let fileManager = FileManager.default
        
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else {
            return
        }
        
        for file in files {
            try? fileManager.removeItem(at: file)
        }
    }
}
