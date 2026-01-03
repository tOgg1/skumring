import Foundation

/// The health status of a library item based on recent playback attempts.
///
/// Health is updated on playback:
/// - On successful playback start: `.ok`
/// - On failure: increment fail counter; after 3 consecutive failures: `.failing`
/// - Manual retry resets the fail counter and re-probes
enum HealthStatus: String, Codable, CaseIterable, Hashable, Sendable {
    /// Never tested (default for new items)
    case unknown
    
    /// Last playback or probe succeeded
    case ok
    
    /// Last N attempts failed (N=3 by default)
    case failing
}
