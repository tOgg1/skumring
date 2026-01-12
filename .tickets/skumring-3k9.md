---
id: skumring-3k9
status: closed
deps: [skumring-ksb, skumring-wyw]
links: []
created: 2026-01-02T17:44:06.815985+01:00
type: task
priority: 0
parent: skumring-r3a
---
# Implement Library grid and list views

Create the library content views for browsing items:

1. LibraryView container:
   - Receives filter parameter (all, streams, youtube, audioURLs)
   - View mode toggle: Grid / List
   - Search integration
   - Sort options: Name, Date Added, Recently Played

2. LibraryGridView:
   - LazyVGrid with adaptive columns
   - Card size: approximately 180x200
   - Each card shows:
     - Artwork (or placeholder by type)
     - Title (2 lines max, truncated)
     - Subtitle/source type
     - Type badge (stream/youtube/audio)
   - Hover: show play button overlay
   - Click: select item
   - Double-click: play item

3. LibraryListView:
   - List or Table view
   - Columns:
     - Artwork (small thumbnail)
     - Title
     - Subtitle
     - Type
     - Tags
     - Date Added
   - Sortable columns
   - Resizable columns
   - Click: select
   - Double-click: play

4. LibraryItemCard component:
   - Reusable card for grid view
   - Artwork with CachedAsyncImage
   - Fallback artwork per type
   - Playing indicator animation
   - Selection ring

5. LibraryItemRow component:
   - Reusable row for list view
   - Compact layout
   - Playing indicator
   - Selection highlight

6. Empty states:
   - No items: 'Your library is empty. Add your first item.'
   - No search results: 'No items matching [query]'
   - No items of type: 'No [streams/YouTube/audio] items'

7. Context menus (on items):
   - Play
   - Add to Playlist >
   - Add to Queue
   - Play Next
   - Edit...
   - Export...
   - Delete

8. Multi-select:
   - Cmd+click for multi-select
   - Shift+click for range select
   - Cmd+A for select all
   - Actions apply to selection

Acceptance criteria:
- Grid view shows all items attractively
- List view shows sortable columns
- View toggle works
- Search filters items
- Context menus work
- Multi-select works


