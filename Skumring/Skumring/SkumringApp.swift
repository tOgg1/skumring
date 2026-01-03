import SwiftUI
import AppKit

@main
struct SkumringApp: App {
    /// The root application model, injected into the SwiftUI environment
    @State private var appModel = AppModel()
    
    /// State for showing import result alert
    @State private var importResult: ImportResult?
    @State private var showImportAlert = false
    
    /// Service for handling media key events
    @State private var mediaKeyService: MediaKeyService?
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
                .environment(appModel.libraryStore)
                .environment(appModel.playbackController)
                .frame(minWidth: 600, minHeight: 400)
                .alert("Import Complete", isPresented: $showImportAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    if let result = importResult {
                        Text(result.summary)
                    }
                }
                .onChange(of: appModel.showImportPicker) { _, newValue in
                    if newValue {
                        appModel.showImportPicker = false
                        importFromFile()
                    }
                }
                .onAppear {
                    setupMediaKeyService()
                }
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1000, height: 700)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Add Item...") {
                    appModel.showAddItemSheet = true
                }
                .keyboardShortcut("l", modifiers: .command)
                
                Divider()
                
                Button("Import...") {
                    importFromFile()
                }
                .keyboardShortcut("i", modifiers: .command)
                
                Button("Export Library...") {
                    exportLibraryToFile()
                }
                .keyboardShortcut("e", modifiers: .command)
            }
            
            // MARK: - Playback Commands
            CommandGroup(after: .toolbar) {
                Button("Play/Pause") {
                    appModel.playbackController.togglePlayPause()
                }
                .keyboardShortcut(.space, modifiers: [])
                
                Button("Next Track") {
                    Task {
                        try? await appModel.playbackController.next()
                    }
                }
                .keyboardShortcut(.rightArrow, modifiers: .command)
                
                Button("Previous Track") {
                    Task {
                        try? await appModel.playbackController.previous()
                    }
                }
                .keyboardShortcut(.leftArrow, modifiers: .command)
            }
        }
    }
    
    // MARK: - Media Key Service
    
    /// Sets up the media key service to handle remote commands
    private func setupMediaKeyService() {
        guard mediaKeyService == nil else { return }
        mediaKeyService = MediaKeyService(playbackController: appModel.playbackController)
        mediaKeyService?.enable()
    }
    
    // MARK: - File Operations
    
    /// Opens a file picker and imports a pack from the selected JSON file
    private func importFromFile() {
        let panel = NSOpenPanel()
        panel.title = "Import Pack"
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        if panel.runModal() == .OK, let url = panel.url {
            let service = ImportExportService(store: appModel.libraryStore)
            do {
                let pack = try service.readPackFromFile(url: url)
                let result = service.importPack(pack: pack)
                importResult = result
                showImportAlert = true
            } catch {
                importResult = ImportResult(
                    itemsImported: 0,
                    itemsUpdated: 0,
                    itemsSkipped: 0,
                    playlistsImported: 0,
                    errors: [error.localizedDescription]
                )
                showImportAlert = true
            }
        }
    }
    
    /// Opens a save panel and exports the entire library as a JSON pack
    private func exportLibraryToFile() {
        let panel = NSSavePanel()
        panel.title = "Export Library"
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "Skumring-Library.json"
        panel.canCreateDirectories = true
        
        if panel.runModal() == .OK, let url = panel.url {
            let service = ImportExportService(store: appModel.libraryStore)
            let pack = service.exportLibrary()
            do {
                try service.writePackToFile(pack: pack, url: url)
            } catch {
                // Show error alert
                let alert = NSAlert()
                alert.messageText = "Export Failed"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }
}
