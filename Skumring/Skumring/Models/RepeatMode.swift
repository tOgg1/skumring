import Foundation

/// Repeat mode for playlist playback.
enum RepeatMode: String, Codable, CaseIterable, Hashable, Sendable {
    /// No repeat - stop after last item
    case off
    
    /// Repeat current item continuously
    case one
    
    /// Repeat entire playlist from start after last item
    case all
}
