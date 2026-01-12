---
id: skumring-4tl
status: closed
deps: [skumring-wyw]
links: []
created: 2026-01-02T17:40:50.34197+01:00
type: task
priority: 0
parent: skumring-b2h
---
# Implement playlist creation and basic management

Create the core playlist CRUD functionality:

1. Create Playlist flow:
   - Menu: File > New Playlist (Cmd+N)
   - Context menu in sidebar: 'New Playlist'
   - Creates playlist with default name 'New Playlist'
   - Immediately enters rename mode
   - Empty playlist appears in sidebar under Playlists section

2. Rename Playlist:
   - Double-click playlist name in sidebar
   - Context menu: 'Rename'
   - Inline text field editing
   - Save on Enter, cancel on Escape
   - Validate: non-empty name

3. Delete Playlist:
   - Context menu: 'Delete Playlist'
   - Keyboard: Delete key when playlist selected
   - Confirmation dialog:
     - 'Delete [Playlist Name]?'
     - 'The playlist will be deleted. Items will remain in your library.'
     - Cancel / Delete buttons
   - Does NOT delete the items, only the playlist

4. Duplicate Playlist:
   - Context menu: 'Duplicate Playlist'
   - Creates copy with name '[Original Name] Copy'
   - Copies all item references and settings

5. Playlist properties:
   - Name (editable)
   - repeatMode: off/one/all (persisted)
   - shuffleMode: off/on (persisted)
   - Item count (computed)
   - Total duration (computed, if known)
   - Created date
   - Last modified date

6. Integration:
   - Wire up to LibraryStore playlist methods
   - Update sidebar immediately on changes
   - Persist changes to disk

Acceptance criteria:
- Can create new playlist via menu and shortcut
- Can rename playlist inline
- Can delete playlist with confirmation
- Playlist settings persist across app restarts
- Items remain in library when playlist deleted


