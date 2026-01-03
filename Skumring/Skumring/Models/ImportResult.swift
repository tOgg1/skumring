import Foundation

/// Result of importing a pack into the library.
///
/// Provides detailed statistics about what happened during an import operation,
/// including counts of items that were added, updated, or skipped.
struct ImportResult: Sendable {
    /// Number of new items added to the library
    let itemsImported: Int
    
    /// Number of existing items that were updated with new metadata
    let itemsUpdated: Int
    
    /// Number of items that were skipped (exact duplicates)
    let itemsSkipped: Int
    
    /// Number of new playlists added to the library
    let playlistsImported: Int
    
    /// Any errors that occurred during import
    let errors: [String]
    
    /// Creates an import result with the specified counts.
    init(
        itemsImported: Int = 0,
        itemsUpdated: Int = 0,
        itemsSkipped: Int = 0,
        playlistsImported: Int = 0,
        errors: [String] = []
    ) {
        self.itemsImported = itemsImported
        self.itemsUpdated = itemsUpdated
        self.itemsSkipped = itemsSkipped
        self.playlistsImported = playlistsImported
        self.errors = errors
    }
    
    /// Total number of items processed (imported + updated + skipped)
    var totalItemsProcessed: Int {
        itemsImported + itemsUpdated + itemsSkipped
    }
    
    /// Whether the import completed without any errors
    var isSuccessful: Bool {
        errors.isEmpty
    }
    
    /// A human-readable summary of the import result
    var summary: String {
        var parts: [String] = []
        
        if itemsImported > 0 {
            parts.append("\(itemsImported) item\(itemsImported == 1 ? "" : "s") imported")
        }
        if itemsUpdated > 0 {
            parts.append("\(itemsUpdated) item\(itemsUpdated == 1 ? "" : "s") updated")
        }
        if itemsSkipped > 0 {
            parts.append("\(itemsSkipped) item\(itemsSkipped == 1 ? "" : "s") skipped")
        }
        if playlistsImported > 0 {
            parts.append("\(playlistsImported) playlist\(playlistsImported == 1 ? "" : "s") imported")
        }
        
        if parts.isEmpty {
            return "No changes made"
        }
        
        return parts.joined(separator: ", ")
    }
}
