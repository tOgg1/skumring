---
id: skumring-wpw
status: closed
deps: []
links: []
created: 2026-01-03T09:09:56.425107+01:00
type: task
priority: 0
---
# Add healthStatus property to LibraryItem

Create HealthStatus enum (unknown, ok, failing) in Models/HealthStatus.swift. Add healthStatus: HealthStatus and failCount: Int to LibraryItem. Default healthStatus to .unknown, failCount to 0.


