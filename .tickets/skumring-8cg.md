---
id: skumring-8cg
status: closed
deps: [skumring-4tl]
links: []
created: 2026-01-02T17:41:10.527887+01:00
type: task
priority: 0
parent: skumring-b2h
---
# Implement playlist editor with drag-and-drop reordering

Create the playlist editor view with full editing capabilities:

1. PlaylistEditorView:
   - Shows all items in playlist
   - List view with drag handles
   - Each row shows:
     - Drag handle (grip icon)
     - Artwork thumbnail
     - Title
     - Subtitle/source type
     - Duration (if known)
     - Remove button (X)

2. Drag-and-drop reordering:
   - Use SwiftUI's onMove modifier or List with move support
   - Visual feedback during drag (elevated item, drop indicator)
   - Update playlist.itemIDs order on drop
   - Persist immediately

3. Add items to playlist:
   - Drag items from library list onto playlist in sidebar
   - Drag items from library list into playlist editor
   - Context menu on library item: 'Add to Playlist >' submenu
   - Context menu shows all playlists as options
   - Support multi-select add

4. Remove items from playlist:
   - Click X button on row
   - Select and press Delete key
   - Context menu: 'Remove from Playlist'
   - No confirmation needed (item stays in library)
   - Support multi-select remove

5. Bulk operations in playlist:
   - Select all (Cmd+A)
   - Remove selected
   - Move selected to top/bottom

6. Playlist header:
   - Playlist name (editable)
   - Item count
   - Total duration (if calculable)
   - Repeat/shuffle toggles
   - Play All button

Acceptance criteria:
- Can reorder items via drag-and-drop
- Reordering persists after restart
- Can add items from library via drag or context menu
- Can remove items without affecting library
- Multi-select operations work


