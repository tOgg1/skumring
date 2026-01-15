import Foundation
import Observation

/// Manages the user's library of items and playlists.
///
/// LibraryStore is an observable class that handles all CRUD operations
/// for library items and playlists. It maintains in-memory collections
/// that will be persisted in future iterations.
///
/// Usage:
/// ```swift
/// let store = LibraryStore()
/// store.addItem(item)
/// store.addPlaylist(playlist)
/// ```
@Observable
final class LibraryStore {
    
    // MARK: - Properties
    
    /// All items in the user's library
    var items: [LibraryItem] = []
    
    /// All user-created playlists
    var playlists: [Playlist] = []
    
    // MARK: - Computed Filters
    
    /// All stream items (internet radio, live streams)
    var streams: [LibraryItem] {
        items.filter { $0.kind == .stream }
    }
    
    /// All YouTube video items
    var youtubeItems: [LibraryItem] {
        items.filter { $0.kind == .youtube }
    }
    
    /// All direct audio URL items (mp3, aac, etc.)
    var audioURLItems: [LibraryItem] {
        items.filter { $0.kind == .audioURL }
    }
    
    // MARK: - Persistence
    
    /// File URL for storing library data
    private var libraryFileURL: URL {
        get throws {
            let fileManager = FileManager.default
            let appSupport = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            
            // Use bundle identifier or fallback
            let bundleID = Bundle.main.bundleIdentifier ?? "app.skumring.Skumring"
            let appDirectory = appSupport.appendingPathComponent(bundleID, isDirectory: true)
            
            // Create directory if needed
            if !fileManager.fileExists(atPath: appDirectory.path) {
                try fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
            }
            
            return appDirectory.appendingPathComponent("library.json")
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // Load persisted data on init
        do {
            try load()
        } catch {
            // First launch or corrupted file - start fresh
            items = []
            playlists = []
        }
    }
    
    // MARK: - Item CRUD
    
    /// Adds a new item to the library.
    ///
    /// - Parameter item: The item to add
    func addItem(_ item: LibraryItem) {
        items.append(item)
        persistChanges()
    }
    
    /// Updates an existing item in the library.
    ///
    /// Finds the item by its ID and replaces it with the updated version.
    /// If no item with the given ID exists, this is a no-op.
    ///
    /// - Parameter item: The updated item (must have same ID as existing item)
    func updateItem(_ item: LibraryItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        items[index] = item
        persistChanges()
    }
    
    /// Removes an item from the library and all playlists.
    ///
    /// This method removes the item from the items array and also
    /// removes any references to it from all playlists.
    ///
    /// - Parameter id: The ID of the item to delete
    func deleteItem(id: UUID) {
        items.removeAll { $0.id == id }
        
        // Remove from all playlists that reference this item
        for index in playlists.indices {
            playlists[index].removeItem(id)
        }
        persistChanges()
    }
    
    /// Finds an item by its ID.
    ///
    /// - Parameter id: The ID to search for
    /// - Returns: The item if found, nil otherwise
    func item(withID id: UUID) -> LibraryItem? {
        items.first { $0.id == id }
    }
    
    // MARK: - Playlist CRUD
    
    /// Adds a new playlist to the library.
    ///
    /// - Parameter playlist: The playlist to add
    func addPlaylist(_ playlist: Playlist) {
        playlists.append(playlist)
        persistChanges()
    }
    
    /// Updates an existing playlist.
    ///
    /// Finds the playlist by its ID and replaces it with the updated version.
    /// If no playlist with the given ID exists, this is a no-op.
    ///
    /// - Parameter playlist: The updated playlist
    func updatePlaylist(_ playlist: Playlist) {
        guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else {
            return
        }
        playlists[index] = playlist
        persistChanges()
    }
    
    /// Removes a playlist from the library.
    ///
    /// - Parameter id: The ID of the playlist to delete
    func deletePlaylist(id: UUID) {
        playlists.removeAll { $0.id == id }
        persistChanges()
    }
    
    /// Finds a playlist by its ID.
    ///
    /// - Parameter id: The ID to search for
    /// - Returns: The playlist if found, nil otherwise
    func playlist(withID id: UUID) -> Playlist? {
        playlists.first { $0.id == id }
    }
    
    /// Returns all items that belong to a playlist.
    ///
    /// - Parameter playlistID: The playlist ID
    /// - Returns: Array of items in playlist order, excluding any missing items
    func items(forPlaylist playlistID: UUID) -> [LibraryItem] {
        guard let playlist = playlist(withID: playlistID) else {
            return []
        }
        return playlist.itemIDs.compactMap { item(withID: $0) }
    }
    
    // MARK: - Persistence Operations
    
    /// Container for encoding/decoding library data
    private struct LibraryData: Codable {
        var items: [LibraryItem]
        var playlists: [Playlist]
    }
    
    /// Saves the current library state to disk.
    ///
    /// - Throws: Encoding or file system errors
    func save() throws {
        let data = LibraryData(items: items, playlists: playlists)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(data)
        try jsonData.write(to: try libraryFileURL)
    }
    
    /// Loads the library state from disk.
    ///
    /// - Throws: Decoding or file system errors
    func load() throws {
        let url = try libraryFileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            // No saved data yet - this is fine
            items = []
            playlists = []
            return
        }
        
        let jsonData = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try decoder.decode(LibraryData.self, from: jsonData)
        items = data.items
        playlists = data.playlists
    }

    // MARK: - Private Helpers

    private func persistChanges() {
        do {
            try save()
        } catch {
            print("Failed to save library: \(error.localizedDescription)")
        }
    }
}
