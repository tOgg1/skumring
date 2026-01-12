---
id: skumring-fm5
status: closed
deps: [skumring-da6]
links: []
created: 2026-01-02T17:43:10.024821+01:00
type: task
priority: 0
parent: skumring-xsn
---
# Implement Import UI and flows

Create the user interface for importing library content:

1. Import menu commands:
   - File > Import... (Cmd+I)
   - Also support drag-and-drop of .json files onto app window

2. Import dialog:
   - NSOpenPanel for choosing file
   - File type filter: .json
   - Allow multiple selection for batch import

3. Import preview sheet:
   - Parse file and show preview before importing:
     - Pack name/source (if available)
     - Item count
     - Playlist count
     - List of items with duplicates highlighted
   - Options:
     - Duplicate handling: Skip / Replace / Create Copy
     - Checkbox: Import playlists
   - Cancel / Import buttons

4. Import progress:
   - Progress bar for large imports
   - Show current item being processed
   - Allow cancellation

5. Import results dialog:
   - Summary:
     - Items imported: X
     - Items skipped (duplicates): X
     - Items updated: X
     - Playlists imported: X
   - If errors:
     - List errors with item names
     - Option to view error log
   - 'View Imported Items' button to filter library

6. Duplicate handling UI:
   - When duplicates found, highlight in preview
   - Show comparison: existing vs. incoming metadata
   - Per-item override option (advanced)

7. Error handling:
   - Invalid JSON format
   - Unknown schema version
   - Invalid item data
   - Clear error messages explaining issue

8. Drag-and-drop support:
   - Drop .json file on library view
   - Drop .json file on app icon
   - Same import flow as menu

Acceptance criteria:
- Can import via menu command
- Can import via drag-and-drop
- Preview shows accurate counts
- Duplicate handling works per settings
- Errors show helpful messages
- Import results show accurate stats


