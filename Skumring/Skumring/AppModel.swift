import Foundation
import Observation

/// Central state container for the Skumring app.
///
/// AppModel is the root observable object injected into the SwiftUI environment.
/// It holds references to all major subsystems: LibraryStore, PlaybackController,
/// and UI navigation state.
///
/// Usage:
/// ```swift
/// @State private var appModel = AppModel()
/// // ...
/// ContentView()
///     .environment(appModel)
/// ```
@Observable
final class AppModel {
    
    // MARK: - Initialization
    
    init() {
        // Future: Initialize LibraryStore, PlaybackController here
    }
}
