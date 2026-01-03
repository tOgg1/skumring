# Decision: YouTube Playback in WKWebView

**Date:** 2026-01-03  
**Status:** Accepted  
**Context:** Milestone 0 PoC for Skumring

## Problem

YouTube playback is required for Skumring. The standard approaches don't work:

1. **IFrame Embed API via `loadHTMLString`** — Error 152 (embedding disabled)
2. **Direct embed URL (`youtube.com/embed/`)** — Error 153 (configuration error)
3. **youtube-nocookie.com embed** — Same Error 153

YouTube actively blocks embed playback in WKWebView contexts that don't have a proper web origin.

## Solution

Load the full YouTube watch page (`youtube.com/watch?v=VIDEO_ID`) and inject CSS to hide the YouTube UI, leaving only the video player visible.

### Implementation

1. Load `https://www.youtube.com/watch?v=VIDEO_ID` in WKWebView
2. Set a Safari User-Agent to avoid detection
3. After page load, inject CSS that:
   - Hides header, sidebar, comments, related videos, description
   - Makes video player fullscreen
   - Hides end-screen recommendations
   - Sets black background
4. Inject JS to monitor `<video>` element events (play/pause/time/etc.)
5. Control playback via JS: `document.querySelector('video').play()` etc.

### Trade-offs

**Pros:**
- Works reliably
- Full YouTube player controls available
- No API key required
- Compliant with YouTube ToS (we're displaying the player, not extracting audio)

**Cons:**
- Depends on YouTube's DOM structure (may break with YouTube updates)
- Initial page load includes more content than needed
- CSS selectors may need maintenance

### Mitigation

- Keep CSS selectors broad and defensive
- Monitor for breakage in updates
- The core `<video>` element interface is stable

## Code Location

- `Skumring/Skumring/YouTubePlayerView.swift` — WKWebView wrapper with CSS/JS injection
- `Skumring/Skumring/YouTubePlayer.swift` — Observable state model

## Validation

Tested on macOS Tahoe 26 with Xcode 26.2:
- Video loads and plays ✓
- Play/Pause commands work ✓  
- Time updates received ✓
- State changes detected ✓
- UI is clean (YouTube chrome hidden) ✓
