---
id: skumring-a16
status: closed
deps: [skumring-fza, skumring-ksb]
links: []
created: 2026-01-02T17:44:28.62878+01:00
type: task
priority: 0
parent: skumring-r3a
---
# Implement Now Playing bar

Create the persistent Now Playing bar at the bottom of the window:

1. NowPlayingBar view:
   - Fixed at bottom of main window
   - Height: approximately 72-80 points
   - Always visible (even when nothing playing, shows empty state)

2. Layout (left to right):
   - Artwork thumbnail (56x56)
   - Track info:
     - Title (primary text)
     - Subtitle/artist (secondary text)
     - Source type badge
   - Playback controls (center):
     - Previous button
     - Play/Pause button (large, primary)
     - Next button
   - Secondary controls:
     - Shuffle toggle
     - Repeat toggle
   - Right section:
     - Volume slider
     - Queue button (opens popover)

3. Playback controls behavior:
   - Previous: go to previous in queue, or restart if >3s into track
   - Play/Pause: toggle playback
   - Next: go to next in queue
   - Disabled states when not applicable

4. Track info interaction:
   - Click artwork: open Now Playing detail view (if exists)
   - Click title: navigate to item in library
   - Marquee scroll for long titles

5. Progress indicator (for finite content):
   - Thin progress bar above or below controls
   - Current time / duration display
   - Seekable (click to seek)
   - For streams: show 'LIVE' badge instead

6. Volume control:
   - Slider (0-100%)
   - Mute button (speaker icon)
   - Remember last volume

7. Empty state:
   - When nothing playing:
     - Dimmed appearance
     - 'Not Playing' text
     - Controls disabled

8. YouTube-specific:
   - When YouTube item playing, show hint about visible player
   - Optional: button to focus YouTube player view

Acceptance criteria:
- Bar shows current track info
- Play/pause works
- Next/previous work
- Volume control works
- Empty state is clear
- Progress bar shows for finite content


