---
id: skumring-o3g
status: closed
deps: [skumring-ksb, skumring-wyw]
links: []
created: 2026-01-02T17:45:11.075996+01:00
type: task
priority: 1
parent: skumring-r3a
---
# Implement Home/Focus Now dashboard

Create the Home screen with quick-start focus options:

1. HomeView (Focus Now dashboard):
   - First screen shown on app launch
   - Quick access to start focusing

2. Quick Play section:
   - Large 'Focus Now' CTA button
   - Plays default/last playlist immediately
   - Prominent, enticing design

3. Favorite playlists row:
   - Horizontal scroll of top playlists
   - Cards with artwork and name
   - One-click to play
   - 3-6 items visible

4. Recently Played section:
   - Grid or list of last 6-10 played items
   - Shows artwork, title, when played
   - One-click to play
   - 'See All' link to full history (optional)

5. Quick stations:
   - Row of favorite individual streams
   - Radio-button style quick access
   - Currently playing highlighted

6. First launch experience:
   - If library empty/new user:
     - Show built-in pack prominently
     - 'Try Focus Now' CTA
     - Hint: 'Add your own stations with Cmd+L'

7. Customization (optional P2):
   - Pin playlists to home
   - Reorder sections
   - Hide sections

8. Time-of-day greeting (optional):
   - 'Good morning' / 'Good afternoon' / 'Good evening'
   - Suggest appropriate playlists

Acceptance criteria:
- Home screen loads on app start
- Focus Now button starts playback
- Recent items show correctly
- First launch shows helpful content
- One-click to play any featured item


