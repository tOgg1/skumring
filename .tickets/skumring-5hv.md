---
id: skumring-5hv
status: closed
deps: [skumring-fza]
links: []
created: 2026-01-02T17:39:46.738698+01:00
type: task
priority: 0
parent: skumring-zhs
---
# Implement YouTubePlaybackBackend with WKWebView embed

Create the YouTube playback backend using embedded WKWebView player:

1. YouTubePlaybackBackend class:
   - webView: WKWebView (managed internally)
   - currentVideoID: String?
   - delegate: PlaybackBackendDelegate?
   - Conforms to PlaybackBackend protocol

2. WKWebView setup:
   - Configure WKWebViewConfiguration
   - Enable JavaScript
   - Set up message handlers for player events
   - Configure for media playback

3. YouTube IFrame Player integration:
   - Load custom HTML page with YouTube IFrame API
   - Include JavaScript bridge for Swift communication
   - Parameters to set:
     - enablejsapi=1 (required for control)
     - origin=<app bundle identifier or localhost>
     - playsinline=1
     - controls=1 (show native controls)
     - rel=0 (don't show related videos)

4. JavaScript bridge events to handle:
   - onReady
   - onStateChange (PLAYING, PAUSED, ENDED, BUFFERING, CUED)
   - onError (INVALID_PARAM, HTML5_ERROR, NOT_FOUND, EMBED_NOT_ALLOWED, etc.)
   - onPlaybackQualityChange (optional)

5. Control methods (via JavaScript):
   - playVideo()
   - pauseVideo()
   - stopVideo()
   - seekTo(seconds, allowSeekAhead)
   - setVolume(0-100)
   - getCurrentTime()
   - getDuration()

6. Looping support (per YouTube spec):
   - For loop=1 to work, must also set playlist=VIDEO_ID
   - Inject as URL parameters

7. CRITICAL Policy compliance:
   - Player must be visible (at least 200x200)
   - Do NOT attempt to hide player or extract audio-only
   - Do NOT attempt to play when window is minimized
   - Add window visibility observer to pause if needed

8. SwiftUI integration:
   - Create YouTubePlayerView as NSViewRepresentable
   - Expose as a view that can be placed in Now Playing area

Acceptance criteria:
- YouTube video plays in embedded player
- Play/pause/seek controls work
- Player is always visible when playing
- Errors show clear messages
- Looping works for single video


