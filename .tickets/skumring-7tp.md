---
id: skumring-7tp
status: closed
deps: [skumring-5hv]
links: []
created: 2026-01-02T17:44:50.433566+01:00
type: task
priority: 0
parent: skumring-r3a
---
# Implement YouTube player view integration

Create the UI for displaying YouTube embedded player:

1. YouTubePlayerContainerView:
   - Container for WKWebView-based YouTube player
   - Minimum size: 200x200 (per YouTube policy)
   - Recommended aspect: 16:9 (e.g., 480x270)
   - Resizable with aspect ratio lock

2. Placement options:
   - Option A: Detail panel in NavigationSplitView
     - Shows when YouTube item is playing
     - Replaces/overlays normal detail view
   - Option B: Floating panel
     - Separate window that stays on top
     - Can be repositioned
   - Option C: Inline in content area
     - YouTube player appears above/below library content

3. Player chrome (around WebView):
   - Title bar with video name
   - Minimize button (pauses playback, shows warning)
   - Close button (stops playback)
   - Full-screen toggle (optional)

4. Ambient artwork mode:
   - Background image/gradient around player
   - Based on video thumbnail colors
   - Creates pleasant visual ambiance

5. Policy compliance UI:
   - Show YouTube branding appropriately
   - Don't obstruct player controls
   - Ensure player is interactable

6. Transition animations:
   - Smooth transition when YouTube item starts
   - Fade in player area
   - Resize animation if needed

7. Non-YouTube item behavior:
   - When stream/audio playing, hide YouTube container
   - Show regular Now Playing artwork instead
   - Smooth transition between modes

8. Error states:
   - Video unavailable: show message with 'Open on YouTube' button
   - Embed blocked: show message explaining restriction
   - Loading: show spinner/skeleton

Acceptance criteria:
- YouTube player visible and at least 200x200
- Player controls work
- Transitions are smooth
- Error states are clear
- Policy-compliant presentation


