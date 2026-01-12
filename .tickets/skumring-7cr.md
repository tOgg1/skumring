---
id: skumring-7cr
status: closed
deps: [skumring-5hv]
links: []
created: 2026-01-02T17:40:07.290397+01:00
type: task
priority: 0
parent: skumring-zhs
---
# Implement YouTube visibility compliance (pause when hidden)

Ensure YouTube playback complies with policy by pausing when player is not visible:

1. Window visibility monitoring:
   - Observe NSApplication.didHideApplicationNotification
   - Observe NSApplication.didUnhideApplicationNotification
   - Observe NSWindow.didMiniaturizeNotification
   - Observe window occlusion state changes

2. View visibility monitoring:
   - Track if YouTube player view is in visible view hierarchy
   - Track if YouTube player is scrolled out of view
   - Track if another view is covering the player

3. Behavior when player becomes hidden:
   - Pause YouTube playback
   - Show notification/hint: 'YouTube paused - player must be visible'
   - Do NOT allow background audio (this violates policy)

4. Behavior when player becomes visible again:
   - Optionally auto-resume (user preference)
   - Or show 'Resume' button

5. UI hint for users:
   - If user tries to minimize/hide while YouTube playing:
     - Show brief tooltip explaining policy
     - 'YouTube requires the player to be visible during playback'
   - Consider showing this in onboarding for YouTube items

6. Distinction from streams:
   - AVPlayer streams CAN continue when window is hidden
   - Only YouTube has this restriction
   - Clear differentiation in UI if needed

Acceptance criteria:
- YouTube pauses when window minimized
- YouTube pauses when app hidden
- Clear message explains why
- Streams continue to play when hidden (different behavior)
- No policy-violating background YouTube audio


