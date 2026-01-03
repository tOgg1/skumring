import SwiftUI

/// Main content view with NavigationSplitView layout and NowPlayingBar.
///
/// Uses a two-column navigation layout:
/// - Sidebar: SidebarView with navigation destinations
/// - Detail: MainContentView that displays content based on selection
/// - Bottom: NowPlayingBar for playback controls (always visible)
struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    
    /// Controls the visibility of the sidebar column
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    
    var body: some View {
        VStack(spacing: 0) {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                SidebarView()
            } detail: {
                MainContentView()
            }
            .navigationSplitViewStyle(.balanced)
            
            // Now playing bar - always visible at bottom
            NowPlayingBar()
        }
    }
}

#Preview {
    ContentView()
        .environment(AppModel())
        .environment(LibraryStore())
        .environment(PlaybackController())
}
