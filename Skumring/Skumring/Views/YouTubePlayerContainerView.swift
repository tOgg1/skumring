import SwiftUI

/// A container view that wraps YouTubePlayerView with a title bar, close button,
/// and sizing constraints for integration into the main window layout.
///
/// This view provides the chrome around the YouTube player, including:
/// - A semi-transparent title bar with video title and close button
/// - Minimum size constraints (200x200)
/// - Error state display
///
/// Usage:
/// ```swift
/// YouTubePlayerContainerView(
///     player: youtubePlayer,
///     title: "Video Title",
///     onClose: { hidePlayer = true }
/// )
/// ```
struct YouTubePlayerContainerView: View {
    /// The YouTube player model that controls playback
    let player: YouTubePlayer
    
    /// The title to display in the title bar (typically the video title)
    let title: String?
    
    /// Callback invoked when the close button is pressed
    var onClose: (() -> Void)?
    
    /// Whether to show the title bar overlay
    var showTitleBar: Bool = true
    
    /// Controls title bar visibility on hover
    @State private var isHovering = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // YouTube player content
            if !player.videoID.isEmpty {
                YouTubePlayerView(player: player)
            } else {
                // Placeholder when no video is loaded
                Color.black
                    .overlay {
                        Text("No video loaded")
                            .foregroundStyle(.secondary)
                    }
            }
            
            // Error overlay
            if let error = player.errorMessage {
                errorOverlay(message: error)
            }
            
            // Title bar overlay (visible on hover or when paused)
            if showTitleBar && (isHovering || player.playerState == .paused) {
                titleBar
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(minWidth: 200, minHeight: 200)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
    
    // MARK: - Title Bar
    
    @ViewBuilder
    private var titleBar: some View {
        HStack(spacing: 12) {
            // Video title
            if let title = title, !title.isEmpty {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            // Close button
            if let onClose = onClose {
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
                .help("Close player")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            LinearGradient(
                colors: [.black.opacity(0.7), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    // MARK: - Error Overlay
    
    @ViewBuilder
    private func errorOverlay(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.yellow)
            
            Text("Playback Error")
                .font(.headline)
                .foregroundStyle(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.8))
    }
}

#Preview {
    YouTubePlayerContainerView(
        player: YouTubePlayer(videoID: "dQw4w9WgXcQ"),
        title: "Sample Video Title",
        onClose: { print("Close pressed") }
    )
    .frame(width: 640, height: 360)
}
