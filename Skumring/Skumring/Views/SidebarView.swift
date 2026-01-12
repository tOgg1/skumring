import SwiftUI

/// The main sidebar navigation view for the app.
///
/// Displays a hierarchical list of navigation destinations organized into sections:
/// - Home: Quick access to main view
/// - Built-in Pack: Curated content
/// - Library: All items, filtered by type
/// - Playlists: User-created playlists
struct SidebarView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(LibraryStore.self) private var libraryStore
    @Environment(PlaybackController.self) private var playbackController
    
    /// ID of playlist currently being renamed (nil if not in rename mode)
    @State private var renamingPlaylistID: UUID?
    
    /// Text for the rename text field
    @State private var renameText: String = ""
    
    /// ID of playlist to show delete confirmation for
    @State private var playlistToDelete: UUID?
    
    /// Items loaded from the built-in pack
    @State private var builtInItems: [LibraryItem] = []
    
    /// Loader for built-in pack content
    private let builtInPackLoader = BuiltInPackLoader()
    
    var body: some View {
        @Bindable var appModel = appModel
        
        List(selection: $appModel.selectedSidebarItem) {
            // MARK: - Home Section
            Section("Home") {
                Label("Focus Now", systemImage: "house")
                    .tag(SidebarItem.home)
                
                // Now Playing item - highlighted when playing
                nowPlayingRow
            }
            
            // MARK: - Built-in Pack Section
            Section("Built-in Pack") {
                Label("All Curated", systemImage: "star")
                    .tag(SidebarItem.builtInPack)
                
                ForEach(builtInItems) { item in
                    builtInItemRow(for: item)
                }
            }
            
            // MARK: - Library Section
            Section("Library") {
                Label("All Items", systemImage: "music.note.list")
                    .tag(SidebarItem.allItems)
                
                Label("Streams", systemImage: "antenna.radiowaves.left.and.right")
                    .tag(SidebarItem.streams)
                
                Label("YouTube", systemImage: "play.rectangle")
                    .tag(SidebarItem.youtube)
                
                Label("Audio URLs", systemImage: "link")
                    .tag(SidebarItem.audioURLs)
                
                Label("Imports", systemImage: "square.and.arrow.down")
                    .tag(SidebarItem.imports)
            }
            
            // MARK: - Playlists Section
            Section("Playlists") {
                ForEach(libraryStore.playlists) { playlist in
                    playlistRow(for: playlist)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Skumring")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)
            }
        }
        .safeAreaInset(edge: .bottom) {
            sidebarFooter
        }
        .task {
            await loadBuiltInItems()
        }
        .alert("Delete Playlist?", isPresented: .init(
            get: { playlistToDelete != nil },
            set: { if !$0 { playlistToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                playlistToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let id = playlistToDelete {
                    deletePlaylist(id: id)
                }
            }
        } message: {
            if let id = playlistToDelete,
               let playlist = libraryStore.playlist(withID: id) {
                Text("Are you sure you want to delete \"\(playlist.name)\"? Items in this playlist will not be removed from your library.")
            }
        }
    }
    
    // MARK: - Now Playing Row
    
    /// Row showing "Now Playing" in the sidebar, highlighted when something is playing
    @ViewBuilder
    private var nowPlayingRow: some View {
        // Access PlaybackController from environment
        // Note: We need to add this to the environment reader
        Label {
            HStack(spacing: 4) {
                Text("Now Playing")
                
                // Playing indicator when active
                if hasActivePlayback {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 6, height: 6)
                }
            }
        } icon: {
            Image(systemName: hasActivePlayback ? "speaker.wave.2.fill" : "play.circle")
                .foregroundStyle(hasActivePlayback ? Color.accentColor : .primary)
        }
        .tag(SidebarItem.nowPlaying)
    }
    
    /// Whether there is active playback
    private var hasActivePlayback: Bool {
        playbackController.currentItem != nil
    }
    
    // MARK: - Built-in Item Row
    
    @ViewBuilder
    private func builtInItemRow(for item: LibraryItem) -> some View {
        Label {
            HStack(spacing: 4) {
                Text(item.title)
                
                // Curated badge
                Text("curated")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }
        } icon: {
            itemIcon(for: item)
        }
        .tag(SidebarItem.builtInItem(item.id))
        // No context menu - built-in items cannot be deleted
    }
    
    /// Returns the appropriate icon for a built-in item based on its kind
    @ViewBuilder
    private func itemIcon(for item: LibraryItem) -> some View {
        switch item.kind {
        case .stream:
            Image(systemName: "antenna.radiowaves.left.and.right")
        case .youtube:
            Image(systemName: "play.rectangle")
        case .audioURL:
            Image(systemName: "link")
        }
    }
    
    // MARK: - Playlist Row
    
    @ViewBuilder
    private func playlistRow(for playlist: Playlist) -> some View {
        if renamingPlaylistID == playlist.id {
            // Inline rename mode
            TextField("Playlist name", text: $renameText)
                .textFieldStyle(.plain)
                .onSubmit {
                    commitRename(for: playlist.id)
                }
                .onExitCommand {
                    cancelRename()
                }
                .onAppear {
                    renameText = playlist.name
                }
        } else {
            Label(playlist.name, systemImage: "music.note.list")
                .tag(SidebarItem.playlist(playlist.id))
                .contextMenu {
                    playlistContextMenu(for: playlist)
                }
        }
    }
    
    // MARK: - Playlist Context Menu
    
    @ViewBuilder
    private func playlistContextMenu(for playlist: Playlist) -> some View {
        Button {
            startRename(playlist: playlist)
        } label: {
            Label("Rename", systemImage: "pencil")
        }
        
        Button {
            duplicatePlaylist(playlist)
        } label: {
            Label("Duplicate", systemImage: "plus.square.on.square")
        }
        
        Button {
            exportPlaylist(playlist)
        } label: {
            Label("Export...", systemImage: "square.and.arrow.up")
        }
        
        Divider()
        
        Button(role: .destructive) {
            playlistToDelete = playlist.id
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    // MARK: - Rename Actions
    
    private func startRename(playlist: Playlist) {
        renameText = playlist.name
        renamingPlaylistID = playlist.id
    }
    
    private func commitRename(for playlistID: UUID) {
        guard !renameText.trimmingCharacters(in: .whitespaces).isEmpty else {
            cancelRename()
            return
        }
        
        if var playlist = libraryStore.playlist(withID: playlistID) {
            playlist.name = renameText.trimmingCharacters(in: .whitespaces)
            libraryStore.updatePlaylist(playlist)
        }
        renamingPlaylistID = nil
    }
    
    private func cancelRename() {
        renamingPlaylistID = nil
        renameText = ""
    }
    
    // MARK: - Playlist Actions
    
    private func duplicatePlaylist(_ playlist: Playlist) {
        let duplicated = Playlist(
            name: "\(playlist.name) Copy",
            itemIDs: playlist.itemIDs,
            repeatMode: playlist.repeatMode,
            shuffleMode: playlist.shuffleMode
        )
        libraryStore.addPlaylist(duplicated)
    }
    
    private func exportPlaylist(_ playlist: Playlist) {
        // TODO: Implement export functionality
        // This will be handled by ImportExportService in a future task
    }
    
    private func deletePlaylist(id: UUID) {
        // If we're deleting the currently selected playlist, navigate away
        if case .playlist(let selectedID) = appModel.selectedSidebarItem,
           selectedID == id {
            appModel.selectedSidebarItem = .allItems
        }
        libraryStore.deletePlaylist(id: id)
        playlistToDelete = nil
    }
    
    // MARK: - Sidebar Footer
    
    /// Footer view with Add Playlist button.
    ///
    /// Uses Liquid Glass styling for a modern, translucent appearance that
    /// matches the system aesthetic on macOS 26+. The glass effect automatically
    /// falls back to solid styling when Reduce Transparency is enabled.
    private var sidebarFooter: some View {
        HStack {
            Button(action: addPlaylist) {
                Label("New Playlist", systemImage: "plus")
            }
            .buttonStyle(.borderless)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .glassStyleFullBleed()
    }
    
    /// Creates a new playlist with a default name
    private func addPlaylist() {
        let playlistNumber = libraryStore.playlists.count + 1
        let newPlaylist = Playlist(name: "Playlist \(playlistNumber)")
        libraryStore.addPlaylist(newPlaylist)
        
        // Select the newly created playlist
        appModel.selectedSidebarItem = .playlist(newPlaylist.id)
    }
    
    // MARK: - Built-in Pack Loading
    
    /// Loads items from the built-in pack asynchronously
    private func loadBuiltInItems() async {
        do {
            builtInItems = try await builtInPackLoader.loadItemsAsync()
        } catch {
            // If loading fails, items remain empty. User can still use "All Curated" to see
            // the full built-in pack view which has its own error handling.
            print("Failed to load built-in items for sidebar: \(error.localizedDescription)")
        }
    }
}

#Preview {
    SidebarView()
        .environment(AppModel())
        .environment(LibraryStore())
        .environment(PlaybackController())
}
