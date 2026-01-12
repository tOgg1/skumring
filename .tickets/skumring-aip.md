---
id: skumring-aip
status: closed
deps: [skumring-ezx]
links: []
created: 2026-01-02T17:48:43.310856+01:00
type: task
priority: 1
parent: skumring-a5b
---
# Implement unit tests for data models and JSON encoding

Create unit tests for core data models:

1. LibraryItem tests:
   - Test initialization with all parameters
   - Test Codable encoding/decoding round-trip
   - Test JSON output matches spec schema
   - Test all ItemKind cases
   - Test sourceKey computation

2. Playlist tests:
   - Test initialization
   - Test Codable round-trip
   - Test itemIDs ordering preserved
   - Test repeatMode and shuffleMode encoding

3. Pack tests:
   - Test full pack encoding/decoding
   - Test schemaVersion is included
   - Test exportedAt timestamp format
   - Test items and playlists arrays

4. Import validation tests:
   - Test valid pack passes validation
   - Test invalid schemaVersion rejected
   - Test invalid item kind rejected
   - Test missing URL/youtubeID rejected
   - Test file:// URLs rejected
   - Test malformed JSON handling

5. Deduplication tests:
   - Test sourceKey matching for streams
   - Test sourceKey matching for YouTube
   - Test URL normalization
   - Test duplicate detection

6. Edge cases:
   - Empty arrays
   - Unicode in titles/tags
   - Very long strings
   - Special characters in URLs

7. Test organization:
   - ModelsTests group
   - ImportExportTests group
   - Clear test naming convention

Acceptance criteria:
- All models have encoding tests
- All models have decoding tests
- Round-trip preserves all data
- Invalid data is rejected appropriately
- Tests run in < 5 seconds


