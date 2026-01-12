---
id: skumring-wyw
status: closed
deps: [skumring-h9n]
links: []
created: 2026-01-02T17:36:31.088779+01:00
type: task
priority: 0
parent: skumring-fo9
---
# Implement LibraryStore with persistence

Create the LibraryStore service that manages all library data:

1. LibraryStore class (@Observable or ObservableObject):
   - items: [LibraryItem] (published)
   - playlists: [Playlist] (published)
   - importedPacks: [ImportedPackMetadata]? (optional tracking)
   
2. CRUD operations for items:
   - addItem(_ item: LibraryItem)
   - updateItem(_ item: LibraryItem)
   - deleteItem(id: UUID)
   - getItem(id: UUID) -> LibraryItem?
   - getItems(filter: LibraryFilter) -> [LibraryItem]
   - getItems(byTag: String) -> [LibraryItem]
   - searchItems(query: String) -> [LibraryItem]

3. CRUD operations for playlists:
   - addPlaylist(_ playlist: Playlist)
   - updatePlaylist(_ playlist: Playlist)
   - deletePlaylist(id: UUID)
   - getPlaylist(id: UUID) -> Playlist?
   - addItemToPlaylist(itemID: UUID, playlistID: UUID)
   - removeItemFromPlaylist(itemID: UUID, playlistID: UUID)
   - reorderPlaylist(playlistID: UUID, fromIndex: Int, toIndex: Int)

4. Persistence layer:
   - Storage path: Application Support/<bundle id>/library.json
   - Auto-save on changes (debounced, e.g., 1 second)
   - Load on init
   - Error handling for corrupt files
   - Consider SwiftData as alternative (but JSON is simpler for v1)

5. Computed properties:
   - allTags: Set<String>
   - recentlyPlayed: [LibraryItem] (last 10)
   - itemCount: Int
   - playlistCount: Int

Acceptance criteria:
- Items persist across app restarts
- Playlists persist across app restarts
- Search returns relevant results
- Deleting an item removes it from all playlists
- File corruption shows error but doesn't crash


