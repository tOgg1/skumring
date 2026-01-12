---
id: skumring-ssjq
status: closed
deps: []
links: []
created: 2026-01-03T09:12:53.155983+01:00
type: task
priority: 1
---
# Implement stream reconnection with exponential backoff

In AVPlaybackBackend, on stream failure, attempt reconnect up to 3 times with delays: 1s, 2s, 4s. Update state to .error after final failure.


