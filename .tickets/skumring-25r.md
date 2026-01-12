---
id: skumring-25r
status: closed
deps: [skumring-fza, skumring-7o5]
links: []
created: 2026-01-02T17:38:45.344159+01:00
type: task
priority: 0
parent: skumring-zhs
---
# Implement AVPlaybackBackend for streams and audio URLs

Create the AVPlayer-based backend for stream and audio URL playback:

1. AVPlaybackBackend class:
   - player: AVPlayer
   - currentURL: URL?
   - delegate: PlaybackBackendDelegate?
   - Conforms to PlaybackBackend protocol

2. PlaybackBackend protocol:
   - play(url: URL) async throws
   - pause()
   - resume()
   - stop()
   - seek(to: TimeInterval)
   - setVolume(_ volume: Float)
   - var isPlaying: Bool
   - var currentTime: TimeInterval?
   - var duration: TimeInterval?
   - var state: PlaybackState

3. AVPlayer configuration:
   - Use AVPlayer (not AVAudioPlayer) for streaming
   - Configure for background audio (if supported)
   - Set audio session category appropriately
   - Enable rate change observation

4. Supported formats:
   - MP3, AAC, M4A audio files
   - HLS streams (.m3u8)
   - Direct stream URLs
   - Note: .m3u/.pls resolution handled by StreamResolver first

5. State observation (KVO or Combine):
   - Observe player.timeControlStatus
   - Observe player.currentItem.status
   - Observe player.currentItem.duration
   - Publish periodic time updates (1 second interval)

6. Error handling:
   - Handle AVPlayerItem failures
   - Detect network errors
   - Provide clear error types to controller

7. Resource management:
   - Clean up on stop
   - Release player when not in use
   - Handle audio interruptions (phone call, etc.)

Acceptance criteria:
- Can play a known good MP3 URL
- Can play a known good stream URL
- Playback survives for 30+ minutes without issues
- Volume changes work
- Errors are reported to controller


