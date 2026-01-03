import Foundation

/// A single item in the user's music library.
///
/// Library items can be streams, YouTube videos, or direct audio URLs.
/// Each item tracks its health status based on playback success/failure.
struct LibraryItem: Codable, Identifiable, Hashable, Sendable {
    /// Unique identifier for this item
    let id: UUID
    
    /// The type of media source
    let kind: LibraryItemKind
    
    /// Display title for the item
    var title: String
    
    /// Optional subtitle (e.g., artist, station name)
    var subtitle: String?
    
    /// The source URL or YouTube ID
    let source: LibraryItemSource
    
    /// When this item was added to the library
    let addedAt: Date
    
    /// User-defined tags for organization and filtering
    var tags: [String]
    
    /// Optional URL for artwork/cover image
    var artworkURL: URL?
    
    /// Current health status based on playback attempts
    var healthStatus: HealthStatus
    
    /// Number of consecutive playback failures
    var failCount: Int
    
    /// Creates a new library item with default values for optional fields.
    init(
        id: UUID = UUID(),
        kind: LibraryItemKind,
        title: String,
        subtitle: String? = nil,
        source: LibraryItemSource,
        addedAt: Date = Date(),
        tags: [String] = [],
        artworkURL: URL? = nil,
        healthStatus: HealthStatus = .unknown,
        failCount: Int = 0
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.source = source
        self.addedAt = addedAt
        self.tags = tags
        self.artworkURL = artworkURL
        self.healthStatus = healthStatus
        self.failCount = failCount
    }
    
    // MARK: - Health Status Updates
    
    /// Records a successful playback, resetting health to `.ok`.
    mutating func recordSuccess() {
        healthStatus = .ok
        failCount = 0
    }
    
    /// Records a playback failure. After 3 consecutive failures, status becomes `.failing`.
    mutating func recordFailure() {
        failCount += 1
        if failCount >= 3 {
            healthStatus = .failing
        }
    }
    
    /// Resets health status for a manual retry.
    mutating func resetForRetry() {
        failCount = 0
        healthStatus = .unknown
    }
}
