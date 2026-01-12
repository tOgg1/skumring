---
id: skumring-7o5
status: closed
deps: []
links: []
created: 2026-01-02T17:39:04.20561+01:00
type: task
priority: 0
parent: skumring-zhs
---
# Implement StreamResolver for .m3u and .pls files

Create the StreamResolver service to resolve playlist files to playable URLs:

1. StreamResolver class:
   - Static or singleton service
   - resolveURL(_ url: URL) async throws -> URL

2. M3U parsing:
   - Fetch .m3u file content
   - Parse line by line
   - Skip comment lines (starting with #)
   - Find first valid http(s) URL line
   - Support extended M3U (#EXTM3U) header
   - Handle relative URLs by resolving against base

3. PLS parsing:
   - Fetch .pls file content
   - Parse INI-like format
   - Extract File1= value (first entry)
   - Handle NumberOfEntries
   - Extract Title1= for metadata if available

4. Resolution logic:
   - Check if URL ends in .m3u or .pls (case insensitive)
   - If so, fetch and parse
   - If resolved URL also ends in .m3u/.pls, recurse (with depth limit)
   - Return direct playable URL

5. Caching (optional):
   - Cache resolved URLs for short period (5 minutes)
   - Invalidate on playback failure

6. Error handling:
   - Network fetch failures
   - Parse failures (invalid format)
   - No valid URLs found
   - Timeout (e.g., 10 seconds)

Acceptance criteria:
- Can resolve a known good .m3u file to playable URL
- Can resolve a known good .pls file to playable URL
- Invalid files return clear error
- Recursive resolution works (nested playlists)
- Timeout prevents hanging on slow servers


