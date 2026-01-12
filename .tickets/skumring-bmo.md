---
id: skumring-bmo
status: closed
deps: [skumring-7o5]
links: []
created: 2026-01-02T17:49:02.022655+01:00
type: task
priority: 1
parent: skumring-a5b
---
# Implement unit tests for StreamResolver

Create unit tests for stream URL resolution:

1. M3U parsing tests:
   - Parse simple M3U with single URL
   - Parse M3U with comments (lines starting with #)
   - Parse extended M3U (#EXTM3U header)
   - Parse M3U with multiple URLs (pick first valid)
   - Handle empty lines
   - Handle whitespace

2. PLS parsing tests:
   - Parse simple PLS with File1=
   - Parse PLS with NumberOfEntries
   - Parse PLS with Title1= metadata
   - Handle File2, File3 etc (use File1)
   - Handle malformed PLS gracefully

3. Resolution logic tests:
   - Direct MP3 URL returns unchanged
   - .m3u URL fetches and parses
   - .pls URL fetches and parses
   - Recursive resolution (nested playlists)
   - Depth limit prevents infinite loops

4. Error handling tests:
   - Network error returns appropriate error
   - Invalid M3U content returns error
   - No valid URLs found returns error
   - Timeout handling

5. Mock network layer:
   - Use URLProtocol mock for testing
   - Provide mock responses for various formats
   - Simulate network failures

6. Test fixtures:
   - Create sample .m3u files
   - Create sample .pls files
   - Include edge cases

Acceptance criteria:
- M3U parsing covers all common formats
- PLS parsing covers common formats
- Errors are handled gracefully
- Recursive resolution works with limits
- Tests use mocked network (fast, reliable)


