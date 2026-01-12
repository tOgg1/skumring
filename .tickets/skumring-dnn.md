---
id: skumring-dnn
status: closed
deps: []
links: []
created: 2026-01-03T09:10:26.337345+01:00
type: task
priority: 0
---
# Call LibraryStore.load() on init and save() on changes

Update LibraryStore init to call load(). Add didSet observers or explicit save calls after mutations. Consider debouncing saves.


