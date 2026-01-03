import SwiftUI

/// Library filter options for displaying subsets of items.
enum LibraryFilter {
    case all
    case streams
    case youtube
    case audioURLs
}

/// View mode for displaying library items.
enum ViewMode: String, CaseIterable {
    case grid
    case list
    
    var icon: String {
        switch self {
        case .grid: return "square.grid.2x2"
        case .list: return "list.bullet"
        }
    }
}

/// Filtered library view that displays items based on the selected filter.
///
/// Takes a `LibraryFilter` parameter to show subsets of the library:
/// - `.all`: All library items
/// - `.streams`: Only stream items (internet radio, live streams)
/// - `.youtube`: Only YouTube video items
/// - `.audioURLs`: Only direct audio URL items
///
/// Supports toggling between grid and list view modes via the toolbar.
struct LibraryView: View {
    let filter: LibraryFilter
    
    @Environment(AppModel.self) private var appModel
    @Environment(LibraryStore.self) private var libraryStore
    @State private var viewMode: ViewMode = .grid
    @State private var selection: Set<UUID> = []
    @State private var searchText: String = ""
    
    /// ID of item to show delete confirmation for
    @State private var itemToDelete: UUID?
    
    var body: some View {
        Group {
            if filteredItems.isEmpty {
                emptyStateView
            } else {
                contentView
            }
        }
        .navigationTitle(title)
        .searchable(text: $searchText, prompt: "Search \(title.lowercased())")
        .toolbar {
            ToolbarItemGroup {
                viewModeToggle
            }
        }
        .alert("Delete Item?", isPresented: .init(
            get: { itemToDelete != nil },
            set: { if !$0 { itemToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                itemToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let id = itemToDelete {
                    deleteItem(id: id)
                }
            }
        } message: {
            if let id = itemToDelete,
               let item = libraryStore.item(withID: id) {
                Text("Are you sure you want to delete \"\(item.title)\"? This cannot be undone.")
            }
        }
    }
    
    // MARK: - Filtered Items
    
    /// Items filtered by the current filter and search text
    private var filteredItems: [LibraryItem] {
        let baseItems: [LibraryItem]
        
        switch filter {
        case .all:
            baseItems = libraryStore.items
        case .streams:
            baseItems = libraryStore.streams
        case .youtube:
            baseItems = libraryStore.youtubeItems
        case .audioURLs:
            baseItems = libraryStore.audioURLItems
        }
        
        // Apply search filter if text is not empty
        if searchText.isEmpty {
            return baseItems
        }
        
        let lowercasedSearch = searchText.lowercased()
        return baseItems.filter { item in
            item.title.lowercased().contains(lowercasedSearch) ||
            (item.subtitle?.lowercased().contains(lowercasedSearch) ?? false) ||
            item.tags.contains { $0.lowercased().contains(lowercasedSearch) }
        }
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        switch viewMode {
        case .grid:
            LibraryGridView(
                items: filteredItems,
                selection: $selection,
                onPlay: playItem,
                onDelete: requestDeleteConfirmation,
                onAddToPlaylist: addItemToPlaylist,
                playlists: libraryStore.playlists
            )
        case .list:
            LibraryListView(
                items: filteredItems,
                selection: $selection,
                onPlay: playItem,
                onDelete: requestDeleteConfirmation,
                onAddToPlaylist: addItemToPlaylist,
                playlists: libraryStore.playlists
            )
        }
    }
    
    // MARK: - View Mode Toggle
    
    private var viewModeToggle: some View {
        Picker("View Mode", selection: $viewMode) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                Image(systemName: mode.icon)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .help("Switch between grid and list view")
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label(emptyTitle, systemImage: systemImage)
        } description: {
            Text(emptyDescription)
        } actions: {
            VStack(spacing: 12) {
                if !searchText.isEmpty {
                    Button("Clear Search") {
                        searchText = ""
                    }
                }
                
                // Add Item CTA - shown in all filter empty states when not searching
                if searchText.isEmpty {
                    Button {
                        appModel.showAddItemSheet = true
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Text("or press \(Text("Cmd+L").fontWeight(.medium))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Title & Icons
    
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
    
    private var emptyTitle: String {
        if !searchText.isEmpty {
            return "No Results"
        }
        return "No \(title)"
    }
    
    private var emptyDescription: String {
        if !searchText.isEmpty {
            return "No items match '\(searchText)'"
        }
        switch filter {
        case .all:
            return "Add streams, YouTube videos, or audio URLs to get started."
        case .streams:
            return "Add internet radio stations or live streams."
        case .youtube:
            return "Add YouTube videos to your library."
        case .audioURLs:
            return "Add direct audio file URLs (mp3, aac, m4a)."
        }
    }
    
    // MARK: - Actions
    
    private func playItem(_ item: LibraryItem) {
        // TODO: Integrate with PlaybackController
        print("Play item: \(item.title)")
    }
    
    /// Shows the delete confirmation dialog for an item.
    private func requestDeleteConfirmation(_ item: LibraryItem) {
        itemToDelete = item.id
    }
    
    /// Deletes an item from the library after confirmation.
    private func deleteItem(id: UUID) {
        libraryStore.deleteItem(id: id)
        itemToDelete = nil
        // Clear selection if the deleted item was selected
        selection.remove(id)
    }
    
    /// Adds an item to a playlist.
    private func addItemToPlaylist(_ item: LibraryItem, _ playlist: Playlist) {
        guard var updatedPlaylist = libraryStore.playlist(withID: playlist.id) else {
            return
        }
        updatedPlaylist.addItem(item.id)
        libraryStore.updatePlaylist(updatedPlaylist)
    }
}

#Preview("All Items - Empty") {
    NavigationStack {
        LibraryView(filter: .all)
    }
    .environment(AppModel())
    .environment(LibraryStore())
}

#Preview("Streams Filter") {
    NavigationStack {
        LibraryView(filter: .streams)
    }
    .environment(AppModel())
    .environment(LibraryStore())
}
