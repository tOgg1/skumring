import SwiftUI

/// A persistent bar at the bottom of the main window showing current playback.
///
/// The NowPlayingBar displays:
/// - Artwork thumbnail (left)
/// - Track info (title/subtitle)
/// - Transport controls (previous, play/pause, next)
/// - Progress bar with time display
/// - Volume slider
/// - Repeat/shuffle toggles
///
/// Layout:
/// ```
/// +----------------------------------------------------------+
/// |  [Art]  Title           [<] [>||] [>]  [====]  [Vol] [R][S]
/// |         Subtitle                        0:00 / 3:45
/// +----------------------------------------------------------+
/// ```
///
/// ## Liquid Glass
///
/// On macOS 26+, the bar uses Apple's Liquid Glass effect for a modern,
/// translucent appearance. On older systems, it falls back to `.ultraThinMaterial`.
/// The bar also respects accessibility settings (Reduce Transparency).
struct NowPlayingBar: View {
    @Environment(PlaybackController.self) private var playbackController
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    
    /// Standard height for the now playing bar
    private let barHeight: CGFloat = 72
    
    /// Artwork thumbnail size
    private let artworkSize: CGFloat = 56
    
    /// Controls visibility of the queue popover
    @State private var showQueuePopover: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Left section: Artwork
            artworkView
            
            // Track info section
            trackInfoView
            
            Spacer()
            
            // Center section: Transport controls with progress
            transportControlsView
            
            Spacer()
            
            // Right section: Volume and toggles
            rightControlsView
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(height: barHeight)
        .background(barBackground)
    }
    
    // MARK: - Bar Background
    
    /// Background view that uses Liquid Glass on macOS 26+ with accessibility fallback.
    @ViewBuilder
    private var barBackground: some View {
        if reduceTransparency {
            // Accessibility: solid background when Reduce Transparency is enabled
            Color(nsColor: .windowBackgroundColor)
        } else {
            // Liquid Glass effect (macOS 26+)
            // The glassEffect modifier creates a translucent, frosted glass appearance
            // that morphs with the content behind it.
            Rectangle()
                .fill(.clear)
                .glassEffect()
        }
    }
    
    // MARK: - Artwork View
    
    /// 56x56 artwork thumbnail with placeholder
    private var artworkView: some View {
        Group {
            if let artworkURL = playbackController.currentItem?.artworkURL {
                AsyncImage(url: artworkURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        artworkPlaceholder
                    case .empty:
                        ProgressView()
                            .frame(width: artworkSize, height: artworkSize)
                    @unknown default:
                        artworkPlaceholder
                    }
                }
            } else {
                artworkPlaceholder
            }
        }
        .frame(width: artworkSize, height: artworkSize)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    /// Placeholder shown when no artwork is available
    private var artworkPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
            Image(systemName: "music.note")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Track Info View
    
    /// Title and subtitle with truncation, plus reconnection/error status
    private var trackInfoView: some View {
        VStack(alignment: .leading, spacing: 2) {
            switch playbackController.state {
            case .reconnecting(let attempt, let maxAttempts):
                // Show reconnecting status
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Reconnecting...")
                        .font(.headline)
                        .foregroundStyle(.orange)
                }
                Text("Attempt \(attempt) of \(maxAttempts)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
            case .error(let message):
                // Show error with retry button
                Text("Connection Lost")
                    .font(.headline)
                    .foregroundStyle(.red)
                
                if let item = playbackController.currentItem {
                    Button {
                        Task {
                            try? await playbackController.play(item: item)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                            Text("Retry")
                        }
                        .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                } else {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
            default:
                // Normal playback info
                if let item = playbackController.currentItem {
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                } else {
                    Text("Not Playing")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(minWidth: 120, maxWidth: 200, alignment: .leading)
    }
    
    // MARK: - Transport Controls
    
    /// Previous, play/pause, next buttons with progress bar
    private var transportControlsView: some View {
        VStack(spacing: 4) {
            // Transport buttons
            HStack(spacing: 20) {
                // Previous button
                let controller = playbackController
                Button {
                    Task {
                        try? await controller.previous()
                    }
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .disabled(controller.currentItem == nil)
                
                // Play/Pause button
                Button {
                    controller.togglePlayPause()
                } label: {
                    Image(systemName: playPauseIcon)
                        .font(.title)
                }
                .buttonStyle(.plain)
                .disabled(controller.currentItem == nil)
                
                // Next button
                Button {
                    Task {
                        try? await controller.next()
                    }
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .disabled(controller.currentItem == nil)
            }
            
            // Progress bar
            progressView
        }
    }
    
    /// Icon for play/pause button based on current state
    private var playPauseIcon: String {
        switch playbackController.state {
        case .playing:
            return "pause.fill"
        case .loading, .reconnecting:
            return "circle.dotted"
        default:
            return "play.fill"
        }
    }
    
    // MARK: - Progress View
    
    /// Progress bar with time display or LIVE badge
    private var progressView: some View {
        HStack(spacing: 8) {
            if let duration = playbackController.duration, duration > 0 {
                // Finite duration - show progress bar
                let currentTime = playbackController.currentTime ?? 0
                let progress = duration > 0 ? currentTime / duration : 0
                
                Text(formatTime(currentTime))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .frame(width: 45, alignment: .trailing)
                
                ProgressView(value: progress)
                    .frame(width: 150)
                    .onTapGesture { location in
                        // Seek on tap
                        let fraction = location.x / 150
                        playbackController.seek(to: duration * fraction)
                    }
                
                Text(formatTime(duration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .frame(width: 45, alignment: .leading)
            } else if playbackController.currentItem != nil {
                // Live stream - show LIVE badge
                Text("LIVE")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.red, in: Capsule())
            } else {
                // Nothing playing - show placeholder
                Text("--:-- / --:--")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .frame(height: 20)
    }
    
    /// Formats seconds as M:SS or H:MM:SS
    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
    
    // MARK: - Right Controls
    
    /// Volume slider, queue button, and repeat/shuffle toggles
    private var rightControlsView: some View {
        HStack(spacing: 16) {
            // Volume control
            volumeView
            
            // Queue button
            queueButtonView
            
            // Repeat/Shuffle toggles
            modeTogglesView
        }
    }
    
    // MARK: - Queue Button
    
    /// Button to show the queue popover
    private var queueButtonView: some View {
        Button {
            showQueuePopover.toggle()
        } label: {
            Image(systemName: "list.bullet")
                .font(.body)
                .foregroundStyle(hasUpcomingItems ? Color.accentColor : .secondary)
        }
        .buttonStyle(.plain)
        .help("Show Queue")
        .popover(isPresented: $showQueuePopover, arrowEdge: .top) {
            QueueView()
        }
    }
    
    /// Whether there are items upcoming in the queue
    private var hasUpcomingItems: Bool {
        !playbackController.upcomingItems.isEmpty
    }
    
    /// Volume slider with speaker icon
    @MainActor
    private var volumeView: some View {
        HStack(spacing: 8) {
            Image(systemName: volumeIcon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            Slider(
                value: Binding(
                    get: { Double(playbackController.volume) },
                    set: { playbackController.setVolume(Float($0)) }
                ),
                in: 0...1
            )
            .frame(width: 80)
        }
    }
    
    /// Icon for volume based on level
    private var volumeIcon: String {
        let vol = playbackController.volume
        if vol == 0 {
            return "speaker.slash.fill"
        } else if vol < 0.33 {
            return "speaker.wave.1.fill"
        } else if vol < 0.66 {
            return "speaker.wave.2.fill"
        } else {
            return "speaker.wave.3.fill"
        }
    }
    
    /// Repeat and shuffle toggle buttons
    @MainActor
    private var modeTogglesView: some View {
        HStack(spacing: 8) {
            // Repeat toggle - cycles through modes
            Button {
                cycleRepeatMode()
            } label: {
                Image(systemName: repeatIcon)
                    .font(.body)
                    .foregroundStyle(repeatColor)
            }
            .buttonStyle(.plain)
            .help(repeatHelpText)
            
            // Shuffle toggle
            Button {
                toggleShuffle()
            } label: {
                Image(systemName: "shuffle")
                    .font(.body)
                    .foregroundStyle(playbackController.shuffleMode == .on ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .help(playbackController.shuffleMode == .on ? "Shuffle On" : "Shuffle Off")
        }
    }
    
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
    
    /// Color for repeat icon
    private var repeatColor: Color {
        playbackController.repeatMode == .off ? .secondary : .accentColor
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
}

#Preview("With Item") {
    let controller = PlaybackController()
    return NowPlayingBar()
        .environment(controller)
}

#Preview("Empty State") {
    NowPlayingBar()
        .environment(PlaybackController())
}
