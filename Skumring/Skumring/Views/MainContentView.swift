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
            
        case .nowPlaying:
            NowPlayingView()
            
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
            
        case .builtInItem(let itemID):
            BuiltInItemDetailView(itemID: itemID)
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

/// View for displaying playlist contents with playable items.
///
/// Shows playlist items in a list with:
/// - Playlist name and item count header
/// - Play All button
/// - List of items with thumbnails and titles
/// - Visual indication of currently playing item
/// - Context menu for each item (Play, Play Next, Add to Queue)
struct PlaylistView: View {
    let playlist: Playlist
    
    @Environment(LibraryStore.self) private var libraryStore
    @Environment(PlaybackController.self) private var playbackController
    
    /// Artwork cache for item thumbnails
    private let artworkCache = ArtworkCache()
    
    var body: some View {
        Group {
            if items.isEmpty {
                emptyStateView
            } else {
                contentView
            }
        }
        .navigationTitle(playlist.name)
    }
    
    // MARK: - Computed Properties
    
    /// Resolved items from the playlist's item IDs
    private var items: [LibraryItem] {
        libraryStore.items(forPlaylist: playlist.id)
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        VStack(spacing: 0) {
            // Header with playlist info and Play All button
            playlistHeader
            
            Divider()
            
            // List of items
            List {
                ForEach(items) { item in
                    PlaylistContentRow(
                        item: item,
                        isPlaying: playbackController.currentItem?.id == item.id,
                        artworkCache: artworkCache,
                        onPlay: { playItem(item) },
                        onPlayNext: { playNextItem(item) },
                        onAddToQueue: { addToQueue(item) }
                    )
                }
            }
            .listStyle(.inset)
        }
    }
    
    // MARK: - Header
    
    private var playlistHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.title2.bold())
                
                Text("\(playlist.itemCount) items")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Play All button
            Button {
                playAll()
            } label: {
                Label("Play All", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(items.isEmpty)
        }
        .padding()
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("Empty Playlist", systemImage: "music.note.list")
        } description: {
            Text("Add items from your library to this playlist.")
        }
    }
    
    // MARK: - Actions
    
    private func playItem(_ item: LibraryItem) {
        Task {
            try? await playbackController.play(item: item)
        }
    }
    
    private func playNextItem(_ item: LibraryItem) {
        Task {
            try? await playbackController.playNext(item)
        }
    }
    
    private func addToQueue(_ item: LibraryItem) {
        Task {
            try? await playbackController.addToQueue(item)
        }
    }
    
    private func playAll() {
        guard !items.isEmpty else { return }
        Task {
            try? await playbackController.playQueue(items: items, startingAt: 0)
        }
    }
}

// MARK: - Playlist Content Row

/// A row displaying a library item within the playlist content view.
///
/// Shows item thumbnail, title, subtitle, type indicator, and currently playing indicator.
private struct PlaylistContentRow: View {
    let item: LibraryItem
    let isPlaying: Bool
    let artworkCache: ArtworkCache
    let onPlay: () -> Void
    let onPlayNext: () -> Void
    let onAddToQueue: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            thumbnailView
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            // Title and subtitle
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.title)
                        .font(.body)
                        .lineLimit(1)
                    
                    // Playing indicator
                    if isPlaying {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.caption)
                            .foregroundStyle(Color.accentColor)
                    }
                }
                
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Item type indicator
            Image(systemName: iconForKind(item.kind))
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onPlay()
        }
        .contextMenu {
            Button {
                onPlay()
            } label: {
                Label("Play", systemImage: "play.fill")
            }
            
            Button {
                onPlayNext()
            } label: {
                Label("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward")
            }
            
            Button {
                onAddToQueue()
            } label: {
                Label("Add to Queue", systemImage: "text.badge.plus")
            }
        }
    }
    
    // MARK: - Thumbnail
    
    @ViewBuilder
    private var thumbnailView: some View {
        if let artworkURL = item.artworkURL {
            CachedAsyncImage(url: artworkURL, cache: artworkCache) { phase in
                switch phase {
                case .empty:
                    placeholderView
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholderView
                @unknown default:
                    placeholderView
                }
            }
        } else {
            placeholderView
        }
    }
    
    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(.quaternary)
            .overlay {
                Image(systemName: iconForKind(item.kind))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
    }
    
    private func iconForKind(_ kind: LibraryItemKind) -> String {
        switch kind {
        case .stream: return "antenna.radiowaves.left.and.right"
        case .youtube: return "play.rectangle"
        case .audioURL: return "link"
        }
    }
}

/// View for a built-in pack item (from sidebar selection)
struct BuiltInItemDetailView: View {
    let itemID: UUID
    
    /// The built-in pack loader to find the item
    private let builtInPackLoader = BuiltInPackLoader()
    
    /// Artwork cache for images
    private let artworkCache = ArtworkCache()
    
    @Environment(PlaybackController.self) private var playbackController
    
    @State private var item: LibraryItem?
    @State private var loadError: Error?
    
    var body: some View {
        Group {
            if let item = item {
                // Show item details with play button
                VStack(spacing: 16) {
                    if let artworkURL = item.artworkURL {
                        CachedAsyncImage(url: artworkURL, cache: artworkCache) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 300, height: 300)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            case .failure:
                                placeholderView(for: item.kind)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(maxWidth: 300, maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        placeholderView(for: item.kind)
                            .frame(width: 300, height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Text(item.title)
                        .font(.title)
                    
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("curated")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.quaternary, in: Capsule())
                    }
                    
                    // Play button
                    Button {
                        Task {
                            try? await playbackController.play(item: item)
                        }
                    } label: {
                        Label("Play", systemImage: "play.fill")
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding()
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    Task {
                        try? await playbackController.play(item: item)
                    }
                }
                .contextMenu {
                    Button {
                        Task {
                            try? await playbackController.play(item: item)
                        }
                    } label: {
                        Label("Play", systemImage: "play.fill")
                    }
                    
                    Button {
                        Task {
                            try? await playbackController.playNext(item)
                        }
                    } label: {
                        Label("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward")
                    }
                    
                    Button {
                        Task {
                            try? await playbackController.addToQueue(item)
                        }
                    } label: {
                        Label("Add to Queue", systemImage: "text.badge.plus")
                    }
                }
                .navigationTitle(item.title)
            } else if loadError != nil {
                ContentUnavailableView(
                    "Item Not Found",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This curated item could not be loaded.")
                )
            } else {
                ProgressView("Loading...")
            }
        }
        .task {
            await loadItem()
        }
    }
    
    @ViewBuilder
    private func placeholderView(for kind: LibraryItemKind) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.quaternary)
            .overlay {
                Image(systemName: iconName(for: kind))
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
    }
    
    private func loadItem() async {
        do {
            let items = try await builtInPackLoader.loadItemsAsync()
            item = items.first { $0.id == itemID }
            if item == nil {
                loadError = NSError(domain: "BuiltInItemDetailView", code: 404, userInfo: nil)
            }
        } catch {
            loadError = error
        }
    }
    
    private func iconName(for kind: LibraryItemKind) -> String {
        switch kind {
        case .stream:
            return "antenna.radiowaves.left.and.right"
        case .youtube:
            return "play.rectangle"
        case .audioURL:
            return "link"
        }
    }
}

#Preview {
    MainContentView()
        .environment(AppModel())
        .environment(LibraryStore())
        .environment(PlaybackController())
}
