import Foundation

/// Centralized accessibility identifiers for UI testing.
///
/// Using an enum ensures compile-time safety and autocomplete support.
/// These identifiers must match the `.accessibilityIdentifier()` modifiers
/// applied in the SwiftUI views.
///
/// Naming convention: `<View>.<Element>`
enum AccessibilityIdentifiers {
    
    // MARK: - Sidebar
    
    enum Sidebar {
        static let list = "sidebar.list"
        static let homeRow = "sidebar.home"
        static let allItemsRow = "sidebar.allItems"
        static let streamsRow = "sidebar.streams"
        static let youtubeRow = "sidebar.youtube"
        static let audioURLsRow = "sidebar.audioURLs"
        static let importsRow = "sidebar.imports"
        static let newPlaylistButton = "sidebar.newPlaylist"
    }
    
    // MARK: - Library View
    
    enum Library {
        static let grid = "library.grid"
        static let list = "library.list"
        static let searchField = "library.search"
        static let viewModeToggle = "library.viewMode"
        static let emptyState = "library.emptyState"
        static let addItemButton = "library.addItem"
    }
    
    // MARK: - Add Item Sheet
    
    enum AddItemSheet {
        static let sheet = "addItemSheet"
        static let urlField = "addItemSheet.url"
        static let titleField = "addItemSheet.title"
        static let tagsField = "addItemSheet.tags"
        static let addButton = "addItemSheet.add"
        static let cancelButton = "addItemSheet.cancel"
        static let detectedKindLabel = "addItemSheet.detectedKind"
    }
    
    // MARK: - Library Item
    
    enum LibraryItem {
        /// Base identifier for library items, append item ID for specific items
        static let prefix = "libraryItem."
        
        static func item(id: String) -> String {
            "\(prefix)\(id)"
        }
        
        static func playButton(id: String) -> String {
            "\(prefix)\(id).play"
        }
        
        static func deleteButton(id: String) -> String {
            "\(prefix)\(id).delete"
        }
    }
    
    // MARK: - Now Playing Bar
    
    enum NowPlayingBar {
        static let bar = "nowPlayingBar"
        static let artwork = "nowPlayingBar.artwork"
        static let title = "nowPlayingBar.title"
        static let subtitle = "nowPlayingBar.subtitle"
        static let playPauseButton = "nowPlayingBar.playPause"
        static let previousButton = "nowPlayingBar.previous"
        static let nextButton = "nowPlayingBar.next"
        static let progressBar = "nowPlayingBar.progress"
        static let volumeSlider = "nowPlayingBar.volume"
        static let repeatButton = "nowPlayingBar.repeat"
        static let shuffleButton = "nowPlayingBar.shuffle"
        static let queueButton = "nowPlayingBar.queue"
    }
    
    // MARK: - Queue View
    
    enum Queue {
        static let popover = "queue.popover"
        static let list = "queue.list"
        static let clearButton = "queue.clear"
        static let emptyState = "queue.emptyState"
    }
    
    // MARK: - Playlist Editor
    
    enum PlaylistEditor {
        static let view = "playlistEditor"
        static let list = "playlistEditor.list"
        static let nameField = "playlistEditor.name"
        static let playAllButton = "playlistEditor.playAll"
        static let emptyState = "playlistEditor.emptyState"
    }
    
    // MARK: - Home View
    
    enum Home {
        static let view = "home"
        static let quickPlaySection = "home.quickPlay"
        static let recentSection = "home.recent"
    }
    
    // MARK: - Alerts & Dialogs
    
    enum Alert {
        static let deleteConfirmation = "alert.deleteConfirmation"
        static let importProgress = "alert.importProgress"
        static let importResults = "alert.importResults"
    }
}
