---
id: skumring-fza
status: closed
deps: [skumring-h9n]
links: []
created: 2026-01-02T17:38:25.231568+01:00
type: task
priority: 0
parent: skumring-zhs
---
# Implement PlaybackController unified API

Create the central PlaybackController that provides a unified playback API:

1. PlaybackController class (@Observable):
   - currentItem: LibraryItem? (published)
   - playbackState: PlaybackState (published)
   - isPlaying: Bool (published)
   - currentTime: TimeInterval? (for finite content)
   - duration: TimeInterval? (for finite content)
   - volume: Float (0.0 - 1.0, published)
   - repeatMode: RepeatMode (published)
   - shuffleMode: ShuffleMode (published)
   - queue: [LibraryItem] (published)
   - queueIndex: Int (published)
   - error: PlaybackError? (published)

2. PlaybackState enum:
   - idle
   - loading
   - playing
   - paused
   - error(PlaybackError)

3. PlaybackError enum:
   - networkUnavailable
   - streamUnavailable
   - youtubeRestricted
   - unsupportedFormat
   - unknown(Error)

4. Playback control methods:
   - play(item: LibraryItem)
   - play(playlist: Playlist, startingAt: Int = 0)
   - pause()
   - resume()
   - stop()
   - next()
   - previous()
   - seek(to: TimeInterval)
   - setVolume(_ volume: Float)
   - setRepeatMode(_ mode: RepeatMode)
   - setShuffleMode(_ mode: ShuffleMode)

5. Internal backend routing:
   - Determine item type and route to appropriate backend
   - AVPlaybackBackend for streams and audio URLs
   - YouTubePlaybackBackend for YouTube items
   - Handle backend switching cleanly

6. Queue management:
   - Build queue from playlist or single item
   - Handle shuffle by shuffling queue copy
   - Handle repeat modes in next/previous logic

Acceptance criteria:
- Single API for all playback operations
- State updates propagate to UI immediately
- Next/Previous works correctly with repeat/shuffle
- Volume persists across items
- Errors surface clearly to UI


