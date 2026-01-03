import Foundation
import Observation

/// Unified playback controller that manages playback across multiple backends.
///
/// PlaybackController coordinates between AVPlaybackBackend (for streams and audio URLs)
/// and YouTubePlayer (for YouTube videos). It provides a single interface for the UI
/// to control playback regardless of the underlying media type.
///
/// Key responsibilities:
/// - Route play requests to the appropriate backend based on item kind
/// - Manage the playback queue
/// - Expose unified state for UI binding
/// - Handle transitions between items
///
/// Usage:
/// ```swift
/// let controller = PlaybackController()
/// try await controller.play(item: libraryItem)
/// controller.togglePlayPause()
/// ```
@MainActor
@Observable
final class PlaybackController {
    
    // MARK: - Active Backend Tracking
    
    /// Which backend is currently active for playback
    enum ActiveBackend {
        case none
        case av
        case youtube
    }
    
    /// The currently active playback backend
    private(set) var activeBackend: ActiveBackend = .none
    
    // MARK: - Backends
    
    /// Backend for streams and direct audio URLs
    let avBackend: AVPlaybackBackend
    
    /// Backend for YouTube video playback
    let youtubePlayer: YouTubePlayer
    
    // MARK: - State
    
    /// The currently playing item, if any.
    private(set) var currentItem: LibraryItem?
    
    /// The current playback state (unified across backends).
    var state: PlaybackState {
        switch activeBackend {
        case .none:
            return .stopped
        case .av:
            return avBackend.state
        case .youtube:
            return youtubePlayer.state
        }
    }
    
    /// Whether any media is currently playing.
    var isPlaying: Bool {
        switch activeBackend {
        case .none:
            return false
        case .av:
            return avBackend.isPlaying
        case .youtube:
            return youtubePlayer.isPlaying
        }
    }
    
    /// The current playback position in seconds.
    var currentTime: TimeInterval? {
        switch activeBackend {
        case .none:
            return nil
        case .av:
            return avBackend.currentTime
        case .youtube:
            return youtubePlayer.currentTimeInterval
        }
    }
    
    /// The total duration in seconds (nil for live streams).
    var duration: TimeInterval? {
        switch activeBackend {
        case .none:
            return nil
        case .av:
            return avBackend.duration
        case .youtube:
            return youtubePlayer.durationInterval
        }
    }
    
    /// The current volume level (0.0 to 1.0).
    private(set) var volume: Float = 1.0
    
    // MARK: - Queue
    
    /// Items in the current playback queue.
    private(set) var queue: [LibraryItem] = []
    
    /// Index of the current item in the queue, or nil if not in queue mode.
    private(set) var queueIndex: Int?
    
    /// The current repeat mode for queue playback.
    var repeatMode: RepeatMode = .off
    
    /// The current shuffle mode for queue playback.
    var shuffleMode: ShuffleMode = .off
    
    // MARK: - Initialization
    
    init() {
        self.avBackend = AVPlaybackBackend()
        self.youtubePlayer = YouTubePlayer()
        setupYouTubeStateCallback()
    }
    
    /// Configures the YouTube player's state change callback to handle queue advancement
    private func setupYouTubeStateCallback() {
        youtubePlayer.onStateChange = { [weak self] (state: YouTubePlayerState) in
            self?.handleYouTubeStateChange(state)
        }
    }
    
    // MARK: - YouTube State Observation
    
    /// Called when YouTube playback state changes.
    ///
    /// When playback ends while in queue mode, it automatically advances to the next item.
    ///
    /// - Parameter newState: The new YouTube player state
    private func handleYouTubeStateChange(_ newState: YouTubePlayerState) {
        guard activeBackend == .youtube else { return }
        
        if newState == .ended && !queue.isEmpty && queueIndex != nil {
            // Video ended while in queue mode - advance to next
            Task {
                try? await next()
            }
        }
    }
    
    // MARK: - Playback Control
    
    /// Plays the given library item.
    ///
    /// Routes to the appropriate backend based on the item's kind.
    /// Stops the previous backend before switching to ensure clean transitions.
    ///
    /// - Parameter item: The item to play
    /// - Throws: If playback cannot be started
    func play(item: LibraryItem) async throws {
        // Stop the previous backend before switching
        stopCurrentBackend()
        
        currentItem = item
        
        switch item.kind {
        case .stream, .audioURL:
            // Use AV backend for streams and audio URLs
            guard let url = item.source.url else {
                throw PlaybackControllerError.invalidSource
            }
            activeBackend = .av
            try await avBackend.play(url: url)
            
        case .youtube:
            // Use YouTube backend for YouTube videos
            guard let videoID = item.source.youtubeID else {
                throw PlaybackControllerError.invalidSource
            }
            activeBackend = .youtube
            youtubePlayer.play(videoID: videoID)
        }
    }
    
    /// Stops the currently active backend without clearing controller state.
    private func stopCurrentBackend() {
        switch activeBackend {
        case .none:
            break
        case .av:
            avBackend.stop()
        case .youtube:
            youtubePlayer.stop()
        }
    }
    
    /// Plays a queue of items starting at the specified index.
    ///
    /// - Parameters:
    ///   - items: The items to add to the queue
    ///   - startingAt: The index to start playing from
    /// - Throws: If playback cannot be started
    func playQueue(items: [LibraryItem], startingAt index: Int = 0) async throws {
        guard !items.isEmpty else { return }
        guard index >= 0 && index < items.count else {
            throw PlaybackControllerError.invalidQueueIndex
        }
        
        queue = items
        queueIndex = index
        try await play(item: items[index])
    }
    
    /// Toggles between play and pause states.
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }
    
    /// Pauses playback.
    func pause() {
        switch activeBackend {
        case .none:
            break
        case .av:
            avBackend.pause()
        case .youtube:
            youtubePlayer.pause()
        }
    }
    
    /// Resumes playback.
    func resume() {
        switch activeBackend {
        case .none:
            break
        case .av:
            avBackend.resume()
        case .youtube:
            youtubePlayer.resume()
        }
    }
    
    /// Stops playback and clears the current item.
    func stop() {
        stopCurrentBackend()
        activeBackend = .none
        currentItem = nil
        queue = []
        queueIndex = nil
    }
    
    /// Seeks to the specified time.
    ///
    /// - Parameter time: The target time in seconds
    func seek(to time: TimeInterval) {
        switch activeBackend {
        case .none:
            break
        case .av:
            avBackend.seek(to: time)
        case .youtube:
            youtubePlayer.seek(to: time)
        }
    }
    
    /// Sets the playback volume.
    ///
    /// - Parameter newVolume: Volume level from 0.0 to 1.0
    func setVolume(_ newVolume: Float) {
        volume = max(0.0, min(1.0, newVolume))
        switch activeBackend {
        case .none:
            break
        case .av:
            avBackend.setVolume(volume)
        case .youtube:
            youtubePlayer.setVolume(volume)
        }
    }
    
    // MARK: - Queue Navigation
    
    /// Plays the next item in the queue.
    ///
    /// Behavior depends on repeat mode:
    /// - `.off`: Stop if at end of queue
    /// - `.one`: Replay current item
    /// - `.all`: Wrap to first item when at end
    func next() async throws {
        guard !queue.isEmpty, let currentIndex = queueIndex else { return }
        
        switch repeatMode {
        case .one:
            // Repeat current item - seek to beginning
            seek(to: 0)
            resume()
            
        case .all:
            // Wrap around to start if at end
            let nextIndex = (currentIndex + 1) % queue.count
            queueIndex = nextIndex
            try await play(item: queue[nextIndex])
            
        case .off:
            // Move to next or stop if at end
            if currentIndex + 1 < queue.count {
                queueIndex = currentIndex + 1
                try await play(item: queue[currentIndex + 1])
            } else {
                stop()
            }
        }
    }
    
    /// Plays the previous item in the queue.
    ///
    /// If current playback time is > 3 seconds, seeks to beginning of current item.
    /// Otherwise moves to previous item.
    /// At the start of queue with repeat all, wraps to last item.
    func previous() async throws {
        guard !queue.isEmpty, let currentIndex = queueIndex else { return }
        
        // If we're more than 3 seconds in, restart current track
        if let time = currentTime, time > 3 {
            seek(to: 0)
            return
        }
        
        switch repeatMode {
        case .one:
            // Always restart current item
            seek(to: 0)
            resume()
            
        case .all:
            // Wrap around to end if at start
            let prevIndex = currentIndex > 0 ? currentIndex - 1 : queue.count - 1
            queueIndex = prevIndex
            try await play(item: queue[prevIndex])
            
        case .off:
            // Move to previous or stay at start
            if currentIndex > 0 {
                queueIndex = currentIndex - 1
                try await play(item: queue[currentIndex - 1])
            } else {
                // At start, just restart current item
                seek(to: 0)
            }
        }
    }
}

// MARK: - Errors

/// Errors that can occur during playback operations.
enum PlaybackControllerError: Error, LocalizedError {
    case invalidSource
    case invalidQueueIndex
    
    var errorDescription: String? {
        switch self {
        case .invalidSource:
            return "The item's source URL could not be resolved"
        case .invalidQueueIndex:
            return "Invalid queue index"
        }
    }
}
