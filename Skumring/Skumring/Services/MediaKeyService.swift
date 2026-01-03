import Foundation
import MediaPlayer

/// Service that handles media key events using MPRemoteCommandCenter.
///
/// MediaKeyService registers handlers for play, pause, toggle play/pause,
/// next track, and previous track commands. These map to the corresponding
/// methods on PlaybackController.
///
/// Usage:
/// ```swift
/// let service = MediaKeyService(playbackController: controller)
/// service.enable()
/// // Media keys now control playback
/// service.disable()
/// ```
///
/// Note: For macOS, the app must be playing audio for the system to route
/// media key events to it. The "Now Playing" info should also be set for
/// the best user experience.
@MainActor
final class MediaKeyService {
    
    // MARK: - Properties
    
    /// The playback controller to route commands to
    private let playbackController: PlaybackController
    
    /// Whether the service is currently enabled
    private(set) var isEnabled: Bool = false
    
    /// Reference to the shared command center
    private var commandCenter: MPRemoteCommandCenter {
        MPRemoteCommandCenter.shared()
    }
    
    // MARK: - Initialization
    
    /// Creates a new media key service.
    ///
    /// - Parameter playbackController: The playback controller to control
    init(playbackController: PlaybackController) {
        self.playbackController = playbackController
    }
    
    // MARK: - Enable/Disable
    
    /// Enables media key handling.
    ///
    /// Registers handlers for:
    /// - Play (play button / F8 play)
    /// - Pause (pause button / F8 pause)
    /// - Toggle Play/Pause (F8 toggle)
    /// - Next Track (F9 / next button)
    /// - Previous Track (F7 / previous button)
    func enable() {
        guard !isEnabled else { return }
        
        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.handlePlay()
            return .success
        }
        
        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.handlePause()
            return .success
        }
        
        // Toggle play/pause command
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.handleTogglePlayPause()
            return .success
        }
        
        // Next track command
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.handleNextTrack()
            return .success
        }
        
        // Previous track command
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.handlePreviousTrack()
            return .success
        }
        
        isEnabled = true
    }
    
    /// Disables media key handling.
    ///
    /// Removes all command handlers and disables the commands.
    func disable() {
        guard isEnabled else { return }
        
        commandCenter.playCommand.isEnabled = false
        commandCenter.playCommand.removeTarget(nil)
        
        commandCenter.pauseCommand.isEnabled = false
        commandCenter.pauseCommand.removeTarget(nil)
        
        commandCenter.togglePlayPauseCommand.isEnabled = false
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.nextTrackCommand.removeTarget(nil)
        
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.removeTarget(nil)
        
        isEnabled = false
    }
    
    // MARK: - Command Handlers
    
    private func handlePlay() {
        playbackController.resume()
    }
    
    private func handlePause() {
        playbackController.pause()
    }
    
    private func handleTogglePlayPause() {
        playbackController.togglePlayPause()
    }
    
    private func handleNextTrack() {
        Task { @MainActor in
            try? await playbackController.next()
        }
    }
    
    private func handlePreviousTrack() {
        Task { @MainActor in
            try? await playbackController.previous()
        }
    }
}
