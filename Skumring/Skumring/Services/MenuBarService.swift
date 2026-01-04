import AppKit
import SwiftUI
import Observation

/// Service that manages the menu bar status item and mini-player popover.
///
/// MenuBarService creates an NSStatusItem in the system menu bar that:
/// - Shows the current playback state with appropriate icons
/// - Displays a popover with Now Playing info and controls on click
/// - Provides a right-click context menu for quick actions
///
/// The service can be enabled/disabled via UserDefaults preferences.
///
/// Usage:
/// ```swift
/// let service = MenuBarService(playbackController: controller)
/// service.enable()
/// // ...
/// service.disable()
/// ```
@MainActor
final class MenuBarService: ObservableObject {
    
    // MARK: - Properties
    
    /// The playback controller to observe and control
    private let playbackController: PlaybackController
    
    /// The library store for accessing playlists
    private let libraryStore: LibraryStore
    
    /// The status item in the menu bar
    private var statusItem: NSStatusItem?
    
    /// The popover containing the mini player
    private var popover: NSPopover?
    
    /// Event monitor for clicking outside the popover to dismiss it
    private var eventMonitor: Any?
    
    /// Observation token for playback state changes
    private var observationTask: Task<Void, Never>?
    
    // MARK: - UserDefaults Keys
    
    private enum Defaults {
        static let menuBarEnabled = "menuBarEnabled"
        static let showOnlyWhenPlaying = "menuBarShowOnlyWhenPlaying"
    }
    
    // MARK: - Preferences
    
    /// Whether the menu bar item is enabled
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Defaults.menuBarEnabled) }
        set {
            UserDefaults.standard.set(newValue, forKey: Defaults.menuBarEnabled)
            if newValue {
                setupStatusItem()
            } else {
                teardownStatusItem()
            }
        }
    }
    
    /// Whether to show the menu bar item only when playing
    var showOnlyWhenPlaying: Bool {
        get { UserDefaults.standard.bool(forKey: Defaults.showOnlyWhenPlaying) }
        set {
            UserDefaults.standard.set(newValue, forKey: Defaults.showOnlyWhenPlaying)
            updateVisibility()
        }
    }
    
    // MARK: - Initialization
    
    init(playbackController: PlaybackController, libraryStore: LibraryStore) {
        self.playbackController = playbackController
        self.libraryStore = libraryStore
        
        // Register default values
        UserDefaults.standard.register(defaults: [
            Defaults.menuBarEnabled: true,
            Defaults.showOnlyWhenPlaying: false
        ])
    }
    
    deinit {
        observationTask?.cancel()
    }
    
    // MARK: - Public API
    
    /// Enables the menu bar service if preferences allow
    func enable() {
        guard isEnabled else { return }
        setupStatusItem()
        startObserving()
    }
    
    /// Disables the menu bar service completely
    func disable() {
        stopObserving()
        teardownStatusItem()
    }
    
    /// Toggles the popover visibility
    func togglePopover() {
        if let popover = popover, popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }
    
    // MARK: - Status Item Setup
    
    private func setupStatusItem() {
        guard statusItem == nil else { return }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = iconForState()
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        setupPopover()
        updateVisibility()
    }
    
    private func teardownStatusItem() {
        closePopover()
        
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        statusItem = nil
        popover = nil
    }
    
    // MARK: - Popover Setup
    
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 280, height: 180)
        popover?.behavior = .transient
        popover?.animates = true
        
        // Create the SwiftUI view for the popover
        let contentView = MiniPlayerPopoverView()
            .environment(playbackController)
            .environment(libraryStore)
        
        popover?.contentViewController = NSHostingController(rootView: contentView)
    }
    
    private func showPopover() {
        guard let button = statusItem?.button, let popover = popover else { return }
        
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        
        // Add event monitor to close popover when clicking outside
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }
    
    private func closePopover() {
        popover?.performClose(nil)
        
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
    }
    
    // MARK: - Status Item Actions
    
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }
    
    private func showContextMenu() {
        guard let button = statusItem?.button else { return }
        
        let menu = NSMenu()
        
        // Playback controls
        if playbackController.currentItem != nil {
            let playPauseItem = NSMenuItem(
                title: playbackController.isPlaying ? "Pause" : "Play",
                action: #selector(togglePlayPause),
                keyEquivalent: ""
            )
            playPauseItem.target = self
            menu.addItem(playPauseItem)
            
            let nextItem = NSMenuItem(title: "Next", action: #selector(playNext), keyEquivalent: "")
            nextItem.target = self
            menu.addItem(nextItem)
            
            let prevItem = NSMenuItem(title: "Previous", action: #selector(playPrevious), keyEquivalent: "")
            prevItem.target = self
            menu.addItem(prevItem)
            
            menu.addItem(.separator())
        }
        
        // Playlists submenu
        if !libraryStore.playlists.isEmpty {
            let playlistsMenu = NSMenu()
            for playlist in libraryStore.playlists {
                let item = NSMenuItem(title: playlist.name, action: #selector(playPlaylist(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = playlist.id
                playlistsMenu.addItem(item)
            }
            
            let playlistsItem = NSMenuItem(title: "Playlists", action: nil, keyEquivalent: "")
            playlistsItem.submenu = playlistsMenu
            menu.addItem(playlistsItem)
            
            menu.addItem(.separator())
        }
        
        // Open Skumring
        let openItem = NSMenuItem(title: "Open Skumring", action: #selector(openMainWindow), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)
        
        menu.addItem(.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit Skumring", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
        button.performClick(nil)
        statusItem?.menu = nil
    }
    
    // MARK: - Menu Actions
    
    @objc private func togglePlayPause() {
        playbackController.togglePlayPause()
    }
    
    @objc private func playNext() {
        Task {
            try? await playbackController.next()
        }
    }
    
    @objc private func playPrevious() {
        Task {
            try? await playbackController.previous()
        }
    }
    
    @objc private func playPlaylist(_ sender: NSMenuItem) {
        guard let playlistID = sender.representedObject as? UUID,
              let playlist = libraryStore.playlists.first(where: { $0.id == playlistID }) else {
            return
        }
        
        let items = playlist.itemIDs.compactMap { id in
            libraryStore.items.first { $0.id == id }
        }
        
        guard !items.isEmpty else { return }
        
        Task {
            try? await playbackController.playQueue(items: items, startingAt: 0)
        }
    }
    
    @objc private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        
        // Find and bring the main window to front
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue != "fullscreen-player" }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    // MARK: - State Observation
    
    private func startObserving() {
        observationTask = Task { [weak self] in
            // Poll for state changes
            // Note: In a real implementation, we'd use proper Observation
            // For now, we'll use a polling approach
            while !Task.isCancelled {
                await self?.updateIconAndVisibility()
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }
    
    private func stopObserving() {
        observationTask?.cancel()
        observationTask = nil
    }
    
    private func updateIconAndVisibility() {
        updateIcon()
        updateVisibility()
    }
    
    private func updateIcon() {
        guard let button = statusItem?.button else { return }
        button.image = iconForState()
    }
    
    private func updateVisibility() {
        guard isEnabled else {
            statusItem?.isVisible = false
            return
        }
        
        if showOnlyWhenPlaying {
            statusItem?.isVisible = playbackController.currentItem != nil
        } else {
            statusItem?.isVisible = true
        }
    }
    
    // MARK: - Icon Generation
    
    private func iconForState() -> NSImage? {
        let symbolName: String
        let symbolConfig: NSImage.SymbolConfiguration
        
        if playbackController.currentItem == nil {
            // Nothing playing - dimmed icon
            symbolName = "music.note"
            symbolConfig = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
                .applying(.init(paletteColors: [.tertiaryLabelColor]))
        } else if playbackController.isPlaying {
            // Playing - highlighted icon with animation effect (solid)
            symbolName = "music.note"
            symbolConfig = NSImage.SymbolConfiguration(pointSize: 16, weight: .bold)
                .applying(.init(paletteColors: [.controlAccentColor]))
        } else {
            // Paused - normal icon
            symbolName = "music.note"
            symbolConfig = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
                .applying(.init(paletteColors: [.labelColor]))
        }
        
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Skumring")
        return image?.withSymbolConfiguration(symbolConfig)
    }
}
