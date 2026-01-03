import Foundation

/// A protocol that defines the interface for media playback backends.
///
/// This protocol abstracts the playback implementation, allowing different
/// backends (AVPlayer for streams/audio URLs, WebKit for YouTube) to be
/// used interchangeably by the PlaybackController.
///
/// All conforming types must be observable classes to enable SwiftUI integration.
protocol PlaybackBackend: AnyObject {
    
    // MARK: - State Properties
    
    /// The current playback state.
    var state: PlaybackState { get }
    
    /// Whether media is currently playing.
    var isPlaying: Bool { get }
    
    /// The current playback position in seconds, or nil if not available.
    var currentTime: TimeInterval? { get }
    
    /// The total duration in seconds, or nil if not available (e.g., live streams).
    var duration: TimeInterval? { get }
    
    // MARK: - Playback Control
    
    /// Starts playback of media at the given URL.
    ///
    /// This method is asynchronous and may throw if the URL cannot be loaded
    /// or the media format is unsupported.
    ///
    /// - Parameter url: The URL of the media to play
    /// - Throws: An error if playback cannot be started
    func play(url: URL) async throws
    
    /// Pauses the current playback.
    ///
    /// If nothing is playing, this is a no-op.
    func pause()
    
    /// Resumes playback from the paused state.
    ///
    /// If nothing is paused or loaded, this is a no-op.
    func resume()
    
    /// Stops playback and clears the current media.
    ///
    /// After calling stop, a new call to play(url:) is required to resume playback.
    func stop()
    
    /// Seeks to the specified time position.
    ///
    /// If the backend doesn't support seeking (e.g., live streams) or no media
    /// is loaded, this is a no-op.
    ///
    /// - Parameter time: The target time in seconds
    func seek(to time: TimeInterval)
    
    /// Sets the playback volume.
    ///
    /// - Parameter volume: The volume level from 0.0 (mute) to 1.0 (max)
    func setVolume(_ volume: Float)
}
