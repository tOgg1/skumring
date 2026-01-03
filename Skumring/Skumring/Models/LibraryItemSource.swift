import Foundation

/// The source location for a library item.
///
/// Either contains a URL (for streams and audio files) or a YouTube video ID.
/// At least one of `url` or `youtubeID` must be set for a valid source.
struct LibraryItemSource: Codable, Hashable, Sendable {
    /// The URL for stream or audio file sources.
    /// Should be https:// for security.
    let url: URL?
    
    /// The YouTube video ID for YouTube sources.
    /// Example: "dQw4w9WgXcQ" from https://youtube.com/watch?v=dQw4w9WgXcQ
    let youtubeID: String?
    
    /// Creates a source from a URL (for streams or audio files).
    static func fromURL(_ url: URL) -> LibraryItemSource {
        LibraryItemSource(url: url, youtubeID: nil)
    }
    
    /// Creates a source from a YouTube video ID.
    static func fromYouTube(_ videoID: String) -> LibraryItemSource {
        LibraryItemSource(url: nil, youtubeID: videoID)
    }
    
    /// Whether this source is valid (has at least one source identifier).
    var isValid: Bool {
        url != nil || (youtubeID != nil && !youtubeID!.isEmpty)
    }
    
    /// A normalized key for deduplication.
    ///
    /// For URLs: lowercased scheme + host, trimmed path
    /// For YouTube: the video ID
    var sourceKey: String {
        if let youtubeID {
            return "youtube:\(youtubeID)"
        }
        if let url {
            // Normalize: lowercase scheme and host
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return url.absoluteString
            }
            components.scheme = components.scheme?.lowercased()
            components.host = components.host?.lowercased()
            return components.string ?? url.absoluteString
        }
        return ""
    }
}
