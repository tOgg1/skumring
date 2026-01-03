import SwiftUI

/// The main detail view that displays content based on sidebar selection.
///
/// MainContentView acts as a router that switches the displayed content based
/// on the currently selected sidebar item. It handles all navigation destinations
/// defined in SidebarItem.
struct MainContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(LibraryStore.self) private var libraryStore
    
    var body: some View {
        Group {
            if let selectedItem = appModel.selectedSidebarItem {
                contentView(for: selectedItem)
            } else {
                emptyStateView
            }
        }
    }
    
    // MARK: - Content Routing
    
    /// Returns the appropriate view for the given sidebar selection
    @ViewBuilder
    private func contentView(for item: SidebarItem) -> some View {
        switch item {
        case .home:
            HomeView()
            
        case .builtInPack:
            BuiltInPackView()
            
        case .allItems:
            LibraryView(filter: .all)
            
        case .streams:
            LibraryView(filter: .streams)
            
        case .youtube:
            LibraryView(filter: .youtube)
            
        case .audioURLs:
            LibraryView(filter: .audioURLs)
            
        case .imports:
            ImportsView()
            
        case .playlist(let playlistID):
            if let playlist = libraryStore.playlist(withID: playlistID) {
                PlaylistView(playlist: playlist)
            } else {
                // Playlist was deleted
                ContentUnavailableView(
                    "Playlist Not Found",
                    systemImage: "music.note.list",
                    description: Text("This playlist no longer exists.")
                )
            }
        }
    }
    
    // MARK: - Empty State
    
    /// Displayed when no sidebar item is selected
    private var emptyStateView: some View {
        ContentUnavailableView(
            "Select an Item",
            systemImage: "sidebar.left",
            description: Text("Choose something from the sidebar to get started.")
        )
    }
}

// MARK: - Placeholder Views

/// Placeholder for the home/focus view
struct HomeView: View {
    var body: some View {
        ContentUnavailableView(
            "Focus Now",
            systemImage: "house",
            description: Text("Your personalized home screen will appear here.")
        )
        .navigationTitle("Home")
    }
}

/// Placeholder for the built-in pack view
struct BuiltInPackView: View {
    var body: some View {
        ContentUnavailableView(
            "Curated Stations",
            systemImage: "star",
            description: Text("Curated content will appear here.")
        )
        .navigationTitle("Built-in Pack")
    }
}

/// Placeholder for the imports queue view
struct ImportsView: View {
    var body: some View {
        ContentUnavailableView(
            "Import Queue",
            systemImage: "square.and.arrow.down",
            description: Text("Drag files here to import them to your library.")
        )
        .navigationTitle("Imports")
    }
}

/// Library filter options for displaying subsets of items
enum LibraryFilter {
    case all
    case streams
    case youtube
    case audioURLs
}

/// Placeholder for the filtered library view
struct LibraryView: View {
    let filter: LibraryFilter
    
    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text("Your \(title.lowercased()) will appear here.")
        )
        .navigationTitle(title)
    }
    
    private var title: String {
        switch filter {
        case .all: return "All Items"
        case .streams: return "Streams"
        case .youtube: return "YouTube"
        case .audioURLs: return "Audio URLs"
        }
    }
    
    private var systemImage: String {
        switch filter {
        case .all: return "music.note.list"
        case .streams: return "antenna.radiowaves.left.and.right"
        case .youtube: return "play.rectangle"
        case .audioURLs: return "link"
        }
    }
}

/// Placeholder for individual playlist view
struct PlaylistView: View {
    let playlist: Playlist
    
    var body: some View {
        ContentUnavailableView(
            playlist.name,
            systemImage: "music.note.list",
            description: Text("\(playlist.itemCount) items")
        )
        .navigationTitle(playlist.name)
    }
}

#Preview {
    MainContentView()
        .environment(AppModel())
        .environment(LibraryStore())
}
