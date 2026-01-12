---
id: skumring-alk
status: closed
deps: []
links: []
created: 2026-01-03T09:10:48.922999+01:00
type: task
priority: 0
---
# Implement M3U parsing in StreamResolver

In StreamResolver, detect .m3u extension. Fetch file contents, parse line by line, skip # comments, return first valid http(s) URL.


