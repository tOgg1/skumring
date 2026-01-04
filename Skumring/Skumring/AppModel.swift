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
@MainActor
@Observable
final class AppModel {
    
    // MARK: - Subsystems
    
    /// Manages all library items and playlists
    let libraryStore: LibraryStore
    
    /// Controls playback across all backends
    let playbackController: PlaybackController
    
    /// Cache for artwork images
    let artworkCache: ArtworkCache
    
    /// Updates system Now Playing info with current playback
    private(set) var nowPlayingService: NowPlayingService?
    
    // MARK: - Navigation State
    
    /// Currently selected item in the sidebar, if any
    var selectedSidebarItem: SidebarItem?
    
    /// Set of item IDs currently selected in the library view (for multi-selection)
    var selectedItemIDs: Set<UUID> = []
    
    // MARK: - Sheet State
    
    /// Controls visibility of the Add Item sheet (triggered by Cmd+L or File > Add Item...)
    var showAddItemSheet: Bool = false
    
    /// Controls triggering the import file picker (triggered by File > Import... or empty state CTA)
    var showImportPicker: Bool = false
    
    // MARK: - Fullscreen State
    
    /// Controls fullscreen mode for the YouTube player (triggered by F key or fullscreen button)
    var isFullscreen: Bool = false
    
    // MARK: - Initialization
    
    init() {
        self.libraryStore = LibraryStore()
        self.playbackController = PlaybackController()
        self.artworkCache = ArtworkCache()
        
        // Initialize Now Playing service after other properties are set
        self.nowPlayingService = NowPlayingService(
            playbackController: playbackController,
            artworkCache: artworkCache
        )
    }
}
