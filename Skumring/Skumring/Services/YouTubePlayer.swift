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
    
    /// Converts YouTube player state to the unified PlaybackState enum
    var asPlaybackState: PlaybackState {
        switch self {
        case .unstarted: return .stopped
        case .ended: return .stopped
        case .playing: return .playing
        case .paused: return .paused
        case .buffering: return .loading
        case .cued: return .loading
        }
    }
}

/// Observable model for YouTube player state
///
/// Provides a PlaybackBackend-compatible interface for use with PlaybackController.
/// The primary play method is `play(videoID:)` rather than `play(url:)` since
/// YouTube content is accessed by video ID.
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
    /// Called when a new video should be loaded
    var onLoadVideo: ((String) -> Void)?
    
    // MARK: - State Change Callback (set by PlaybackController)
    
    /// Called when the player state changes. Used by PlaybackController to handle
    /// queue advancement when a video ends.
    var onStateChange: ((YouTubePlayerState) -> Void)?
    
    /// Volume level from 0.0 to 1.0
    private var _volume: Float = 1.0
    
    // MARK: - Init
    
    init(videoID: String = "", autoplay: Bool = false, loop: Bool = false) {
        self.videoID = videoID
        self.autoplay = autoplay
        self.loop = loop
    }
    
    // MARK: - PlaybackBackend-Compatible Interface
    
    /// The current playback state in the unified PlaybackState format
    var state: PlaybackState {
        if let error = errorMessage {
            return .error(error)
        }
        return playerState.asPlaybackState
    }
    
    /// Whether media is currently playing
    var isPlaying: Bool {
        playerState == .playing
    }
    
    /// The current playback position in seconds
    var currentTimeInterval: TimeInterval? {
        guard currentTime > 0 || isReady else { return nil }
        return TimeInterval(currentTime)
    }
    
    /// The total duration in seconds, or nil if not available
    var durationInterval: TimeInterval? {
        guard duration > 0 else { return nil }
        return TimeInterval(duration)
    }
    
    /// Starts playback of a YouTube video by ID
    ///
    /// - Parameter videoID: The YouTube video ID to play
    func play(videoID: String) {
        self.videoID = videoID
        onLoadVideo?(videoID)
        onPlay?()
    }
    
    /// Pauses the current playback
    func pause() {
        onPause?()
    }
    
    /// Resumes playback from the paused state
    func resume() {
        onPlay?()
    }
    
    /// Stops playback and resets state
    func stop() {
        onPause?()
        playerState = .unstarted
        currentTime = 0
    }
    
    /// Seeks to the specified time position
    ///
    /// - Parameter time: The target time in seconds
    func seek(to time: TimeInterval) {
        onSeek?(time)
    }
    
    /// Sets the playback volume
    ///
    /// - Parameter volume: The volume level from 0.0 (mute) to 1.0 (max)
    func setVolume(_ volume: Float) {
        _volume = max(0.0, min(1.0, volume))
        // Convert from 0.0-1.0 to 0-100 for YouTube API
        let intVolume = Int(_volume * 100)
        onSetVolume?(intVolume)
    }
    
    // MARK: - Legacy Interface (for backward compatibility)
    
    /// Starts or resumes playback
    @available(*, deprecated, renamed: "resume()")
    func play() {
        onPlay?()
    }
    
    /// Seeks to the specified time (legacy interface accepting Double)
    func seek(toSeconds seconds: Double) {
        onSeek?(seconds)
    }
    
    /// Sets volume using 0-100 scale (legacy interface)
    func setVolume(percent volume: Int) {
        let clamped = max(0, min(100, volume))
        _volume = Float(clamped) / 100.0
        onSetVolume?(clamped)
    }
    
    // MARK: - State Updates (called by YouTubePlayerView via JS bridge)
    
    func updateState(_ state: YouTubePlayerState) {
        self.playerState = state
        onStateChange?(state)
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
