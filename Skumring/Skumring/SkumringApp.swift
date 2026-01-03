import SwiftUI

@main
struct SkumringApp: App {
    /// The root application model, injected into the SwiftUI environment
    @State private var appModel = AppModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 800, height: 600)
    }
}
