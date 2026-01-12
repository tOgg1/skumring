---
id: skumring-f3q
status: closed
deps: [skumring-wyw]
links: []
created: 2026-01-02T17:37:29.120932+01:00
type: task
priority: 2
parent: skumring-fo9
---
# Implement ArtworkCache service

Create a lightweight disk cache for artwork images:

1. ArtworkCache class:
   - Singleton or injected service
   - Cache location: Application Support/<bundle id>/artwork_cache/
   - Max cache size: configurable (default 100MB)

2. Core methods:
   - getImage(for url: URL) async -> NSImage?
   - prefetchImage(for url: URL) async
   - clearCache()
   - cacheSize() -> Int64
   - pruneCache(to maxSize: Int64)

3. Implementation details:
   - Use URLSession for downloads
   - Hash URL to create filename
   - Store as PNG or JPEG on disk
   - In-memory NSCache for hot items
   - LRU eviction when cache is full
   - Handle download failures gracefully
   - Support cancellation

4. SwiftUI integration:
   - Create CachedAsyncImage view that uses ArtworkCache
   - Placeholder while loading
   - Error state fallback image

5. Optimization:
   - Resize images to max display size before caching
   - Support multiple resolutions if needed
   - Avoid re-downloading existing cached images

Acceptance criteria:
- Images load from cache on second request
- Cache respects size limits
- App starts quickly even with large cache
- Network errors don't crash the app


