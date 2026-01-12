---
id: skumring-da6
status: closed
deps: [skumring-wyw]
links: []
created: 2026-01-02T17:42:28.747721+01:00
type: task
priority: 0
parent: skumring-xsn
---
# Implement ImportExportService

Create the core service for handling import and export operations:

1. ImportExportService class:
   - Dependencies: LibraryStore
   - Conforms to JSON schema version 1

2. Export methods:
   - exportLibrary() -> Pack
     - Exports all items and playlists
   - exportPlaylist(id: UUID) -> Pack
     - Exports single playlist with referenced items only
   - exportPlaylists(ids: [UUID]) -> Pack
     - Exports multiple playlists with referenced items
   - exportToFile(pack: Pack, url: URL) throws
     - Writes Pack as formatted JSON to file

3. Import methods:
   - importFromFile(url: URL) throws -> ImportResult
   - importPack(_ pack: Pack, options: ImportOptions) -> ImportResult
   - validatePack(_ pack: Pack) -> [ValidationError]

4. ImportOptions:
   - duplicateHandling: .skip | .replace | .duplicate
   - mergePlaylistItems: Bool (add to existing playlist if same name)

5. ImportResult:
   - itemsImported: Int
   - itemsSkipped: Int (duplicates)
   - itemsUpdated: Int
   - playlistsImported: Int
   - playlistsSkipped: Int
   - errors: [ImportError]

6. Deduplication logic:
   - Compute sourceKey for each item:
     - stream/remoteAudio: normalized URL (lowercase scheme+host)
     - youtube: videoID
   - Check if sourceKey exists in library
   - Apply duplicateHandling option

7. Schema migration:
   - Read schemaVersion from pack
   - If schemaVersion > current, reject with message
   - If schemaVersion < current, apply migrations
   - v1 is initial, no migrations needed yet

8. Validation:
   - schemaVersion must be recognized
   - Item kinds must be valid
   - URLs must be http(s)
   - Each item needs either url or youtubeID
   - Playlist itemIDs must reference valid items in pack

Acceptance criteria:
- Export creates valid JSON matching spec schema
- Import parses JSON correctly
- Duplicates handled per options
- Invalid packs show clear error messages
- Round-trip export/import preserves data


