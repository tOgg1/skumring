import SwiftUI

/// Main content view with NavigationSplitView layout and NowPlayingBar.
///
/// Uses a two-column navigation layout:
/// - Sidebar: SidebarView with navigation destinations
/// - Detail: MainContentView that displays content based on selection
/// - Bottom: NowPlayingBar for playback controls (always visible)
///
/// ## Now Playing Navigation
///
/// When playback starts, the view automatically navigates to the Now Playing view
/// to provide an immersive playback experience. Users can navigate away and return
/// via the sidebar or by clicking the NowPlayingBar.
struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(PlaybackController.self) private var playbackController
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    /// Controls the visibility of the sidebar column
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    
    /// Tracks the previous currentItem to detect when playback starts
    @State private var previousCurrentItem: LibraryItem?
    
    var body: some View {
        @Bindable var appModel = appModel
        
        VStack(spacing: 0) {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                SidebarView()
            } detail: {
                MainContentView()
            }
            .navigationSplitViewStyle(.balanced)
            
            // Now playing bar - always visible at bottom
            // Clicking on it navigates to Now Playing view
            NowPlayingBar()
                .onTapGesture {
                    if playbackController.currentItem != nil {
                        appModel.selectedSidebarItem = .nowPlaying
                    }
                }
        }
        .sheet(isPresented: $appModel.showAddItemSheet) {
            AddItemSheet()
        }
        .onChange(of: playbackController.currentItem?.id) { oldValue, newValue in
            // Auto-navigate to Now Playing when playback starts
            // (when going from nil to a value)
            if oldValue == nil && newValue != nil {
                appModel.selectedSidebarItem = .nowPlaying
            }
        }
        .onChange(of: appModel.isFullscreen) { _, isFullscreen in
            // Handle fullscreen window state changes
            if isFullscreen {
                openWindow(id: "fullscreen-player")
            } else {
                dismissWindow(id: "fullscreen-player")
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppModel())
        .environment(LibraryStore())
        .environment(PlaybackController())
}
