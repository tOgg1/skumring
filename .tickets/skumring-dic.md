---
id: skumring-dic
status: closed
deps: [skumring-ckj]
links: []
created: 2026-01-02T17:37:11.019324+01:00
type: task
priority: 1
parent: skumring-fo9
---
# Implement item editing and deletion

Allow users to edit and delete library items:

1. Edit Item flow:
   - Context menu option: 'Edit...'
   - Open same sheet as Add Item, pre-filled with existing data
   - Allow editing:
     - Title
     - Subtitle
     - Tags
     - Artwork URL
     - Source URL/ID (with warning about breaking playback)
   - Save updates via LibraryStore.updateItem()

2. Delete Item flow:
   - Context menu option: 'Delete'
   - Keyboard shortcut: Cmd+Delete or Delete key
   - Confirmation dialog:
     - 'Delete [Item Title]?'
     - 'This item will be removed from your library and all playlists.'
     - Cancel / Delete buttons
   - Delete via LibraryStore.deleteItem()
   - Clean removal from all playlists that reference it

3. Bulk operations:
   - Multi-select items in list/grid view
   - Bulk delete with confirmation showing count
   - Bulk add tags
   - Bulk add to playlist

4. Item details panel (optional):
   - Show in detail column or inspector
   - Display all metadata
   - Inline editing where possible

Acceptance criteria:
- Can edit any field of an existing item
- Deleting item removes it from all playlists
- Confirmation prevents accidental deletion
- Bulk operations work with multi-select


