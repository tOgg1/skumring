import SwiftUI

/// Main content view with NavigationSplitView layout.
///
/// Uses a two-column navigation layout:
/// - Sidebar: SidebarView with navigation destinations
/// - Detail: MainContentView that displays content based on selection
struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    
    /// Controls the visibility of the sidebar column
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
        } detail: {
            MainContentView()
        }
        .navigationSplitViewStyle(.balanced)
    }
}

#Preview {
    ContentView()
        .environment(AppModel())
        .environment(LibraryStore())
        .environment(PlaybackController())
}
