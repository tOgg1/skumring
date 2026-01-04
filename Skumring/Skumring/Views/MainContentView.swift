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
