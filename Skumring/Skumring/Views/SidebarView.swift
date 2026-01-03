import SwiftUI

/// The main sidebar navigation view for the app.
///
/// Displays a hierarchical list of navigation destinations organized into sections:
/// - Home: Quick access to main view
/// - Built-in Pack: Curated content
/// - Library: All items, filtered by type
/// - Playlists: User-created playlists
struct SidebarView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(LibraryStore.self) private var libraryStore
    
    var body: some View {
        @Bindable var appModel = appModel
        
        List(selection: $appModel.selectedSidebarItem) {
            // MARK: - Home Section
            Section("Home") {
                Label("Focus Now", systemImage: "house")
                    .tag(SidebarItem.home)
            }
            
            // MARK: - Built-in Pack Section
            Section("Built-in Pack") {
                Label("Curated Stations", systemImage: "star")
                    .tag(SidebarItem.builtInPack)
            }
            
            // MARK: - Library Section
            Section("Library") {
                Label("All Items", systemImage: "music.note.list")
                    .tag(SidebarItem.allItems)
                
                Label("Streams", systemImage: "antenna.radiowaves.left.and.right")
                    .tag(SidebarItem.streams)
                
                Label("YouTube", systemImage: "play.rectangle")
                    .tag(SidebarItem.youtube)
                
                Label("Audio URLs", systemImage: "link")
                    .tag(SidebarItem.audioURLs)
                
                Label("Imports", systemImage: "square.and.arrow.down")
                    .tag(SidebarItem.imports)
            }
            
            // MARK: - Playlists Section
            Section("Playlists") {
                ForEach(libraryStore.playlists) { playlist in
                    Label(playlist.name, systemImage: "music.note.list")
                        .tag(SidebarItem.playlist(playlist.id))
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Skumring")
        .safeAreaInset(edge: .bottom) {
            sidebarFooter
        }
    }
    
    // MARK: - Sidebar Footer
    
    /// Footer view with Add Playlist button
    private var sidebarFooter: some View {
        HStack {
            Button(action: addPlaylist) {
                Label("New Playlist", systemImage: "plus")
            }
            .buttonStyle(.borderless)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
    
    /// Creates a new playlist with a default name
    private func addPlaylist() {
        let playlistNumber = libraryStore.playlists.count + 1
        let newPlaylist = Playlist(name: "Playlist \(playlistNumber)")
        libraryStore.addPlaylist(newPlaylist)
        
        // Select the newly created playlist
        appModel.selectedSidebarItem = .playlist(newPlaylist.id)
    }
}

#Preview {
    SidebarView()
        .environment(AppModel())
        .environment(LibraryStore())
}
