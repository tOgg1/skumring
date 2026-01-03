import Foundation

/// Represents the different navigation destinations in the sidebar.
///
/// SidebarItem defines all possible selections in the app's sidebar navigation.
/// It supports both fixed destinations (home, allItems, etc.) and dynamic
/// destinations like specific playlists.
enum SidebarItem: Hashable, Sendable {
    /// Home view with featured content and quick actions
    case home
    
    /// A built-in pack of curated content (shows all built-in items)
    case builtInPack
    
    /// A specific item from the built-in pack
    case builtInItem(UUID)
    
    /// All items in the library
    case allItems
    
    /// Streaming radio stations
    case streams
    
    /// YouTube videos
    case youtube
    
    /// Direct audio URLs
    case audioURLs
    
    /// A specific user-created playlist
    case playlist(UUID)
    
    /// Import queue for adding new items
    case imports
}
