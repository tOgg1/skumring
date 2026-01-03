import Foundation

/// Shuffle mode for playlist playback.
enum ShuffleMode: String, Codable, CaseIterable, Hashable, Sendable {
    /// Play items in order
    case off
    
    /// Play items in random order
    case on
}
