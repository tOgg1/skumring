---
id: skumring-4f9
status: closed
deps: [skumring-7qk]
links: []
created: 2026-01-02T17:41:51.489639+01:00
type: task
priority: 1
parent: skumring-b2h
---
# Implement queue view and management

Create the queue view for managing upcoming playback:

1. QueueView (popover or panel):
   - Triggered from Now Playing bar queue button
   - Shows as popover or slide-out panel
   - Header: 'Up Next' title

2. Queue display:
   - Current item highlighted at top (Now Playing)
   - Upcoming items listed below
   - Each row shows:
     - Position number
     - Artwork thumbnail
     - Title
     - Source type icon
     - Remove button

3. Queue manipulation:
   - Drag-and-drop reorder upcoming items
   - Remove item from queue (doesn't affect playlist)
   - Clear all upcoming (keep current)
   - Play Now: jump to any queued item

4. 'Play Next' feature:
   - From library context menu: 'Play Next'
   - Inserts item at position 1 in queue (after current)
   - Visual feedback confirming insertion

5. 'Add to Queue' feature:
   - From library context menu: 'Add to Queue'
   - Appends item at end of queue
   - Visual feedback confirming addition

6. Queue vs Playlist distinction:
   - Queue is temporary playback order
   - Modifying queue doesn't modify source playlist
   - Queue resets when starting new playlist
   - Consider: 'Save Queue as Playlist' option

7. Empty state:
   - When no queue: 'No upcoming items'
   - Hint: 'Play a playlist or add items to queue'

Acceptance criteria:
- Queue shows correct upcoming items
- Can reorder queue without affecting playlist
- Play Next inserts at correct position
- Add to Queue appends correctly
- Removing from queue doesn't affect library


