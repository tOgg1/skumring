---
id: skumring-dga
status: closed
deps: []
links: []
created: 2026-01-03T09:09:56.769771+01:00
type: task
priority: 0
---
# Define Playlist struct with id, name, itemIDs, repeatMode, shuffleMode

Create Playlist struct in Models/Playlist.swift. Properties: id (UUID), name (String), itemIDs ([UUID]), repeatMode (RepeatMode, default .off), shuffleMode (ShuffleMode, default .off), createdAt (Date). Conform to Codable, Identifiable.


