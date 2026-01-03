import Foundation

/// Errors that can occur during import/export operations.
enum ImportExportError: Error, LocalizedError {
    case unsupportedSchemaVersion(Int)
    case fileReadError(URL, Error)
    case fileWriteError(URL, Error)
    case encodingError(Error)
    case decodingError(Error)
    case playlistNotFound(UUID)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedSchemaVersion(let version):
            return "Unsupported pack schema version: \(version). Please update Skumring to import this pack."
        case .fileReadError(let url, let underlying):
            return "Failed to read file at \(url.lastPathComponent): \(underlying.localizedDescription)"
        case .fileWriteError(let url, let underlying):
            return "Failed to write file at \(url.lastPathComponent): \(underlying.localizedDescription)"
        case .encodingError(let underlying):
            return "Failed to encode pack: \(underlying.localizedDescription)"
        case .decodingError(let underlying):
            return "Failed to decode pack: \(underlying.localizedDescription)"
        case .playlistNotFound(let id):
            return "Playlist with ID \(id) not found"
        }
    }
}

/// Service for importing and exporting library data as shareable packs.
///
/// ImportExportService handles all import/export operations for the library,
/// including full library exports, single playlist exports, and pack imports
/// with deduplication support.
///
/// Usage:
/// ```swift
/// let service = ImportExportService(store: libraryStore)
/// let pack = service.exportLibrary()
/// try service.writePackToFile(pack: pack, url: fileURL)
/// ```
final class ImportExportService {
    
    // MARK: - Properties
    
    /// Reference to the library store for reading/writing data
    private let store: LibraryStore
    
    // MARK: - Initialization
    
    /// Creates a new import/export service with the given library store.
    ///
    /// - Parameter store: The library store to use for import/export operations
    init(store: LibraryStore) {
        self.store = store
    }
    
    // MARK: - Export Operations
    
    /// Exports the entire library as a pack.
    ///
    /// Creates a Pack containing all items and playlists from the library,
    /// with the current schema version and timestamp.
    ///
    /// - Returns: A Pack containing the full library
    func exportLibrary() -> Pack {
        Pack(
            items: store.items,
            playlists: store.playlists,
            exportedAt: Date(),
            appIdentifier: Bundle.main.bundleIdentifier ?? Pack.defaultAppIdentifier
        )
    }
    
    /// Exports a single playlist and its items as a pack.
    ///
    /// Creates a Pack containing only the specified playlist and the items
    /// it references. Items not in the playlist are excluded.
    ///
    /// - Parameter id: The ID of the playlist to export
    /// - Returns: A Pack containing the playlist and its items
    /// - Throws: `ImportExportError.playlistNotFound` if the playlist doesn't exist
    func exportPlaylist(id: UUID) throws -> Pack {
        guard let playlist = store.playlist(withID: id) else {
            throw ImportExportError.playlistNotFound(id)
        }
        
        // Get only the items that belong to this playlist
        let playlistItems = store.items(forPlaylist: id)
        
        return Pack(
            items: playlistItems,
            playlists: [playlist],
            exportedAt: Date(),
            appIdentifier: Bundle.main.bundleIdentifier ?? Pack.defaultAppIdentifier
        )
    }
    
    // MARK: - File Operations
    
    /// Writes a pack to a file at the specified URL.
    ///
    /// Encodes the pack as JSON with pretty printing and writes it to disk.
    ///
    /// - Parameters:
    ///   - pack: The pack to write
    ///   - url: The file URL to write to
    /// - Throws: `ImportExportError.encodingError` or `ImportExportError.fileWriteError`
    func writePackToFile(pack: Pack, url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data: Data
        do {
            data = try encoder.encode(pack)
        } catch {
            throw ImportExportError.encodingError(error)
        }
        
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw ImportExportError.fileWriteError(url, error)
        }
    }
    
    /// Reads a pack from a file at the specified URL.
    ///
    /// Reads and decodes the JSON file, validating the schema version.
    ///
    /// - Parameter url: The file URL to read from
    /// - Returns: The decoded Pack
    /// - Throws: `ImportExportError.fileReadError`, `ImportExportError.decodingError`,
    ///           or `ImportExportError.unsupportedSchemaVersion`
    func readPackFromFile(url: URL) throws -> Pack {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ImportExportError.fileReadError(url, error)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let pack: Pack
        do {
            pack = try decoder.decode(Pack.self, from: data)
        } catch {
            throw ImportExportError.decodingError(error)
        }
        
        // Validate schema version
        guard pack.isSchemaVersionSupported else {
            throw ImportExportError.unsupportedSchemaVersion(pack.schemaVersion)
        }
        
        return pack
    }
    
    // MARK: - Import Operations
    
    /// Imports a pack into the library with deduplication.
    ///
    /// For each item in the pack:
    /// - If an item with the same sourceKey exists, updates its metadata
    /// - If no matching item exists, adds it to the library
    ///
    /// For playlists, items are mapped to their new IDs if they were deduplicated.
    ///
    /// - Parameter pack: The pack to import
    /// - Returns: An ImportResult with statistics about the import
    func importPack(pack: Pack) -> ImportResult {
        var itemsImported = 0
        var itemsUpdated = 0
        var itemsSkipped = 0
        var playlistsImported = 0
        var errors: [String] = []
        
        // Build a lookup map of existing items by sourceKey
        var existingItemsBySourceKey: [String: LibraryItem] = [:]
        for item in store.items {
            existingItemsBySourceKey[item.sourceKey] = item
        }
        
        // Map from old item IDs (in pack) to new/existing item IDs (in store)
        var itemIDMapping: [UUID: UUID] = [:]
        
        // Process items
        for packItem in pack.items {
            let sourceKey = packItem.sourceKey
            
            if let existingItem = existingItemsBySourceKey[sourceKey] {
                // Item exists - check if we should update metadata
                if shouldUpdateItem(existing: existingItem, incoming: packItem) {
                    var updatedItem = existingItem
                    // Update metadata fields (preserve health status and fail count)
                    if packItem.title != existingItem.title && !packItem.title.isEmpty {
                        updatedItem.title = packItem.title
                    }
                    if packItem.subtitle != existingItem.subtitle {
                        updatedItem.subtitle = packItem.subtitle
                    }
                    if packItem.artworkURL != existingItem.artworkURL {
                        updatedItem.artworkURL = packItem.artworkURL
                    }
                    // Merge tags
                    let mergedTags = Set(existingItem.tags).union(Set(packItem.tags))
                    updatedItem.tags = Array(mergedTags).sorted()
                    
                    store.updateItem(updatedItem)
                    itemsUpdated += 1
                } else {
                    itemsSkipped += 1
                }
                
                // Map the pack item ID to the existing item ID
                itemIDMapping[packItem.id] = existingItem.id
            } else {
                // New item - add to store
                store.addItem(packItem)
                itemIDMapping[packItem.id] = packItem.id
                existingItemsBySourceKey[sourceKey] = packItem
                itemsImported += 1
            }
        }
        
        // Process playlists
        for packPlaylist in pack.playlists {
            // Remap item IDs to the IDs now in the store
            let remappedItemIDs = packPlaylist.itemIDs.compactMap { itemIDMapping[$0] }
            
            // Check if a playlist with the same name already exists
            let existingPlaylist = store.playlists.first { $0.name == packPlaylist.name }
            
            if existingPlaylist == nil {
                // Create new playlist with remapped IDs
                let newPlaylist = Playlist(
                    id: packPlaylist.id,
                    name: packPlaylist.name,
                    itemIDs: remappedItemIDs,
                    repeatMode: packPlaylist.repeatMode,
                    shuffleMode: packPlaylist.shuffleMode,
                    createdAt: packPlaylist.createdAt
                )
                store.addPlaylist(newPlaylist)
                playlistsImported += 1
            } else {
                // Playlist with same name exists - skip
                // Could optionally merge items here
            }
        }
        
        // Try to save changes
        do {
            try store.save()
        } catch {
            errors.append("Failed to save library after import: \(error.localizedDescription)")
        }
        
        return ImportResult(
            itemsImported: itemsImported,
            itemsUpdated: itemsUpdated,
            itemsSkipped: itemsSkipped,
            playlistsImported: playlistsImported,
            errors: errors
        )
    }
    
    // MARK: - Private Helpers
    
    /// Determines if an existing item should be updated with incoming metadata.
    ///
    /// Returns true if the incoming item has different non-empty metadata
    /// that would improve the existing item.
    private func shouldUpdateItem(existing: LibraryItem, incoming: LibraryItem) -> Bool {
        // Check if incoming has different metadata worth updating
        if incoming.title != existing.title && !incoming.title.isEmpty {
            return true
        }
        if incoming.subtitle != existing.subtitle && incoming.subtitle != nil {
            return true
        }
        if incoming.artworkURL != existing.artworkURL && incoming.artworkURL != nil {
            return true
        }
        if !Set(incoming.tags).isSubset(of: Set(existing.tags)) {
            return true
        }
        return false
    }
}
