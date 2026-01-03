import Foundation
import Combine

/// Represents the current state of the YouTube player
enum YouTubePlayerState: Int, CustomStringConvertible {
    case unstarted = -1
    case ended = 0
    case playing = 1
    case paused = 2
    case buffering = 3
    case cued = 5
    
    var description: String {
        switch self {
        case .unstarted: return "Unstarted"
        case .ended: return "Ended"
        case .playing: return "Playing"
        case .paused: return "Paused"
        case .buffering: return "Buffering"
        case .cued: return "Cued"
        }
    }
}

/// Observable model for YouTube player state
@MainActor
@Observable
final class YouTubePlayer {
    // MARK: - Published State
    
    private(set) var playerState: YouTubePlayerState = .unstarted
    private(set) var isReady: Bool = false
    private(set) var currentTime: Double = 0
    private(set) var duration: Double = 0
    private(set) var errorMessage: String?
    
    // MARK: - Configuration
    
    var videoID: String
    var autoplay: Bool
    var loop: Bool
    
    // MARK: - Command Callbacks (set by YouTubePlayerView)
    
    var onPlay: (() -> Void)?
    var onPause: (() -> Void)?
    var onSeek: ((Double) -> Void)?
    var onSetVolume: ((Int) -> Void)?
    
    // MARK: - Init
    
    init(videoID: String, autoplay: Bool = false, loop: Bool = false) {
        self.videoID = videoID
        self.autoplay = autoplay
        self.loop = loop
    }
    
    // MARK: - Commands (called by UI)
    
    func play() {
        onPlay?()
    }
    
    func pause() {
        onPause?()
    }
    
    func seek(to seconds: Double) {
        onSeek?(seconds)
    }
    
    func setVolume(_ volume: Int) {
        let clamped = max(0, min(100, volume))
        onSetVolume?(clamped)
    }
    
    // MARK: - State Updates (called by YouTubePlayerView via JS bridge)
    
    func updateState(_ state: YouTubePlayerState) {
        self.playerState = state
    }
    
    func updateReady(_ ready: Bool) {
        self.isReady = ready
        if ready {
            self.errorMessage = nil
        }
    }
    
    func updateTime(current: Double, duration: Double) {
        self.currentTime = current
        self.duration = duration
    }
    
    func updateError(_ message: String) {
        self.errorMessage = message
    }
}
