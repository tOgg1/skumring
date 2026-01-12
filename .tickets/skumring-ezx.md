---
id: skumring-ezx
status: closed
deps: [skumring-8dz]
links: []
created: 2026-01-02T17:35:42.142379+01:00
type: task
priority: 0
parent: skumring-y8g
---
# Define core data models (LibraryItem, Playlist, Pack)

Create the canonical Swift data models as defined in the spec:

1. LibraryItem model:
   - id: UUID (stable identifier)
   - kind: ItemKind enum (stream, youtube, remoteAudio)
   - title: String
   - subtitle: String?
   - tags: [String]
   - source: ItemSource (URL or youtubeID)
   - artworkURL: URL?
   - addedAt: Date
   - lastPlayedAt: Date? (transient, not exported)
   
2. ItemSource enum/struct:
   - case stream(url: URL)
   - case youtube(videoID: String)
   - case remoteAudio(url: URL)

3. Playlist model:
   - id: UUID
   - name: String
   - itemIDs: [UUID] (ordered references)
   - repeatMode: RepeatMode (.off, .one, .all)
   - shuffleMode: ShuffleMode (.off, .on)
   - createdAt: Date
   - updatedAt: Date

4. Pack model (for import/export wrapper):
   - schemaVersion: Int
   - exportedAt: Date
   - appIdentifier: String
   - items: [LibraryItem]
   - playlists: [Playlist]

5. Supporting enums:
   - ItemKind: stream, youtube, remoteAudio
   - RepeatMode: off, one, all
   - ShuffleMode: off, on

All models must:
- Conform to Identifiable
- Conform to Codable for JSON serialization
- Conform to Hashable for SwiftUI diffing
- Use proper coding keys matching the JSON schema

Acceptance criteria:
- All models compile without errors
- Models can be encoded/decoded to JSON matching spec schema
- Unit tests verify round-trip encoding


