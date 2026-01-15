import SwiftUI

/// The Home/Focus Now dashboard - the main entry point for the app.
///
/// HomeView provides quick access to start focusing with curated playlists,
/// recent items, and quick stations. It adapts its content based on whether
/// the user has items in their library or is a first-time user.
///
/// Key features:
/// - Time-of-day greeting
/// - Focus Now CTA button
/// - Featured playlists from built-in pack
/// - Quick stations for one-click playback
/// - First launch experience for new users
struct HomeView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(LibraryStore.self) private var libraryStore
    @Environment(PlaybackController.self) private var playbackController
    
    /// Artwork cache for images
    private let artworkCache = ArtworkCache()
    
    /// Loader for built-in pack content
    private let builtInPackLoader = BuiltInPackLoader()
    
    /// Items from the built-in pack
    @State private var builtInItems: [LibraryItem] = []
    
    /// Playlists from the built-in pack
    @State private var builtInPlaylists: [Playlist] = []
    
    /// Loading state for built-in pack
    @State private var isLoadingBuiltIn = true
    
    /// Error loading built-in pack
    @State private var loadError: Error?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Greeting and Focus Now CTA
                headerSection
                
                // Show appropriate content based on library state
                if isFirstLaunch {
                    firstLaunchSection
                } else {
                    // Featured playlists
                    if !builtInPlaylists.isEmpty {
                        featuredPlaylistsSection
                    }
                    
                    // Quick stations
                    if !streamItems.isEmpty {
                        quickStationsSection
                    }
                    
                    // Recent items from user library
                    if !recentUserItems.isEmpty {
                        recentItemsSection
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("Home")
        .task {
            await loadBuiltInContent()
        }
    }
    
    // MARK: - Computed Properties
    
    /// Whether this appears to be a first launch (empty library)
    private var isFirstLaunch: Bool {
        libraryStore.items.isEmpty && libraryStore.playlists.isEmpty
    }
    
    /// Stream items from built-in pack for quick stations
    private var streamItems: [LibraryItem] {
        builtInItems.filter { $0.kind == .stream }
    }
    
    /// Recent items from user library (most recently added first)
    private var recentUserItems: [LibraryItem] {
        Array(libraryStore.items.sorted { $0.addedAt > $1.addedAt }.prefix(6))
    }
    
    /// Time-based greeting
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<21:
            return "Good evening"
        default:
            return "Good night"
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(greeting)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Ready to focus?")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            // Focus Now CTA Button
            Button {
                Task {
                    await startFocusSession()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "play.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.brandTerracotta)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Focus Now")
                            .font(.headline)
                        Text("Start with curated ambient music")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(Color.brandCoralLight, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.brandCoral.opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .frame(maxWidth: 400)
        }
    }
    
    // MARK: - First Launch Section
    
    private var firstLaunchSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Welcome message with logo
            HStack(spacing: 16) {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                    .shadow(color: Color.brandTerracotta.opacity(0.3), radius: 8, y: 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to Skumring")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Your personal focus music player")
                        .foregroundStyle(.secondary)
                }
            }
            
            Text("Get started with our curated stations or add your own.")
                .foregroundStyle(.secondary)
            
            // Built-in pack highlight
            if !builtInItems.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Curated Stations", systemImage: "star.fill")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
                        ForEach(builtInItems.prefix(6)) { item in
                            QuickStationCard(
                                item: item,
                                artworkCache: artworkCache,
                                isPlaying: playbackController.currentItem?.id == item.id,
                                onPlay: { await playItem(item) }
                            )
                        }
                    }
                }
            }
            
            // Add your own hint
            VStack(alignment: .leading, spacing: 8) {
                Text("Add Your Own Stations")
                    .font(.headline)
                
                HStack {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(.tint)
                    Text("Press ")
                    Text("Cmd+L")
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                    Text(" to add a stream URL or YouTube video")
                }
                .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Featured Playlists Section
    
    private var featuredPlaylistsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured Playlists")
                .font(.title3)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(builtInPlaylists) { playlist in
                        PlaylistCard(
                            playlist: playlist,
                            items: itemsForPlaylist(playlist),
                            artworkCache: artworkCache,
                            onOpen: {
                                appModel.selectedSidebarItem = .builtInPlaylist(playlist.id)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Stations Section
    
    private var quickStationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Stations")
                .font(.title3)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 12) {
                ForEach(streamItems.prefix(6)) { item in
                    QuickStationCard(
                        item: item,
                        artworkCache: artworkCache,
                        isPlaying: playbackController.currentItem?.id == item.id,
                        onPlay: { await playItem(item) }
                    )
                }
            }
        }
    }
    
    // MARK: - Recent Items Section
    
    private var recentItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Recent Items")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("See All") {
                    appModel.selectedSidebarItem = .allItems
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 12) {
                ForEach(recentUserItems) { item in
                    QuickStationCard(
                        item: item,
                        artworkCache: artworkCache,
                        isPlaying: playbackController.currentItem?.id == item.id,
                        onPlay: { await playItem(item) }
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Loads built-in pack content
    private func loadBuiltInContent() async {
        isLoadingBuiltIn = true
        defer { isLoadingBuiltIn = false }
        
        do {
            let result = try await builtInPackLoader.loadAsync()
            builtInItems = result.pack.items
            builtInPlaylists = result.pack.playlists
        } catch {
            loadError = error
            print("Failed to load built-in pack: \(error.localizedDescription)")
        }
    }
    
    /// Gets LibraryItems for a playlist
    private func itemsForPlaylist(_ playlist: Playlist) -> [LibraryItem] {
        playlist.itemIDs.compactMap { id in
            builtInItems.first { $0.id == id }
        }
    }
    
    /// Starts a focus session with the default playlist
    private func startFocusSession() async {
        // Try to play the first built-in playlist, or first stream if no playlists
        if let firstPlaylist = builtInPlaylists.first {
            await playPlaylist(firstPlaylist)
        } else if let firstStream = streamItems.first {
            await playItem(firstStream)
        }
    }
    
    /// Plays a single item
    private func playItem(_ item: LibraryItem) async {
        do {
            try await playbackController.play(item: item)
        } catch {
            print("Failed to play item: \(error.localizedDescription)")
        }
    }
    
    /// Plays a playlist
    private func playPlaylist(_ playlist: Playlist) async {
        let items = itemsForPlaylist(playlist)
        guard !items.isEmpty else { return }
        
        do {
            try await playbackController.playQueue(items: items, startingAt: 0)
            playbackController.repeatMode = playlist.repeatMode
            playbackController.setShuffleMode(playlist.shuffleMode)
        } catch {
            print("Failed to play playlist: \(error.localizedDescription)")
        }
    }
}

// MARK: - Quick Station Card

/// A compact card for quick station playback
private struct QuickStationCard: View {
    let item: LibraryItem
    let artworkCache: ArtworkCache
    let isPlaying: Bool
    let onPlay: () async -> Void
    
    var body: some View {
        Button {
            Task {
                await onPlay()
            }
        } label: {
            HStack(spacing: 12) {
                // Artwork
                ZStack {
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
                                EmptyView()
                            }
                        }
                    } else {
                        placeholderView
                    }
                    
                    // Playing indicator
                    if isPlaying {
                        Circle()
                            .fill(.black.opacity(0.5))
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Title and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer(minLength: 0)
                
                // Play indicator
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isPlaying ? .green : .secondary)
            }
            .padding(12)
            .background(isPlaying ? Color.green.opacity(0.1) : Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
    
    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.quaternary)
            .overlay {
                Image(systemName: iconName)
                    .foregroundStyle(.secondary)
            }
    }
    
    private var iconName: String {
        switch item.kind {
        case .stream:
            return "antenna.radiowaves.left.and.right"
        case .youtube:
            return "play.rectangle"
        case .audioURL:
            return "link"
        }
    }
}

// MARK: - Playlist Card

/// A card for playlist display and playback
private struct PlaylistCard: View {
    let playlist: Playlist
    let items: [LibraryItem]
    let artworkCache: ArtworkCache
    let onOpen: () -> Void
    
    /// Get first item's artwork for the card
    private var coverArtworkURL: URL? {
        items.first?.artworkURL
    }
    
    var body: some View {
        Button {
            onOpen()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Artwork grid or placeholder
                ZStack {
                    if let artworkURL = coverArtworkURL {
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
                                EmptyView()
                            }
                        }
                    } else {
                        placeholderView
                    }
                }
                .frame(width: 160, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Playlist info
                VStack(alignment: .leading, spacing: 2) {
                    Text(playlist.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text("\(playlist.itemCount) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 160)
        }
        .buttonStyle(.plain)
    }
    
    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.quaternary)
            .overlay {
                Image(systemName: "music.note.list")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
    }
}

#Preview {
    HomeView()
        .environment(AppModel())
        .environment(LibraryStore())
        .environment(PlaybackController())
}
