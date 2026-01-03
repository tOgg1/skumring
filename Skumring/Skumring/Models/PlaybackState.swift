import Foundation

/// The current playback state of a media player.
///
/// Represents the lifecycle of media playback from stop through loading, playing,
/// pausing, and error conditions.
enum PlaybackState: Equatable, Sendable {
    /// Player is stopped, no media loaded
    case stopped
    
    /// Media is loading (buffering, resolving stream URL, etc.)
    case loading
    
    /// Media is actively playing
    case playing
    
    /// Media is paused
    case paused
    
    /// Attempting to reconnect after a stream failure
    case reconnecting(attempt: Int, maxAttempts: Int)
    
    /// Playback failed with an error message
    case error(String)
}
