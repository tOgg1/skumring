import Foundation

/// Errors that can occur when loading the built-in pack.
enum BuiltInPackLoaderError: Error, LocalizedError {
    case bundleResourceNotFound
    case decodingFailed(Error)
    case unsupportedSchemaVersion(Int)
    
    var errorDescription: String? {
        switch self {
        case .bundleResourceNotFound:
            return "Built-in pack resource not found in app bundle."
        case .decodingFailed(let underlying):
            return "Failed to decode built-in pack: \(underlying.localizedDescription)"
        case .unsupportedSchemaVersion(let version):
            return "Built-in pack has unsupported schema version: \(version)"
        }
    }
}

/// Service for loading the built-in curated pack from bundle resources.
///
/// BuiltInPackLoader provides access to a curated collection of focus music sources
/// that ship with the app. These items are read-only and cannot be deleted by users.
///
/// Usage:
/// ```swift
/// let loader = BuiltInPackLoader()
/// let pack = try await loader.load()
/// for item in pack.items {
///     print(item.title)
/// }
/// ```
///
/// The built-in pack is loaded from `built-in-pack.json` in the app bundle's
/// Resources folder. Future versions may support remote fetching with local fallback.
final class BuiltInPackLoader: Sendable {
    
    // MARK: - Types
    
    /// Result containing the loaded pack and its metadata.
    struct LoadResult: Sendable {
        /// The loaded pack
        let pack: Pack
        
        /// Whether the pack was loaded from the bundle (vs remote in the future)
        let isFromBundle: Bool
        
        /// Pack version string if available
        var packVersion: String? {
            pack.packVersion
        }
    }
    
    // MARK: - Properties
    
    /// Bundle to load resources from (injectable for testing)
    private let bundle: Bundle
    
    /// Resource name for the built-in pack JSON file
    private let resourceName: String
    
    /// Resource extension
    private let resourceExtension: String
    
    // MARK: - Initialization
    
    /// Creates a new built-in pack loader.
    ///
    /// - Parameters:
    ///   - bundle: The bundle to load resources from. Defaults to main bundle.
    ///   - resourceName: The name of the JSON resource. Defaults to "built-in-pack".
    ///   - resourceExtension: The file extension. Defaults to "json".
    init(
        bundle: Bundle = .main,
        resourceName: String = "built-in-pack",
        resourceExtension: String = "json"
    ) {
        self.bundle = bundle
        self.resourceName = resourceName
        self.resourceExtension = resourceExtension
    }
    
    // MARK: - Public Methods
    
    /// Loads the built-in pack from bundle resources.
    ///
    /// This method reads and parses the built-in pack JSON file from the app bundle.
    ///
    /// - Returns: A LoadResult containing the pack and metadata
    /// - Throws: BuiltInPackLoaderError if loading fails
    func load() throws -> LoadResult {
        // Find the resource in the bundle
        guard let url = bundle.url(forResource: resourceName, withExtension: resourceExtension) else {
            throw BuiltInPackLoaderError.bundleResourceNotFound
        }
        
        // Read and decode
        let data = try Data(contentsOf: url)
        let pack = try decodePack(from: data)
        
        return LoadResult(pack: pack, isFromBundle: true)
    }
    
    /// Asynchronously loads the built-in pack.
    ///
    /// This is a convenience wrapper for async/await contexts.
    ///
    /// - Returns: A LoadResult containing the pack and metadata
    /// - Throws: BuiltInPackLoaderError if loading fails
    func loadAsync() async throws -> LoadResult {
        try await Task.detached(priority: .userInitiated) {
            try self.load()
        }.value
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
    
    /// Returns items asynchronously.
    func loadItemsAsync() async throws -> [LibraryItem] {
        try await loadAsync().pack.items
    }
    
    /// Returns playlists asynchronously.
    func loadPlaylistsAsync() async throws -> [Playlist] {
        try await loadAsync().pack.playlists
    }
    
    // MARK: - Private Methods
    
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
