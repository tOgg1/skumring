import SwiftUI

/// Main content view with NavigationSplitView layout and NowPlayingBar.
///
/// Uses a two-column navigation layout:
/// - Sidebar: SidebarView with navigation destinations
/// - Detail: MainContentView that displays content based on selection
/// - YouTube player: Appears above NowPlayingBar when playing YouTube content
/// - Bottom: NowPlayingBar for playback controls (always visible)
struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(PlaybackController.self) private var playbackController
    
    /// Controls the visibility of the sidebar column
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    
    /// YouTube player instance (temporary until integrated into PlaybackController)
    @State private var youtubePlayer = YouTubePlayer()
    
    /// Whether the YouTube player container is visible
    private var showYouTubePlayer: Bool {
        playbackController.currentItem?.kind == .youtube
    }
    
    var body: some View {
        @Bindable var appModel = appModel
        
        VStack(spacing: 0) {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                SidebarView()
            } detail: {
                MainContentView()
            }
            .navigationSplitViewStyle(.balanced)
            
            // YouTube player container - shown when playing YouTube content
            if showYouTubePlayer {
                YouTubePlayerContainerView(
                    player: youtubePlayer,
                    title: playbackController.currentItem?.title,
                    onClose: {
                        playbackController.stop()
                    }
                )
                .frame(height: 360)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            }
            
            // Now playing bar - always visible at bottom
            NowPlayingBar()
        }
        .animation(.easeInOut(duration: 0.3), value: showYouTubePlayer)
        .sheet(isPresented: $appModel.showAddItemSheet) {
            AddItemSheet()
        }
    }
}

#Preview {
    ContentView()
        .environment(AppModel())
        .environment(LibraryStore())
        .environment(PlaybackController())
}
