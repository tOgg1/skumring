---
id: skumring-2k4
status: closed
deps: []
links: []
created: 2026-01-03T09:09:56.887569+01:00
type: task
priority: 0
---
# Define Pack struct for import/export

Create Pack struct in Models/Pack.swift. Properties: schemaVersion (Int, currently 1), exportedAt (Date), appIdentifier (String), items ([LibraryItem]), playlists ([Playlist]). Conform to Codable.


