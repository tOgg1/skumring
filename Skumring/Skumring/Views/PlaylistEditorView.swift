import SwiftUI

/// Editor view for managing playlist contents.
///
/// Displays a playlist with:
/// - Editable name header
/// - List of items with drag reorder support
/// - Empty state when playlist has no items
/// - Play All button in header
///
/// Usage:
/// ```swift
/// PlaylistEditorView(playlist: $playlist)
/// ```
struct PlaylistEditorView: View {
    @Binding var playlist: Playlist
    
    @Environment(LibraryStore.self) private var libraryStore
    @Environment(PlaybackController.self) private var playbackController
    
    /// Tracks whether the name field is being edited
    @State private var isEditingName: Bool = false
    @FocusState private var nameFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with name and controls
            playlistHeader
            
            Divider()
            
            // Content: either items or empty state
            if items.isEmpty {
                emptyStateView
            } else {
                itemListView
            }
        }
        .navigationTitle(playlist.name)
    }
    
    // MARK: - Computed Properties
    
    /// Resolved items from the playlist's item IDs
    private var items: [LibraryItem] {
        libraryStore.items(forPlaylist: playlist.id)
    }
    
    // MARK: - Header
    
    private var playlistHeader: some View {
        HStack(spacing: 12) {
            // Editable playlist name
            if isEditingName {
                TextField("Playlist Name", text: $playlist.name)
                    .textFieldStyle(.plain)
                    .font(.title2.bold())
                    .focused($nameFieldFocused)
                    .onSubmit {
                        finishEditingName()
                    }
            } else {
                Text(playlist.name)
                    .font(.title2.bold())
                    .onTapGesture {
                        startEditingName()
                    }
            }
            
            Spacer()
            
            // Item count
            Text("\(playlist.itemCount) items")
                .foregroundStyle(.secondary)
                .font(.subheadline)
            
            // Play All button
            Button {
                playAll()
            } label: {
                Label("Play All", systemImage: "play.fill")
            }
            .disabled(items.isEmpty)
        }
        .padding()
    }
    
    // MARK: - Item List
    
    private var itemListView: some View {
        List {
            ForEach(items) { item in
                PlaylistItemRow(item: item) {
                    removeItem(item.id)
                }
            }
            .onMove(perform: moveItems)
        }
        .listStyle(.inset)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Items", systemImage: "music.note.list")
        } description: {
            Text("Add items from your library to this playlist.")
        }
    }
    
    // MARK: - Actions
    
    private func startEditingName() {
        isEditingName = true
        nameFieldFocused = true
    }
    
    private func finishEditingName() {
        isEditingName = false
        nameFieldFocused = false
        // Name is already bound, so it saves automatically
    }
    
    private func playAll() {
        guard !items.isEmpty else { return }
        let itemsCopy = items
        let controller = playbackController
        Task { @MainActor in
            try? await controller.playQueue(items: itemsCopy, startingAt: 0)
        }
    }
    
    private func removeItem(_ itemID: UUID) {
        playlist.removeItem(itemID)
    }
    
    private func moveItems(from source: IndexSet, to destination: Int) {
        // Convert IndexSet to actual indices and move
        for sourceIndex in source.sorted().reversed() {
            playlist.moveItem(from: sourceIndex, to: destination)
        }
    }
}

// MARK: - Playlist Item Row

/// A row displaying a library item within a playlist.
///
/// Shows the item title, subtitle, and a remove button.
private struct PlaylistItemRow: View {
    let item: LibraryItem
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.body)
                
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Item type indicator
            Image(systemName: iconForKind(item.kind))
                .foregroundStyle(.secondary)
            
            // Remove button
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Remove from playlist")
        }
        .contentShape(Rectangle())
    }
    
    private func iconForKind(_ kind: LibraryItemKind) -> String {
        switch kind {
        case .stream: return "antenna.radiowaves.left.and.right"
        case .youtube: return "play.rectangle"
        case .audioURL: return "link"
        }
    }
}

#Preview("With Items") {
    let store = LibraryStore()
    let item1 = LibraryItem(
        kind: .stream,
        title: "Lofi Girl",
        subtitle: "24/7 beats to relax/study to",
        source: .fromURL(URL(string: "https://example.com/stream")!)
    )
    let item2 = LibraryItem(
        kind: .youtube,
        title: "Jazz Coffee Shop",
        source: .fromYouTube("abc123")
    )
    store.addItem(item1)
    store.addItem(item2)
    
    var playlist = Playlist(name: "Focus Music", itemIDs: [item1.id, item2.id])
    store.addPlaylist(playlist)
    
    return NavigationStack {
        PlaylistEditorView(playlist: .constant(playlist))
    }
    .environment(store)
    .environment(PlaybackController())
}

#Preview("Empty Playlist") {
    NavigationStack {
        PlaylistEditorView(playlist: .constant(Playlist(name: "New Playlist")))
    }
    .environment(LibraryStore())
    .environment(PlaybackController())
}
