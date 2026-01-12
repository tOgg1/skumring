---
id: skumring-1mb
status: closed
deps: [skumring-a16]
links: []
created: 2026-01-02T17:48:13.325588+01:00
type: task
priority: 2
parent: skumring-xb4
---
# Implement menu bar mini-player (optional)

Add optional menu bar status item with mini player:

1. Menu bar status item:
   - Small icon in menu bar (speaker or app icon)
   - Click to show popover
   - Optional: click to toggle play/pause, hold for menu

2. Mini player popover:
   - Compact Now Playing display:
     - Artwork (small)
     - Title
     - Subtitle
   - Controls:
     - Previous
     - Play/Pause
     - Next
   - Volume slider
   - 'Open Skumring' button

3. Implementation:
   - NSStatusItem
   - NSPopover for mini player
   - SwiftUI view inside popover

4. Status item icon states:
   - Playing: animated or highlighted icon
   - Paused: normal icon
   - Nothing playing: dimmed icon

5. Preferences:
   - Enable/disable menu bar item
   - Show in menu bar when playing only
   - Store preference in UserDefaults

6. Interaction with main window:
   - Both can control playback
   - State synchronized
   - 'Open in main window' action

7. Quick actions menu:
   - Right-click status item:
     - Quick playlist selection
     - Recently played
     - Quit

8. Design:
   - Match system menu bar aesthetics
   - Consider Liquid Glass for popover
   - Support dark and light menu bar

Acceptance criteria:
- Menu bar item shows current state
- Popover shows Now Playing info
- Controls work from popover
- Can be enabled/disabled in preferences
- Works with main window closed


