---
id: skumring-ahz
status: closed
deps: [skumring-3k9]
links: []
created: 2026-01-02T17:45:30.935239+01:00
type: task
priority: 1
parent: skumring-r3a
---
# Implement search functionality

Create the search feature for finding library items:

1. Search UI:
   - Search field in toolbar (Cmd+F to focus)
   - Inline in main window (not modal)
   - Clear button (X)
   - Placeholder: 'Search library...'

2. Search behavior:
   - Instant search (debounced, ~200ms)
   - Search as you type
   - Case insensitive
   - Searches: title, subtitle, tags

3. Search results:
   - Show in main content area
   - Replace current view temporarily
   - Same grid/list view as library
   - Result count shown
   - 'Clear Search' button to return

4. Search scope:
   - Default: search all items
   - Option: search within current filter
   - Option: search within current playlist

5. Empty results:
   - 'No results for [query]'
   - Suggestions: 'Try different keywords'
   - Clear search button

6. Keyboard navigation:
   - Cmd+F: focus search field
   - Escape: clear search and return to previous view
   - Arrow keys: navigate results
   - Enter: play selected result

7. Advanced search (optional P2):
   - Tag search: #lofi
   - Type filter: type:youtube
   - Combine: lofi type:stream

8. Search history (optional):
   - Remember recent searches
   - Show as suggestions

Acceptance criteria:
- Cmd+F focuses search field
- Results update as you type
- Results are accurate
- Escape clears search
- Can navigate and play results


