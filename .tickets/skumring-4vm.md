---
id: skumring-4vm
status: closed
deps: []
links: []
created: 2026-01-03T09:10:38.921355+01:00
type: task
priority: 0
---
# Define PlaybackBackend protocol

Create Services/PlaybackBackend.swift protocol. Methods: play(url: URL) async throws, pause(), resume(), stop(), seek(to: TimeInterval), setVolume(Float). Properties: isPlaying: Bool, currentTime: TimeInterval?, duration: TimeInterval?, state: PlaybackState.


