---
id: skumring-937q
status: closed
deps: []
links: []
created: 2026-01-04T07:20:33.98746+01:00
type: feature
priority: 1
---
# Add dedicated Now Playing view as main player interface

Create a dedicated 'Now Playing' view that becomes the primary player interface. This view should:

**Layout:**
- Takes over the main content area (right side of the split view)
- Shows the video/artwork player prominently (centered, proper 16:9 for video)
- Displays track info (title, artist/subtitle, album art for audio)
- Shows playback controls (play/pause, next/prev, seek bar, volume)
- Lists upcoming queue items below or to the side

**Behavior:**
- Automatically navigate to this view when playback starts
- Serves as the launching point for fullscreen mode
- Previous/Next buttons to navigate queue
- For audio streams: show artwork or visualizer
- For YouTube: show the video player

**Navigation:**
- Should be accessible from sidebar (e.g., 'Now Playing' item)
- Auto-shows when user initiates playback from library
- User can navigate away but can return via sidebar or clicking NowPlayingBar

This replaces the current approach where YouTube player appears as a strip above the NowPlayingBar, creating a more intentional and immersive playback experience.


