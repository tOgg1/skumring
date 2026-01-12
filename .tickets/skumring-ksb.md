---
id: skumring-ksb
status: closed
deps: [skumring-h9n]
links: []
created: 2026-01-02T17:43:45.143151+01:00
type: task
priority: 0
parent: skumring-r3a
---
# Implement main window with NavigationSplitView

Create the main application window structure:

1. MainWindow configuration:
   - Default size: 1000x700 (approximately)
   - Minimum size: 600x400
   - Remember window position and size
   - Title: 'Skumring' (or dynamic based on selection)

2. NavigationSplitView structure:
   - Three-column layout: sidebar, content, detail (optional)
   - Or two-column: sidebar, content with inline detail
   - Collapsible sidebar with toggle

3. Sidebar sections (NavigationSplitView sidebar):
   - Section: Home
     - 'Focus Now' (quick start)
     - 'Recently Played' (optional)
   - Section: Built-in Pack
     - Built-in playlists
   - Section: Library
     - All Items
     - Streams
     - YouTube
     - Audio URLs
   - Section: Playlists
     - User playlists (dynamic list)
   - Section: Imports (optional)
     - Imported pack groupings

4. Sidebar item views:
   - Icon + label for each item
   - Selection highlight
   - Badges for counts (optional)
   - Context menus per item type

5. Sidebar footer:
   - Add Playlist button (+)
   - Settings gear button

6. Content area:
   - Changes based on sidebar selection
   - Library views show grid/list
   - Playlist views show editor
   - Home shows dashboard

7. Window toolbar:
   - Search field (Cmd+F)
   - View toggle (grid/list)
   - Add item button

Acceptance criteria:
- Three-pane navigation works
- Sidebar selection changes content
- Sidebar is collapsible
- Window remembers size/position
- All sections are navigable


