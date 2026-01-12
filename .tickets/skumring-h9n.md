---
id: skumring-h9n
status: closed
deps: [skumring-ezx]
links: []
created: 2026-01-02T17:35:59.320118+01:00
type: task
priority: 0
parent: skumring-y8g
---
# Create AppModel and global state architecture

Implement the central AppModel that holds all app state:

1. AppModel (@Observable or ObservableObject):
   - libraryStore: LibraryStore (reference)
   - playbackController: PlaybackController (reference)
   - selectedSidebarItem: SidebarItem?
   - selectedPlaylistID: UUID?
   - selectedItemID: UUID?
   - searchQuery: String
   - isShowingImportDialog: Bool
   - isShowingExportDialog: Bool
   - isShowingAddItemSheet: Bool

2. SidebarItem enum:
   - home
   - builtInPack
   - library(filter: LibraryFilter)
   - playlist(id: UUID)
   - imports

3. LibraryFilter enum:
   - all
   - streams
   - youtube
   - audioURLs

4. App entry point integration:
   - Create AppModel as @StateObject in App struct
   - Pass down via @EnvironmentObject
   - Initialize LibraryStore and PlaybackController

5. Consider using @MainActor for UI-bound state

Acceptance criteria:
- AppModel compiles and can be instantiated
- State changes trigger SwiftUI view updates
- All child services can be accessed through AppModel


