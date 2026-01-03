import Foundation
import Observation

/// Central state container for the Skumring app.
///
/// AppModel is the root observable object injected into the SwiftUI environment.
/// It holds references to all major subsystems: LibraryStore, PlaybackController,
/// and UI navigation state.
///
/// Usage:
/// ```swift
/// @State private var appModel = AppModel()
/// // ...
/// ContentView()
///     .environment(appModel)
/// ```
@Observable
final class AppModel {
    
    // MARK: - Subsystems
    
    /// Manages all library items and playlists
    let libraryStore: LibraryStore
    
    // TODO: Add playbackController when PlaybackController is implemented
    // let playbackController: PlaybackController
    
    // MARK: - Navigation State
    
    /// Currently selected item in the sidebar, if any
    var selectedSidebarItem: SidebarItem?
    
    /// Set of item IDs currently selected in the library view (for multi-selection)
    var selectedItemIDs: Set<UUID> = []
    
    // MARK: - Initialization
    
    init() {
        self.libraryStore = LibraryStore()
        // Future: Initialize PlaybackController here
    }
}
