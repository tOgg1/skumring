import SwiftUI

/// A list view for displaying library items.
///
/// Displays items in a standard macOS List with LibraryItemRow views.
/// Handles selection state and double-click to play.
struct LibraryListView: View {
    let items: [LibraryItem]
    @Binding var selection: Set<UUID>
    
    /// Called when an item is double-clicked to initiate playback
    var onPlay: ((LibraryItem) -> Void)?
    
    /// Called when the user selects Delete from context menu
    var onDelete: ((LibraryItem) -> Void)?
    
    /// Called when the user selects Play Next from context menu
    var onPlayNext: ((LibraryItem) -> Void)?
    
    /// Called when the user selects Add to Queue from context menu
    var onAddToQueue: ((LibraryItem) -> Void)?
    
    /// Called when the user selects a playlist from the Add to Playlist submenu
    var onAddToPlaylist: ((LibraryItem, Playlist) -> Void)?
    
    /// Available playlists for the Add to Playlist submenu
    var playlists: [Playlist] = []
    
    var body: some View {
        List(items, selection: $selection) { item in
            LibraryItemRow(
                item: item,
                onPlay: {
                    onPlay?(item)
                },
                onDelete: {
                    onDelete?(item)
                },
                onPlayNext: {
                    onPlayNext?(item)
                },
                onAddToQueue: {
                    onAddToQueue?(item)
                },
                onAddToPlaylist: { playlist in
                    onAddToPlaylist?(item, playlist)
                },
                playlists: playlists
            )
            .tag(item.id)
        }
        .listStyle(.inset)
    }
}

#Preview {
    LibraryListView(
        items: [
            LibraryItem(
                kind: .stream,
                title: "Lofi Hip Hop Radio",
                subtitle: "ChilledCow",
                source: .fromURL(URL(string: "https://example.com/stream")!),
                tags: ["focus", "lofi"]
            ),
            LibraryItem(
                kind: .youtube,
                title: "Study Music",
                subtitle: "Focus Channel",
                source: .fromYouTube("dQw4w9WgXcQ")
            ),
            LibraryItem(
                kind: .audioURL,
                title: "Rain Sounds",
                source: .fromURL(URL(string: "https://example.com/rain.mp3")!)
            )
        ],
        selection: .constant([])
    )
}
