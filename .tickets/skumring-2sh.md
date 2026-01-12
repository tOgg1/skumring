---
id: skumring-2sh
status: closed
deps: []
links: []
created: 2026-01-03T09:10:49.157458+01:00
type: task
priority: 0
---
# Add recursive resolution to StreamResolver

In StreamResolver, if resolved URL is also .m3u/.pls, recurse (max depth 3). Prevent infinite loops.


