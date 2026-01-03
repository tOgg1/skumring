import Foundation

/// A user-created playlist containing references to library items.
///
/// Playlists store item IDs (not copies) so changes to items are reflected automatically.
/// Each playlist has its own repeat and shuffle settings.
struct Playlist: Codable, Identifiable, Hashable, Sendable {
    /// Unique identifier for this playlist
    let id: UUID
    
    /// Display name for the playlist
    var name: String
    
    /// Ordered list of item IDs in this playlist
    var itemIDs: [UUID]
    
    /// Current repeat mode for this playlist
    var repeatMode: RepeatMode
    
    /// Current shuffle mode for this playlist
    var shuffleMode: ShuffleMode
    
    /// When this playlist was created
    let createdAt: Date
    
    /// Creates a new playlist with default settings.
    init(
        id: UUID = UUID(),
        name: String,
        itemIDs: [UUID] = [],
        repeatMode: RepeatMode = .off,
        shuffleMode: ShuffleMode = .off,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.itemIDs = itemIDs
        self.repeatMode = repeatMode
        self.shuffleMode = shuffleMode
        self.createdAt = createdAt
    }
    
    // MARK: - Item Management
    
    /// Adds an item ID to the end of the playlist.
    mutating func addItem(_ itemID: UUID) {
        itemIDs.append(itemID)
    }
    
    /// Removes all occurrences of an item ID from the playlist.
    mutating func removeItem(_ itemID: UUID) {
        itemIDs.removeAll { $0 == itemID }
    }
    
    /// Moves an item from one index to another.
    mutating func moveItem(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              itemIDs.indices.contains(sourceIndex),
              destinationIndex >= 0 && destinationIndex <= itemIDs.count else {
            return
        }
        let item = itemIDs.remove(at: sourceIndex)
        let insertIndex = destinationIndex > sourceIndex ? destinationIndex - 1 : destinationIndex
        itemIDs.insert(item, at: insertIndex)
    }
    
    /// Whether this playlist contains the given item.
    func contains(_ itemID: UUID) -> Bool {
        itemIDs.contains(itemID)
    }
    
    /// The number of items in this playlist.
    var itemCount: Int {
        itemIDs.count
    }
}
