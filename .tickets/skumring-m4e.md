---
id: skumring-m4e
status: closed
deps: []
links: []
created: 2026-01-03T09:12:30.368185+01:00
type: task
priority: 1
---
# Implement ArtworkCache size limit and LRU eviction

Add maxCacheSize: Int (100MB). On cache write, check total size. If over limit, delete oldest accessed files until under limit.


