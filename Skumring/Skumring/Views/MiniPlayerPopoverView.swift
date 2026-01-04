import SwiftUI

/// A compact mini-player view displayed in the menu bar popover.
///
/// The MiniPlayerPopoverView provides a condensed version of the Now Playing
/// controls for quick access from the menu bar, including:
/// - Artwork thumbnail
/// - Track title and subtitle
/// - Transport controls (previous, play/pause, next)
/// - Volume slider
/// - Button to open the main Skumring window
///
/// Layout:
/// ```
/// +--------------------------------+
/// |  [Art]  Title                  |
/// |         Subtitle               |
/// |                                |
/// |     [<]  [>||]  [>]            |
/// |                                |
/// |  [Vol Slider-------------]     |
/// |                                |
/// |     [Open Skumring]            |
/// +--------------------------------+
/// ```
struct MiniPlayerPopoverView: View {
    @Environment(PlaybackController.self) private var playbackController
    @Environment(LibraryStore.self) private var libraryStore
    
    /// Artwork thumbnail size
    private let artworkSize: CGFloat = 48
    
    var body: some View {
        VStack(spacing: 12) {
            // Track info section
            trackInfoSection
            
            // Transport controls
            transportControls
            
            // Volume slider
            volumeSlider
            
            // Open main window button
            openButton
        }
        .padding(16)
        .frame(width: 280)
    }
    
    // MARK: - Track Info Section
    
    private var trackInfoSection: some View {
        HStack(spacing: 12) {
            // Artwork
            artworkView
            
            // Title and subtitle
            VStack(alignment: .leading, spacing: 2) {
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
                    
                    Text("Select something to play")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer(minLength: 0)
        }
    }
    
    // MARK: - Artwork View
    
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
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    private var artworkPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(.quaternary)
            Image(systemName: "music.note")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Transport Controls
    
    private var transportControls: some View {
        HStack(spacing: 24) {
            // Previous button
            let controller = playbackController
            Button {
                Task {
                    try? await controller.previous()
                }
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .disabled(controller.currentItem == nil)
            
            // Play/Pause button
            Button {
                controller.togglePlayPause()
            } label: {
                Image(systemName: playPauseIcon)
                    .font(.largeTitle)
                    .foregroundStyle(.primary)
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
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .disabled(controller.currentItem == nil)
        }
        .padding(.vertical, 4)
    }
    
    private var playPauseIcon: String {
        switch playbackController.state {
        case .playing:
            return "pause.circle.fill"
        case .loading, .reconnecting:
            return "circle.dotted"
        default:
            return "play.circle.fill"
        }
    }
    
    // MARK: - Volume Slider
    
    @MainActor
    private var volumeSlider: some View {
        HStack(spacing: 8) {
            Image(systemName: volumeIcon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)
            
            Slider(
                value: Binding(
                    get: { Double(playbackController.volume) },
                    set: { playbackController.setVolume(Float($0)) }
                ),
                in: 0...1
            )
        }
    }
    
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
    
    // MARK: - Open Button
    
    private var openButton: some View {
        Button {
            openMainWindow()
        } label: {
            Text("Open Skumring")
                .font(.subheadline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
    
    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        
        // Find and bring the main window to front
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue != "fullscreen-player" }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
}

#Preview("With Item Playing") {
    let controller = PlaybackController()
    let store = LibraryStore()
    return MiniPlayerPopoverView()
        .environment(controller)
        .environment(store)
}

#Preview("Nothing Playing") {
    let controller = PlaybackController()
    let store = LibraryStore()
    return MiniPlayerPopoverView()
        .environment(controller)
        .environment(store)
}
