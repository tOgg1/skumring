import AppKit
import Foundation
import MediaPlayer
import Observation

/// Service that updates the system Now Playing info center with current playback information.
///
/// NowPlayingService observes the PlaybackController and updates MPNowPlayingInfoCenter
/// with the current track's metadata. This enables display in Control Center and on
/// external devices like AirPlay receivers.
///
/// The service updates:
/// - Track title
/// - Artist/subtitle
/// - Artwork (when available)
/// - Duration
/// - Elapsed time (updated periodically)
/// - Playback rate (0.0 when paused, 1.0 when playing)
///
/// Usage:
/// ```swift
/// let service = NowPlayingService(
///     playbackController: controller,
///     artworkCache: cache
/// )
/// // Service automatically observes and updates Now Playing info
/// ```
@MainActor
final class NowPlayingService {
    
    // MARK: - Properties
    
    /// The playback controller to observe
    private let playbackController: PlaybackController
    
    /// Cache for loading artwork images
    private let artworkCache: ArtworkCache
    
    /// Reference to the Now Playing info center
    private var infoCenter: MPNowPlayingInfoCenter {
        MPNowPlayingInfoCenter.default()
    }
    
    /// Timer for periodic elapsed time updates
    private var updateTimer: Timer?
    
    /// How often to update elapsed time (in seconds)
    private let updateInterval: TimeInterval = 1.0
    
    /// The last item we updated info for (to detect changes)
    private var lastItemID: UUID?
    
    /// Cached artwork for the current item
    private var currentArtwork: MPMediaItemArtwork?
    
    // MARK: - Initialization
    
    /// Creates a new NowPlayingService.
    ///
    /// - Parameters:
    ///   - playbackController: The playback controller to observe
    ///   - artworkCache: Cache for loading artwork images
    init(playbackController: PlaybackController, artworkCache: ArtworkCache) {
        self.playbackController = playbackController
        self.artworkCache = artworkCache
        
        // Initial update
        updateNowPlayingInfo()
        
        // Start observing
        startObserving()
    }
    
    // MARK: - Cleanup
    
    /// Stops the update timer. Call this when the service is no longer needed.
    func stop() {
        updateTimer?.invalidate()
        updateTimer = nil
        clearNowPlayingInfo()
    }
    
    // MARK: - Observation
    
    /// Starts observing playback changes
    private func startObserving() {
        // Start a timer to periodically check state and update
        // This handles both state changes and elapsed time updates
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateNowPlayingInfo()
            }
        }
    }
    
    // MARK: - Now Playing Info Updates
    
    /// Updates the Now Playing info center with current playback state.
    func updateNowPlayingInfo() {
        guard let item = playbackController.currentItem else {
            clearNowPlayingInfo()
            return
        }
        
        let state = playbackController.state
        
        // Build the info dictionary
        var info: [String: Any] = [:]
        
        // Title
        info[MPMediaItemPropertyTitle] = item.title
        
        // Artist (using subtitle)
        if let subtitle = item.subtitle {
            info[MPMediaItemPropertyArtist] = subtitle
        }
        
        // Media type
        switch item.kind {
        case .stream:
            info[MPNowPlayingInfoPropertyIsLiveStream] = true
            info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        case .youtube:
            info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.video.rawValue
        case .audioURL:
            info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        }
        
        // Duration (if available and not a live stream)
        if let duration = playbackController.duration, item.kind != .stream {
            info[MPMediaItemPropertyPlaybackDuration] = duration
        }
        
        // Elapsed time
        if let currentTime = playbackController.currentTime {
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        }
        
        // Playback rate (0.0 when paused, 1.0 when playing)
        switch state {
        case .playing:
            info[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        case .paused, .loading, .stopped, .reconnecting, .error:
            info[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
        }
        
        // Check if we need to load artwork (item changed)
        if item.id != lastItemID {
            lastItemID = item.id
            currentArtwork = nil
            
            // Load artwork asynchronously
            if let artworkURL = item.artworkURL {
                Task {
                    await loadArtwork(url: artworkURL)
                }
            }
        }
        
        // Include cached artwork if available
        if let artwork = currentArtwork {
            info[MPMediaItemPropertyArtwork] = artwork
        }
        
        // Apply the update
        infoCenter.nowPlayingInfo = info
    }
    
    /// Clears the Now Playing info when nothing is playing.
    private func clearNowPlayingInfo() {
        infoCenter.nowPlayingInfo = nil
        lastItemID = nil
        currentArtwork = nil
    }
    
    // MARK: - Artwork Loading
    
    /// Loads artwork from URL and updates the Now Playing info.
    ///
    /// - Parameter url: The artwork URL to load
    private func loadArtwork(url: URL) async {
        guard let image = await artworkCache.fetchAndCache(url: url) else {
            return
        }
        
        // Create MPMediaItemArtwork using the helper function to avoid actor isolation issues
        let artwork = Self.createArtwork(from: image)
        
        // Store for reuse
        currentArtwork = artwork
        
        // Update with artwork included
        updateNowPlayingInfo()
    }
    
    /// Creates an MPMediaItemArtwork from an NSImage.
    ///
    /// This is a nonisolated static function to avoid actor isolation issues.
    /// The requestHandler closure passed to MPMediaItemArtwork is called by MediaPlayer
    /// on an arbitrary background queue. By creating the artwork in a nonisolated context,
    /// we avoid the Swift concurrency runtime checking for main actor isolation when
    /// the closure is invoked.
    ///
    /// - Parameter image: The source image
    /// - Returns: An MPMediaItemArtwork configured to return the image
    private nonisolated static func createArtwork(from image: NSImage) -> MPMediaItemArtwork {
        // Capture image size before the closure to avoid any potential issues
        let imageSize = image.size
        
        // NSImage is thread-safe for reading once created, so this is safe
        // even though NSImage is not Sendable
        return MPMediaItemArtwork(boundsSize: imageSize) { _ in
            return image
        }
    }
}
