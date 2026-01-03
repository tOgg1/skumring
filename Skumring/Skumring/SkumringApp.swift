import SwiftUI

@main
struct SkumringApp: App {
    /// The root application model, injected into the SwiftUI environment
    @State private var appModel = AppModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
                .environment(appModel.libraryStore)
                .environment(appModel.playbackController)
                .frame(minWidth: 600, minHeight: 400)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1000, height: 700)
    }
}
