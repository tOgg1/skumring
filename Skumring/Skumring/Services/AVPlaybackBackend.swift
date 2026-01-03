import AVFoundation
import Foundation
import Observation

/// Error types that can occur during AVPlayer playback.
enum AVPlaybackError: Error, LocalizedError {
    case failedToLoadAsset(Error)
    case assetNotPlayable
    case itemFailedToLoad(Error?)
    
    var errorDescription: String? {
        switch self {
        case .failedToLoadAsset(let error):
            return "Failed to load asset: \(error.localizedDescription)"
        case .assetNotPlayable:
            return "Asset is not playable"
        case .itemFailedToLoad(let error):
            if let error = error {
                return "Item failed to load: \(error.localizedDescription)"
            }
            return "Item failed to load"
        }
    }
}

/// AVPlayer-based implementation of PlaybackBackend for streams and audio URLs.
///
/// This class wraps AVPlayer to provide playback of internet radio streams,
/// direct audio file URLs (mp3, aac, etc.), and other AVPlayer-compatible media.
///
/// The class is observable to enable SwiftUI integration.
@MainActor
@Observable
final class AVPlaybackBackend: PlaybackBackend {
    
    // MARK: - Private Properties
    
    /// The underlying AVPlayer instance.
    private var player: AVPlayer?
    
    /// The currently loaded URL.
    private(set) var currentURL: URL?
    
    /// KVO observers for player status changes.
    private var statusObserver: NSKeyValueObservation?
    private var timeControlObserver: NSKeyValueObservation?
    
    /// Token for the periodic time observer.
    private var timeObserverToken: Any?
    
    /// Cached current time, updated by periodic observer.
    private(set) var observedCurrentTime: TimeInterval?
    
    // MARK: - Reconnection Properties
    
    /// Maximum number of reconnection attempts.
    private static let maxReconnectAttempts = 3
    
    /// Base delay for exponential backoff (in seconds).
    private static let baseReconnectDelay: TimeInterval = 1.0
    
    /// Current reconnection attempt count.
    private var reconnectAttemptCount = 0
    
    /// Whether a reconnection attempt is in progress.
    private(set) var isReconnecting = false
    
    /// Task for managing reconnection attempts.
    private var reconnectTask: Task<Void, Never>?
    
    // MARK: - PlaybackBackend Protocol Properties
    
    /// The current playback state.
    private(set) var state: PlaybackState = .stopped
    
    /// Whether media is currently playing.
    var isPlaying: Bool {
        guard let player = player else { return false }
        return player.timeControlStatus == .playing
    }
    
    /// The current playback position in seconds, or nil if not available.
    var currentTime: TimeInterval? {
        guard let player = player else { return nil }
        let time = player.currentTime()
        guard time.isValid && !time.isIndefinite else { return nil }
        return CMTimeGetSeconds(time)
    }
    
    /// The total duration in seconds, or nil if not available (e.g., live streams).
    var duration: TimeInterval? {
        guard let player = player,
              let item = player.currentItem else { return nil }
        let duration = item.duration
        guard duration.isValid && !duration.isIndefinite else { return nil }
        return CMTimeGetSeconds(duration)
    }
    
    // MARK: - Initialization
    
    init() {
        // Player is created lazily on first play
    }
    
    // Note: No deinit needed - AVPlayer and observers are cleaned up automatically
    // when this object is deallocated. If explicit cleanup is needed before deallocation,
    // call stop() from the owning PlaybackController.
    
    // MARK: - PlaybackBackend Protocol Methods
    
    /// Starts playback of media at the given URL.
    ///
    /// Creates a new AVPlayerItem and AVPlayer (if needed), then begins playback.
    /// This method waits for the item to become ready before returning.
    ///
    /// - Parameter url: The URL of the media to play
    /// - Throws: AVPlaybackError if the media cannot be loaded
    func play(url: URL) async throws {
        // Clean up previous item
        stopObservers()
        
        state = .loading
        currentURL = url
        
        // Create asset and check if it's playable
        let asset = AVURLAsset(url: url)
        
        do {
            // Load asset properties asynchronously
            let isPlayable = try await asset.load(.isPlayable)
            
            guard isPlayable else {
                state = .error("Asset is not playable")
                throw AVPlaybackError.assetNotPlayable
            }
            
            // Create player item
            let item = AVPlayerItem(asset: asset)
            
            // Create player if needed
            if player == nil {
                player = AVPlayer()
            }
            
            // Replace current item and start playback
            player?.replaceCurrentItem(with: item)
            setupObservers()
            player?.play()
            
            // Wait for playback to actually start or fail
            try await waitForPlaybackReady()
            
        } catch let error as AVPlaybackError {
            throw error
        } catch {
            state = .error(error.localizedDescription)
            throw AVPlaybackError.failedToLoadAsset(error)
        }
    }
    
    /// Pauses the current playback.
    func pause() {
        guard let player = player else { return }
        player.pause()
        if case .playing = state {
            state = .paused
        }
    }
    
    /// Resumes playback from the paused state.
    func resume() {
        guard let player = player else { return }
        player.play()
        if case .paused = state {
            state = .playing
        }
    }
    
    /// Stops playback and clears the current media.
    func stop() {
        cancelReconnection()
        stopObservers()
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        currentURL = nil
        state = .stopped
    }
    
    /// Seeks to the specified time position.
    ///
    /// - Parameter time: The target time in seconds
    func seek(to time: TimeInterval) {
        guard let player = player else { return }
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    /// Sets the playback volume.
    ///
    /// - Parameter volume: The volume level from 0.0 (mute) to 1.0 (max)
    func setVolume(_ volume: Float) {
        player?.volume = max(0.0, min(1.0, volume))
    }
    
    // MARK: - Private Methods
    
    /// Sets up KVO observers for the player.
    private func setupObservers() {
        guard let player = player else { return }
        
        // Observe time control status for play/pause state changes
        timeControlObserver = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            Task { @MainActor in
                guard let self = self else { return }
                switch player.timeControlStatus {
                case .playing:
                    self.state = .playing
                case .paused:
                    // Only set paused if we were playing (not stopped)
                    if case .playing = self.state {
                        self.state = .paused
                    }
                case .waitingToPlayAtSpecifiedRate:
                    self.state = .loading
                @unknown default:
                    break
                }
            }
        }
        
        // Observe player item status
        statusObserver = player.observe(\.currentItem?.status, options: [.new]) { [weak self] player, _ in
            Task { @MainActor in
                guard let self = self,
                      let status = player.currentItem?.status else { return }
                
                switch status {
                case .failed:
                    // Trigger reconnection on failure instead of immediately setting error state
                    self.handleStreamFailure(error: player.currentItem?.error)
                case .readyToPlay:
                    // State will be updated by timeControlStatus observer
                    break
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        }
        
        // Add periodic time observer to update current time every 0.5 seconds
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            if time.isValid && !time.isIndefinite {
                self.observedCurrentTime = CMTimeGetSeconds(time)
            }
        }
    }
    
    /// Removes KVO observers and time observer.
    private func stopObservers() {
        statusObserver?.invalidate()
        statusObserver = nil
        timeControlObserver?.invalidate()
        timeControlObserver = nil
        
        // Remove periodic time observer
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        observedCurrentTime = nil
    }
    
    /// Waits for the player item to become ready to play.
    private func waitForPlaybackReady() async throws {
        guard let player = player,
              let item = player.currentItem else {
            throw AVPlaybackError.itemFailedToLoad(nil)
        }
        
        // Poll for status changes (simple approach for now)
        // A more sophisticated approach would use NotificationCenter
        for _ in 0..<50 { // 5 second timeout
            try await Task.sleep(for: .milliseconds(100))
            
            switch item.status {
            case .readyToPlay:
                state = .playing
                return
            case .failed:
                throw AVPlaybackError.itemFailedToLoad(item.error)
            case .unknown:
                continue
            @unknown default:
                continue
            }
        }
        
        // Timeout - check final status
        if item.status == .readyToPlay {
            state = .playing
        } else if item.status == .failed {
            throw AVPlaybackError.itemFailedToLoad(item.error)
        }
    }
    
    // MARK: - Reconnection Logic
    
    /// Attempts to reconnect to the current stream with exponential backoff.
    ///
    /// On stream failure, attempts up to 3 reconnections with delays of 1s, 2s, 4s.
    /// Updates state to .error after final failure.
    ///
    /// - Parameter error: The original error that triggered reconnection
    func attemptReconnection(after error: Error) {
        guard let url = currentURL else {
            state = .error(error.localizedDescription)
            return
        }
        
        // Cancel any existing reconnection attempt
        cancelReconnection()
        
        reconnectTask = Task { [weak self] in
            guard let self = self else { return }
            
            while self.reconnectAttemptCount < Self.maxReconnectAttempts {
                self.reconnectAttemptCount += 1
                self.isReconnecting = true
                
                // Calculate delay with exponential backoff: 1s, 2s, 4s
                let delay = Self.baseReconnectDelay * pow(2.0, Double(self.reconnectAttemptCount - 1))
                self.state = .reconnecting(attempt: self.reconnectAttemptCount, maxAttempts: Self.maxReconnectAttempts)
                
                // Wait before attempting reconnection
                do {
                    try await Task.sleep(for: .seconds(delay))
                } catch {
                    // Task was cancelled
                    self.isReconnecting = false
                    return
                }
                
                // Check if task was cancelled
                if Task.isCancelled {
                    self.isReconnecting = false
                    return
                }
                
                // Attempt to play again
                do {
                    try await self.playWithoutReconnect(url: url)
                    // Success - reset reconnection state
                    self.reconnectAttemptCount = 0
                    self.isReconnecting = false
                    return
                } catch {
                    // Continue to next attempt
                    continue
                }
            }
            
            // All attempts exhausted
            self.isReconnecting = false
            self.reconnectAttemptCount = 0
            self.state = .error("Connection lost - all reconnection attempts failed")
        }
    }
    
    /// Internal play method that doesn't trigger reconnection on failure.
    ///
    /// Used by the reconnection logic to avoid recursive reconnection attempts.
    private func playWithoutReconnect(url: URL) async throws {
        stopObservers()
        
        state = .loading
        currentURL = url
        
        let asset = AVURLAsset(url: url)
        
        let isPlayable = try await asset.load(.isPlayable)
        
        guard isPlayable else {
            throw AVPlaybackError.assetNotPlayable
        }
        
        let item = AVPlayerItem(asset: asset)
        
        if player == nil {
            player = AVPlayer()
        }
        
        player?.replaceCurrentItem(with: item)
        setupObservers()
        player?.play()
        
        try await waitForPlaybackReady()
    }
    
    /// Cancels any in-progress reconnection attempt.
    func cancelReconnection() {
        reconnectTask?.cancel()
        reconnectTask = nil
        isReconnecting = false
        reconnectAttemptCount = 0
    }
    
    /// Handles a stream failure by attempting reconnection.
    ///
    /// Called when the player item status changes to .failed.
    func handleStreamFailure(error: Error?) {
        let errorToReport = error ?? NSError(domain: "AVPlaybackBackend", code: -1, userInfo: [NSLocalizedDescriptionKey: "Stream playback failed"])
        attemptReconnection(after: errorToReport)
    }
}
