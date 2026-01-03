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
@Observable
final class PlaybackController {
    
    // MARK: - Backends
    
    /// Backend for streams and direct audio URLs
    let avBackend: AVPlaybackBackend
    
    // Future: YouTubePlayer backend will be added here
    // let youtubePlayer: YouTubePlayer
    
    // MARK: - State
    
    /// The currently playing item, if any.
    private(set) var currentItem: LibraryItem?
    
    /// The current playback state (unified across backends).
    var state: PlaybackState {
        // For now, just return the AV backend state
        // When YouTube is integrated, this will check which backend is active
        avBackend.state
    }
    
    /// Whether any media is currently playing.
    var isPlaying: Bool {
        avBackend.isPlaying
    }
    
    /// The current playback position in seconds.
    var currentTime: TimeInterval? {
        avBackend.currentTime
    }
    
    /// The total duration in seconds (nil for live streams).
    var duration: TimeInterval? {
        avBackend.duration
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
    }
    
    // MARK: - Playback Control
    
    /// Plays the given library item.
    ///
    /// Routes to the appropriate backend based on the item's kind.
    ///
    /// - Parameter item: The item to play
    /// - Throws: If playback cannot be started
    func play(item: LibraryItem) async throws {
        currentItem = item
        
        switch item.kind {
        case .stream, .audioURL:
            // Use AV backend for streams and audio URLs
            guard let url = item.source.url else {
                throw PlaybackControllerError.invalidSource
            }
            try await avBackend.play(url: url)
            
        case .youtube:
            // YouTube playback will be handled by YouTubePlayer
            // For now, throw an error indicating it's not yet implemented
            throw PlaybackControllerError.youtubeNotImplemented
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
        avBackend.pause()
    }
    
    /// Resumes playback.
    func resume() {
        avBackend.resume()
    }
    
    /// Stops playback and clears the current item.
    func stop() {
        avBackend.stop()
        currentItem = nil
        queue = []
        queueIndex = nil
    }
    
    /// Seeks to the specified time.
    ///
    /// - Parameter time: The target time in seconds
    func seek(to time: TimeInterval) {
        avBackend.seek(to: time)
    }
    
    /// Sets the playback volume.
    ///
    /// - Parameter newVolume: Volume level from 0.0 to 1.0
    func setVolume(_ newVolume: Float) {
        volume = max(0.0, min(1.0, newVolume))
        avBackend.setVolume(volume)
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
    case youtubeNotImplemented
    case invalidQueueIndex
    
    var errorDescription: String? {
        switch self {
        case .invalidSource:
            return "The item's source URL could not be resolved"
        case .youtubeNotImplemented:
            return "YouTube playback is not yet implemented"
        case .invalidQueueIndex:
            return "Invalid queue index"
        }
    }
}
