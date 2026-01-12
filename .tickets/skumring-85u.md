---
id: skumring-85u
status: closed
deps: [skumring-da6]
links: []
created: 2026-01-02T17:42:50.093616+01:00
type: task
priority: 0
parent: skumring-xsn
---
# Implement Export UI and flows

Create the user interface for exporting library content:

1. Export menu commands:
   - File > Export Library... (Cmd+E)
   - File > Export Playlist... (context-aware)
   - Context menu on playlist: 'Export...'
   - Context menu on selected items: 'Export Selection...'

2. Export dialog:
   - NSSavePanel for choosing destination
   - Default filename: 'Skumring Library.json' or 'Playlist Name.json'
   - File type: .json

3. Export options sheet (shown before save panel):
   - For library export:
     - Checkbox: Include all items
     - Checkbox: Include all playlists
   - For playlist export:
     - Shows which playlists will be exported
     - Shows item count
   - Format options (future):
     - Pretty print (default) vs. minified

4. Export progress:
   - For large libraries, show progress indicator
   - Dismissible if taking too long

5. Export confirmation:
   - Show success message with:
     - Items exported count
     - Playlists exported count
     - File size
     - 'Show in Finder' button

6. Error handling:
   - File write permission errors
   - Disk full
   - Clear error messages with retry option

Acceptance criteria:
- Can export full library via menu
- Can export single playlist via context menu
- File saves to chosen location
- Success confirmation shows stats
- Errors show helpful messages


