import Foundation

/// Errors that can occur when loading the built-in pack.
enum BuiltInPackLoaderError: Error, LocalizedError {
    case bundleResourceNotFound
    case decodingFailed(Error)
    case unsupportedSchemaVersion(Int)
    case networkError(Error)
    case invalidRemoteURL
    
    var errorDescription: String? {
        switch self {
        case .bundleResourceNotFound:
            return "Built-in pack resource not found in app bundle."
        case .decodingFailed(let underlying):
            return "Failed to decode built-in pack: \(underlying.localizedDescription)"
        case .unsupportedSchemaVersion(let version):
            return "Built-in pack has unsupported schema version: \(version)"
        case .networkError(let underlying):
            return "Network error loading remote pack: \(underlying.localizedDescription)"
        case .invalidRemoteURL:
            return "Invalid remote URL for built-in pack."
        }
    }
}

/// Service for loading the built-in curated pack from remote URL with bundle fallback.
///
/// BuiltInPackLoader provides access to a curated collection of focus music sources.
/// It tries to fetch from a remote URL first, caching the response for 24 hours.
/// If the remote fetch fails (network error, offline, etc.), it falls back to the
/// bundled pack shipped with the app.
///
/// Usage:
/// ```swift
/// let loader = BuiltInPackLoader(remoteURL: URL(string: "https://example.com/pack.json"))
/// let result = try await loader.loadAsync()
/// for item in result.pack.items {
///     print(item.title)
/// }
/// print("From remote: \(!result.isFromBundle)")
/// ```
///
/// Cache behavior:
/// - Remote responses are cached for 24 hours
/// - Cache is stored in the app's Caches directory
/// - Expired cache triggers a new remote fetch
/// - If remote fetch fails with valid cache, stale cache is used
final class BuiltInPackLoader: Sendable {
    
    // MARK: - Types
    
    /// Result containing the loaded pack and its metadata.
    struct LoadResult: Sendable {
        /// The loaded pack
        let pack: Pack
        
        /// Whether the pack was loaded from the bundle (vs remote)
        let isFromBundle: Bool
        
        /// Whether the pack was loaded from cache
        let isFromCache: Bool
        
        /// Pack version string if available
        var packVersion: String? {
            pack.packVersion
        }
        
        /// Source description for debugging
        var sourceDescription: String {
            if isFromBundle {
                return "bundle"
            } else if isFromCache {
                return "cache"
            } else {
                return "remote"
            }
        }
    }
    
    /// Cache metadata stored alongside the pack data
    private struct CacheMetadata: Codable, Sendable {
        let cachedAt: Date
        let packVersion: String?
        let remoteURL: String
    }
    
    // MARK: - Constants
    
    /// Default cache TTL: 24 hours
    static let defaultCacheTTL: TimeInterval = 24 * 60 * 60
    
    /// Cache file name for the pack data
    private static let cacheFileName = "built-in-pack-cache.json"
    
    /// Cache file name for metadata
    private static let cacheMetadataFileName = "built-in-pack-cache-meta.json"
    
    // MARK: - Properties
    
    /// Bundle to load resources from (injectable for testing)
    private let bundle: Bundle
    
    /// Resource name for the built-in pack JSON file
    private let resourceName: String
    
    /// Resource extension
    private let resourceExtension: String
    
    /// Remote URL to fetch the pack from (optional)
    private let remoteURL: URL?
    
    /// Cache time-to-live in seconds
    private let cacheTTL: TimeInterval
    
    /// URLSession for network requests (injectable for testing)
    private let urlSession: URLSession
    
    // MARK: - Initialization
    
    /// Creates a new built-in pack loader with remote fetch support.
    ///
    /// - Parameters:
    ///   - remoteURL: Optional URL to fetch the pack from. If nil, only bundle is used.
    ///   - cacheTTL: Cache time-to-live in seconds. Defaults to 24 hours.
    ///   - bundle: The bundle to load resources from. Defaults to main bundle.
    ///   - resourceName: The name of the JSON resource. Defaults to "built-in-pack".
    ///   - resourceExtension: The file extension. Defaults to "json".
    ///   - urlSession: URLSession for network requests. Defaults to shared session.
    init(
        remoteURL: URL? = nil,
        cacheTTL: TimeInterval = BuiltInPackLoader.defaultCacheTTL,
        bundle: Bundle = .main,
        resourceName: String = "built-in-pack",
        resourceExtension: String = "json",
        urlSession: URLSession = .shared
    ) {
        self.remoteURL = remoteURL
        self.cacheTTL = cacheTTL
        self.bundle = bundle
        self.resourceName = resourceName
        self.resourceExtension = resourceExtension
        self.urlSession = urlSession
    }
    
    // MARK: - Public Methods
    
    /// Loads the built-in pack, trying remote first then falling back to bundle.
    ///
    /// This is the synchronous version that only loads from bundle.
    /// For remote fetch support, use `loadAsync()`.
    ///
    /// - Returns: A LoadResult containing the pack and metadata
    /// - Throws: BuiltInPackLoaderError if loading fails
    func load() throws -> LoadResult {
        // Synchronous load only supports bundle
        // Check cache first (synchronously)
        if let cachedResult = try? loadFromCacheSync() {
            return cachedResult
        }
        
        // Fall back to bundle
        return try loadFromBundle()
    }
    
    /// Asynchronously loads the built-in pack with remote fetch and fallback.
    ///
    /// Loading priority:
    /// 1. If remote URL is configured and cache is expired, try remote fetch
    /// 2. If remote fetch succeeds, cache and return
    /// 3. If remote fetch fails but cache exists (even if stale), use cache
    /// 4. Fall back to bundled pack
    ///
    /// - Returns: A LoadResult containing the pack and metadata
    /// - Throws: BuiltInPackLoaderError if all sources fail
    func loadAsync() async throws -> LoadResult {
        // If no remote URL, just load from bundle
        guard let remoteURL = remoteURL else {
            return try loadFromBundle()
        }
        
        // Check if we have a valid (non-expired) cache
        if let cachedResult = try? loadFromCacheSync(), !isCacheExpired() {
            return cachedResult
        }
        
        // Try fetching from remote
        do {
            let result = try await fetchFromRemote(url: remoteURL)
            
            // Cache the result for next time
            try? cacheResult(result)
            
            return result
        } catch {
            // Remote fetch failed, try stale cache
            if let cachedResult = try? loadFromCacheSync() {
                return cachedResult
            }
            
            // No cache available, fall back to bundle
            return try loadFromBundle()
        }
    }
    
    // MARK: - Convenience Accessors
    
    /// Returns items from the built-in pack.
    ///
    /// - Returns: Array of LibraryItem from the built-in pack
    /// - Throws: BuiltInPackLoaderError if loading fails
    func loadItems() throws -> [LibraryItem] {
        try load().pack.items
    }
    
    /// Returns playlists from the built-in pack.
    ///
    /// - Returns: Array of Playlist from the built-in pack
    /// - Throws: BuiltInPackLoaderError if loading fails
    func loadPlaylists() throws -> [Playlist] {
        try load().pack.playlists
    }
    
    /// Returns items asynchronously with remote fetch support.
    func loadItemsAsync() async throws -> [LibraryItem] {
        try await loadAsync().pack.items
    }
    
    /// Returns playlists asynchronously with remote fetch support.
    func loadPlaylistsAsync() async throws -> [Playlist] {
        try await loadAsync().pack.playlists
    }
    
    // MARK: - Cache Management
    
    /// Clears the cached pack data.
    func clearCache() {
        try? FileManager.default.removeItem(at: cacheURL)
        try? FileManager.default.removeItem(at: cacheMetadataURL)
    }
    
    /// Checks if the cache exists and returns its metadata.
    func cacheInfo() -> (exists: Bool, cachedAt: Date?, isExpired: Bool) {
        guard let metadata = loadCacheMetadata() else {
            return (false, nil, true)
        }
        
        let expired = Date().timeIntervalSince(metadata.cachedAt) > cacheTTL
        return (true, metadata.cachedAt, expired)
    }
    
    // MARK: - Private Methods - Bundle Loading
    
    /// Loads the pack from bundle resources.
    private func loadFromBundle() throws -> LoadResult {
        guard let url = bundle.url(forResource: resourceName, withExtension: resourceExtension) else {
            throw BuiltInPackLoaderError.bundleResourceNotFound
        }
        
        let data = try Data(contentsOf: url)
        let pack = try decodePack(from: data)
        
        return LoadResult(pack: pack, isFromBundle: true, isFromCache: false)
    }
    
    // MARK: - Private Methods - Remote Loading
    
    /// Fetches the pack from a remote URL.
    private func fetchFromRemote(url: URL) async throws -> LoadResult {
        let (data, response) = try await urlSession.data(from: url)
        
        // Check for valid HTTP response
        if let httpResponse = response as? HTTPURLResponse {
            guard (200...299).contains(httpResponse.statusCode) else {
                throw BuiltInPackLoaderError.networkError(
                    NSError(
                        domain: "BuiltInPackLoader",
                        code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"]
                    )
                )
            }
        }
        
        let pack = try decodePack(from: data)
        return LoadResult(pack: pack, isFromBundle: false, isFromCache: false)
    }
    
    // MARK: - Private Methods - Cache
    
    /// URL for the cache file
    private var cacheURL: URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cacheDir.appendingPathComponent(Self.cacheFileName)
    }
    
    /// URL for the cache metadata file
    private var cacheMetadataURL: URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cacheDir.appendingPathComponent(Self.cacheMetadataFileName)
    }
    
    /// Loads pack from cache synchronously.
    private func loadFromCacheSync() throws -> LoadResult {
        let data = try Data(contentsOf: cacheURL)
        let pack = try decodePack(from: data)
        return LoadResult(pack: pack, isFromBundle: false, isFromCache: true)
    }
    
    /// Checks if the cache is expired.
    private func isCacheExpired() -> Bool {
        guard let metadata = loadCacheMetadata() else {
            return true
        }
        return Date().timeIntervalSince(metadata.cachedAt) > cacheTTL
    }
    
    /// Loads cache metadata.
    private func loadCacheMetadata() -> CacheMetadata? {
        guard let data = try? Data(contentsOf: cacheMetadataURL) else {
            return nil
        }
        return try? JSONDecoder().decode(CacheMetadata.self, from: data)
    }
    
    /// Caches a load result.
    private func cacheResult(_ result: LoadResult) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        // Cache the pack data
        let packData = try encoder.encode(result.pack)
        try packData.write(to: cacheURL, options: Data.WritingOptions.atomic)
        
        // Cache metadata
        let metadata = CacheMetadata(
            cachedAt: Date(),
            packVersion: result.pack.packVersion,
            remoteURL: remoteURL?.absoluteString ?? ""
        )
        let metadataData = try JSONEncoder().encode(metadata)
        try metadataData.write(to: cacheMetadataURL, options: Data.WritingOptions.atomic)
    }
    
    // MARK: - Private Methods - Decoding
    
    /// Decodes a Pack from JSON data.
    private func decodePack(from data: Data) throws -> Pack {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let pack: Pack
        do {
            pack = try decoder.decode(Pack.self, from: data)
        } catch {
            throw BuiltInPackLoaderError.decodingFailed(error)
        }
        
        // Validate schema version
        guard pack.isSchemaVersionSupported else {
            throw BuiltInPackLoaderError.unsupportedSchemaVersion(pack.schemaVersion)
        }
        
        return pack
    }
}

// MARK: - Item Identification

extension LibraryItem {
    /// Whether this item is from the built-in pack.
    ///
    /// Items from the built-in pack have UUIDs that start with "B1".
    /// This is a convention for identifying curated content.
    var isBuiltIn: Bool {
        id.uuidString.hasPrefix("B1")
    }
}

extension Playlist {
    /// Whether this playlist is from the built-in pack.
    ///
    /// Playlists from the built-in pack have UUIDs that start with "B2".
    /// This is a convention for identifying curated content.
    var isBuiltIn: Bool {
        id.uuidString.hasPrefix("B2")
    }
}
