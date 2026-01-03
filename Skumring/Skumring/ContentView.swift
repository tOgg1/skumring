import SwiftUI

/// Main content view for Milestone 0: YouTube WKWebView PoC
/// This validates that YouTube IFrame API works in WKWebView on macOS Tahoe 26
struct ContentView: View {
    // Test video: Big Buck Bunny (public domain, always embeddable)
    @State private var player = YouTubePlayer(
        videoID: "aqz-KE-bpKQ",
        autoplay: false,
        loop: true
    )
    
    @State private var customVideoID: String = "aqz-KE-bpKQ"
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Main content: YouTube player
            YouTubePlayerView(player: player)
                .frame(minWidth: 480, minHeight: 270)
            
            Divider()
            
            // Controls and status
            controlsPanel
        }
        .frame(minWidth: 600, minHeight: 500)
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Skumring - Milestone 0")
                    .font(.headline)
                Text("YouTube WKWebView PoC")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Video ID input
            HStack {
                TextField("Video ID", text: $customVideoID)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 150)
                
                Button("Load") {
                    player = YouTubePlayer(
                        videoID: customVideoID,
                        autoplay: false,
                        loop: true
                    )
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
    
    // MARK: - Controls Panel
    
    private var controlsPanel: some View {
        VStack(spacing: 16) {
            // Status row
            HStack(spacing: 20) {
                statusBadge("Ready", value: player.isReady ? "Yes" : "No", color: player.isReady ? .green : .orange)
                statusBadge("State", value: player.playerState.description, color: stateColor)
                statusBadge("Time", value: formatTime(player.currentTime), color: .blue)
                statusBadge("Duration", value: formatTime(player.duration), color: .blue)
            }
            
            // Error display
            if let error = player.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .foregroundStyle(.red)
                }
                .padding(8)
                .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
            
            // Playback controls
            HStack(spacing: 16) {
                Button(action: { player.play() }) {
                    Label("Play", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!player.isReady)
                
                Button(action: { player.pause() }) {
                    Label("Pause", systemImage: "pause.fill")
                }
                .buttonStyle(.bordered)
                .disabled(!player.isReady)
                
                Button(action: { player.seek(to: 0) }) {
                    Label("Restart", systemImage: "backward.end.fill")
                }
                .buttonStyle(.bordered)
                .disabled(!player.isReady)
                
                Button(action: { player.seek(to: player.currentTime + 30) }) {
                    Label("+30s", systemImage: "goforward.30")
                }
                .buttonStyle(.bordered)
                .disabled(!player.isReady)
            }
            
            // Test checklist
            testChecklist
        }
        .padding()
    }
    
    // MARK: - Test Checklist
    
    private var testChecklist: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PoC Validation Checklist")
                .font(.headline)
            
            checklistItem("Player loads and becomes ready", passed: player.isReady)
            checklistItem("Play command works", passed: player.playerState == .playing)
            checklistItem("Pause command works", passed: player.playerState == .paused && player.currentTime > 0)
            checklistItem("Seek command works", passed: player.currentTime > 5)
            checklistItem("Time updates received", passed: player.duration > 0)
            checklistItem("No errors", passed: player.errorMessage == nil)
        }
        .padding()
        .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Helpers
    
    private func statusBadge(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(color)
        }
    }
    
    private func checklistItem(_ text: String, passed: Bool) -> some View {
        HStack {
            Image(systemName: passed ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(passed ? .green : .secondary)
            Text(text)
                .foregroundStyle(passed ? .primary : .secondary)
        }
    }
    
    private var stateColor: Color {
        switch player.playerState {
        case .playing: return .green
        case .paused: return .orange
        case .buffering: return .yellow
        case .ended: return .blue
        case .unstarted, .cued: return .secondary
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "--:--" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

#Preview {
    ContentView()
}
