import Foundation

/// The type of media source for a library item.
///
/// Used to determine playback behavior:
/// - `stream`: Infinite/live sources (internet radio, 24/7 streams)
/// - `youtube`: YouTube video embeds via WKWebView
/// - `audioURL`: Finite audio files (mp3/aac/m4a/HLS)
enum LibraryItemKind: String, Codable, CaseIterable, Hashable, Sendable {
    /// Infinite or live audio stream (internet radio, .m3u/.pls playlists)
    case stream
    
    /// YouTube video embed (played via WKWebView IFrame API)
    case youtube
    
    /// Direct audio file URL (mp3, aac, m4a, HLS)
    case audioURL
}
