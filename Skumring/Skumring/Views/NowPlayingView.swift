import SwiftUI

/// The dedicated Now Playing view that becomes the primary player interface.
///
/// This view takes over the main content area when playing and displays:
/// - Video player (for YouTube) or artwork (for audio)
/// - Track information (title, subtitle)
/// - Playback controls (play/pause, next/prev, seek bar, volume)
/// - Upcoming queue items
///
/// ## Layout
///
/// The view uses a vertical split:
/// - Top: Media player area (16:9 for YouTube, square for audio artwork)
/// - Bottom: Track info, controls, and queue
///
/// ## Behavior
///
/// - Auto-navigates here when playback starts
/// - Serves as the launching point for fullscreen mode
/// - Works with both YouTube and audio streams
struct NowPlayingView: View {
    @Environment(PlaybackController.self) private var playbackController
    @Environment(AppModel.self) private var appModel
    
    /// Cache for artwork images
    private let artworkCache = ArtworkCache()
    
    var body: some View {
        GeometryReader { geometry in
            if playbackController.currentItem != nil {
                // Active playback layout
                VStack(spacing: 0) {
                    // Media player area
                    mediaPlayerArea(geometry: geometry)
                    
                    // Track info (controls are in the bottom bar)
                    trackInfoSection
                    
                    // Queue section
                    queueSection
                }
            } else {
                // Empty state when nothing is playing
                emptyState
            }
        }
        .navigationTitle("Now Playing")
    }
    
    // MARK: - Media Player Area
    
    /// The main media display area - video for YouTube, artwork for audio
    @ViewBuilder
    private func mediaPlayerArea(geometry: GeometryProxy) -> some View {
        let isYouTube = playbackController.currentItem?.kind == .youtube
        let maxWidth = geometry.size.width
        
        // Calculate size: 16:9 for video, square for audio
        let height: CGFloat = isYouTube
            ? min(maxWidth * 9 / 16, geometry.size.height * 0.5)
            : min(maxWidth * 0.6, geometry.size.height * 0.45, 400)
        
        Group {
            if isYouTube {
                // YouTube video player
                YouTubePlayerContainerView(
                    player: playbackController.youtubePlayer,
                    title: nil, // We show title in the track info area instead
                    onClose: nil, // No close button - use stop instead
                    showTitleBar: false // Hide title bar - info shown below
                )
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(Color.black)
            } else {
                // Audio artwork display
                artworkDisplay(height: height)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    /// Artwork display for non-YouTube content
    @ViewBuilder
    private func artworkDisplay(height: CGFloat) -> some View {
        ZStack {
            // Background blur from artwork
            if let artworkURL = playbackController.currentItem?.artworkURL {
                CachedAsyncImage(url: artworkURL, cache: artworkCache) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: 50)
                            .opacity(0.5)
                    default:
                        Color.clear
                    }
                }
            }
            
            // Main artwork
            artworkView(size: height * 0.8)
        }
        .frame(height: height)
        .clipped()
    }
    
    /// The artwork image or placeholder
    @ViewBuilder
    private func artworkView(size: CGFloat) -> some View {
        if let artworkURL = playbackController.currentItem?.artworkURL {
            CachedAsyncImage(url: artworkURL, cache: artworkCache) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: size, height: size)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    artworkPlaceholder(size: size)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        } else {
            artworkPlaceholder(size: size)
        }
    }
    
    /// Placeholder when no artwork is available
    private func artworkPlaceholder(size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.quaternary)
            Image(systemName: iconForCurrentItem)
                .font(.system(size: size * 0.3))
                .foregroundStyle(.secondary)
        }
        .frame(width: size, height: size)
    }
    
    /// Icon based on current item kind
    private var iconForCurrentItem: String {
        switch playbackController.currentItem?.kind {
        case .stream:
            return "antenna.radiowaves.left.and.right"
        case .youtube:
            return "play.rectangle"
        case .audioURL:
            return "link"
        case .none:
            return "music.note"
        }
    }
    
    // MARK: - Track Info
    
    /// Track information display (controls are in the bottom NowPlayingBar)
    private var trackInfoSection: some View {
        VStack(spacing: 8) {
            if let item = playbackController.currentItem {
                Text(item.title)
                    .font(.title2.bold())
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                // Source badge with LIVE indicator for streams
                HStack(spacing: 8) {
                    if item.kind == .stream {
                        Text("LIVE")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.red, in: Capsule())
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: iconForCurrentItem)
                            .font(.caption)
                        Text(item.kind.rawValue.capitalized)
                            .font(.caption)
                    }
                    .foregroundStyle(.tertiary)
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
    }
    
    // MARK: - Queue Section
    
    /// The upcoming queue display
    private var queueSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Queue header
            HStack {
                Text("Up Next")
                    .font(.headline)
                
                if !playbackController.upcomingItems.isEmpty {
                    Text("(\(playbackController.upcomingItems.count))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Mode toggles
                HStack(spacing: 12) {
                    // Repeat toggle
                    Button {
                        cycleRepeatMode()
                    } label: {
                        Image(systemName: repeatIcon)
                            .foregroundStyle(playbackController.repeatMode == .off ? Color.secondary : Color.accentColor)
                    }
                    .buttonStyle(.plain)
                    .help(repeatHelpText)
                    
                    // Shuffle toggle
                    Button {
                        toggleShuffle()
                    } label: {
                        Image(systemName: "shuffle")
                            .foregroundStyle(playbackController.shuffleMode == .on ? Color.accentColor : Color.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(playbackController.shuffleMode == .on ? "Shuffle On" : "Shuffle Off")
                    
                    // Clear button
                    if !playbackController.upcomingItems.isEmpty {
                        Button {
                            playbackController.clearUpcoming()
                        } label: {
                            Text("Clear")
                                .font(.subheadline)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            Divider()
            
            // Queue list
            if playbackController.upcomingItems.isEmpty {
                queueEmptyState
            } else {
                queueList
            }
        }
        .frame(maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }
    
    /// Empty state for the queue
    private var queueEmptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "text.line.first.and.arrowtriangle.forward")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            
            Text("No upcoming items")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    /// The queue list of upcoming items
    private var queueList: some View {
        List {
            ForEach(Array(playbackController.upcomingItems.enumerated()), id: \.element.id) { offset, item in
                QueueRowView(
                    item: item,
                    isCurrentlyPlaying: false,
                    position: offset + 1,
                    onPlay: {
                        // Calculate actual queue index
                        if let currentIndex = playbackController.queueIndex {
                            let targetIndex = currentIndex + 1 + offset
                            Task {
                                try? await playbackController.jumpToQueueIndex(targetIndex)
                            }
                        }
                    },
                    onRemove: {
                        // Calculate actual queue index
                        if let currentIndex = playbackController.queueIndex {
                            let targetIndex = currentIndex + 1 + offset
                            playbackController.removeFromQueue(at: targetIndex)
                        }
                    }
                )
            }
            .onMove { source, destination in
                // Convert from upcoming indices to queue indices
                if let currentIndex = playbackController.queueIndex {
                    let baseIndex = currentIndex + 1
                    for sourceIndex in source {
                        let fromQueueIndex = baseIndex + sourceIndex
                        let toQueueIndex = baseIndex + destination
                        playbackController.moveInQueue(from: fromQueueIndex, to: toQueueIndex)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Repeat/Shuffle Helpers
    
    /// Icon for repeat mode
    private var repeatIcon: String {
        switch playbackController.repeatMode {
        case .off:
            return "repeat"
        case .one:
            return "repeat.1"
        case .all:
            return "repeat"
        }
    }
    
    /// Help text for repeat button
    private var repeatHelpText: String {
        switch playbackController.repeatMode {
        case .off:
            return "Repeat Off"
        case .one:
            return "Repeat One"
        case .all:
            return "Repeat All"
        }
    }
    
    /// Cycles through repeat modes: off -> all -> one -> off
    private func cycleRepeatMode() {
        switch playbackController.repeatMode {
        case .off:
            playbackController.repeatMode = .all
        case .all:
            playbackController.repeatMode = .one
        case .one:
            playbackController.repeatMode = .off
        }
    }
    
    /// Toggles shuffle mode
    private func toggleShuffle() {
        let newMode: ShuffleMode = playbackController.shuffleMode == .off ? .on : .off
        playbackController.setShuffleMode(newMode)
    }
    
    // MARK: - Empty State
    
    /// Displayed when nothing is playing
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "play.circle")
                .font(.system(size: 80))
                .foregroundStyle(.tertiary)
            
            Text("Nothing Playing")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Text("Select an item from your library to start listening")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Preview

#Preview("With YouTube") {
    let controller = PlaybackController()
    return NowPlayingView()
        .environment(controller)
        .environment(AppModel())
        .frame(width: 800, height: 600)
}

#Preview("Empty State") {
    NowPlayingView()
        .environment(PlaybackController())
        .environment(AppModel())
        .frame(width: 800, height: 600)
}
