---
id: skumring-na4
status: closed
deps: [skumring-fza]
links: []
created: 2026-01-02T17:47:29.024897+01:00
type: task
priority: 1
parent: skumring-xb4
---
# Implement media key support

Add support for keyboard media keys:

1. Media key handling:
   - Play/Pause key (F8 or dedicated)
   - Previous Track key (F7 or dedicated)
   - Next Track key (F9 or dedicated)
   - Volume Up/Down (system handles, but consider)

2. Implementation approaches:
   - MPRemoteCommandCenter (preferred, system integration)
   - or MediaKeyTap library for direct handling

3. MPRemoteCommandCenter setup:
   - Enable play command
   - Enable pause command
   - Enable togglePlayPause command
   - Enable nextTrack command
   - Enable previousTrack command
   - Set command handlers to PlaybackController methods

4. Now Playing Info Center:
   - Set MPNowPlayingInfoCenter.default().nowPlayingInfo
   - Include:
     - MPMediaItemPropertyTitle
     - MPMediaItemPropertyArtist (subtitle)
     - MPMediaItemPropertyArtwork
     - MPMediaItemPropertyPlaybackDuration (if known)
     - MPNowPlayingInfoPropertyElapsedPlaybackTime
     - MPNowPlayingInfoPropertyPlaybackRate

5. Update on changes:
   - Update Now Playing info when track changes
   - Update elapsed time periodically
   - Clear info when stopped

6. App focus considerations:
   - Should work when app is not frontmost
   - Should work when app is minimized
   - Consider conflicts with other apps (Spotify, Music)

7. Testing:
   - Test with MacBook keyboard
   - Test with external Apple keyboard
   - Test with Touch Bar (if applicable)
   - Test Control Center Now Playing widget

Acceptance criteria:
- Play/Pause key toggles playback
- Next/Previous keys work
- Works when app is in background
- Now Playing widget shows current track
- No conflicts with system media apps


