---
id: skumring-v7i
status: closed
deps: [skumring-ksb]
links: []
created: 2026-01-02T17:47:53.088873+01:00
type: task
priority: 1
parent: skumring-xb4
---
# Implement keyboard shortcuts

Add comprehensive keyboard shortcuts:

1. Playback shortcuts:
   - Space: Play/Pause
   - Cmd+Right Arrow: Next track
   - Cmd+Left Arrow: Previous track
   - Cmd+Up Arrow: Volume up
   - Cmd+Down Arrow: Volume down

2. Navigation shortcuts:
   - Cmd+1: Go to Home
   - Cmd+2: Go to Library
   - Cmd+3: Go to Playlists
   - Cmd+F: Focus search field
   - Escape: Clear search / Close sheet

3. Library management shortcuts:
   - Cmd+N: New Playlist
   - Cmd+L: Add Link/Item
   - Cmd+E: Export
   - Cmd+I: Import
   - Cmd+Backspace: Delete selected

4. Playlist shortcuts:
   - Enter: Play selected item/playlist
   - Cmd+D: Duplicate playlist
   - Cmd+R: Toggle repeat (cycle modes)
   - Cmd+Shift+S: Toggle shuffle

5. Implementation:
   - Use SwiftUI .keyboardShortcut() modifier
   - Add commands to menu bar
   - Handle in App struct Commands

6. Menu bar commands:
   - File menu: New, Import, Export
   - Edit menu: Delete, Select All
   - Controls menu: Play, Pause, Next, Previous, Repeat, Shuffle
   - View menu: Show Sidebar, View options
   - Window menu: standard window commands
   - Help menu: keyboard shortcuts list

7. Custom shortcuts (optional):
   - Allow user customization
   - Store in UserDefaults

8. Discoverability:
   - Show shortcuts in menu items
   - Show shortcuts in tooltips
   - Help > Keyboard Shortcuts reference

Acceptance criteria:
- All core shortcuts work
- Shortcuts shown in menus
- No conflicts with system shortcuts
- Space reliably toggles playback
- Cmd+F focuses search


