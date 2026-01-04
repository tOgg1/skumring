import SwiftUI
import AppKit

/// A fullscreen view for the YouTube player.
///
/// This view presents the YouTube player in a borderless fullscreen window
/// with minimal controls that appear on hover.
///
/// ## Keyboard Controls
/// - Escape: Exit fullscreen
/// - F: Toggle fullscreen
/// - Space: Play/Pause
///
/// ## Mouse Controls
/// - Hover: Show controls overlay
/// - Double-click: Exit fullscreen
struct FullscreenPlayerView: View {
    @Environment(PlaybackController.self) private var playbackController
    @Environment(AppModel.self) private var appModel
    
    /// Controls overlay visibility on hover
    @State private var isHovering = false
    
    /// Timer to auto-hide controls after inactivity
    @State private var hideControlsTask: Task<Void, Never>?
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
            
            // YouTube player
            if let currentItem = playbackController.currentItem, currentItem.kind == .youtube {
                YouTubePlayerView(player: playbackController.youtubePlayer)
                    .ignoresSafeArea()
            }
            
            // Controls overlay (visible on hover)
            if isHovering {
                controlsOverlay
                    .transition(.opacity)
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
            
            // Auto-hide controls after 3 seconds of inactivity
            hideControlsTask?.cancel()
            if hovering {
                hideControlsTask = Task {
                    try? await Task.sleep(for: .seconds(3))
                    if !Task.isCancelled {
                        await MainActor.run {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isHovering = false
                            }
                        }
                    }
                }
            }
        }
        .onTapGesture(count: 2) {
            // Double-click to exit fullscreen
            appModel.isFullscreen = false
        }
        .focusable()
        .onKeyPress(.escape) {
            appModel.isFullscreen = false
            return .handled
        }
        .onKeyPress(.space) {
            playbackController.togglePlayPause()
            return .handled
        }
        .onKeyPress("f") {
            appModel.isFullscreen = false
            return .handled
        }
        .onAppear {
            // Enter the window's native fullscreen mode when view appears
            enterNativeFullscreen()
        }
        .onDisappear {
            // Reset fullscreen state when window is closed
            appModel.isFullscreen = false
        }
    }
    
    // MARK: - Native Fullscreen
    
    /// Enters the window's native macOS fullscreen mode
    private func enterNativeFullscreen() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let window = NSApp.windows.first(where: { $0.title == "Fullscreen Player" }) else { return }
            
            if !window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            }
        }
    }
    
    // MARK: - Controls Overlay
    
    @ViewBuilder
    private var controlsOverlay: some View {
        VStack {
            // Top bar with title and exit button
            HStack {
                // Track title
                if let item = playbackController.currentItem {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.headline)
                            .foregroundStyle(.white)
                        if let subtitle = item.subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
                
                Spacer()
                
                // Exit fullscreen button
                Button {
                    appModel.isFullscreen = false
                } label: {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.white.opacity(0.2), in: Circle())
                }
                .buttonStyle(.plain)
                .help("Exit Fullscreen (Esc)")
            }
            .padding()
            .background {
                LinearGradient(
                    colors: [.black.opacity(0.7), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            
            Spacer()
            
            // Bottom bar with playback controls
            VStack(spacing: 16) {
                // Progress bar
                progressBar
                
                // Transport controls
                HStack(spacing: 40) {
                    // Previous
                    Button {
                        Task {
                            try? await playbackController.previous()
                        }
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    
                    // Play/Pause
                    Button {
                        playbackController.togglePlayPause()
                    } label: {
                        Image(systemName: playbackController.state == .playing ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    
                    // Next
                    Button {
                        Task {
                            try? await playbackController.next()
                        }
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .padding(.bottom)
            .background {
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
    
    // MARK: - Progress Bar
    
    @ViewBuilder
    private var progressBar: some View {
        if let duration = playbackController.duration, duration > 0 {
            let currentTime = playbackController.currentTime ?? 0
            let progress = currentTime / duration
            
            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { progress },
                        set: { newValue in
                            playbackController.seek(to: duration * newValue)
                        }
                    ),
                    in: 0...1
                )
                .tint(.white)
                
                HStack {
                    Text(formatTime(currentTime))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .monospacedDigit()
                    
                    Spacer()
                    
                    Text(formatTime(duration))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .monospacedDigit()
                }
            }
            .padding(.horizontal)
        }
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
}

#Preview {
    FullscreenPlayerView()
        .environment(PlaybackController())
        .environment(AppModel())
}
