import SwiftUI

/// Sheet for adding new items to the library.
///
/// Provides a form for entering:
/// - URL (stream, YouTube, or audio file)
/// - Auto-detected item type based on URL
/// - Title for the item
/// - Optional tags for organization
///
/// Usage:
/// ```swift
/// .sheet(isPresented: $showAddSheet) {
///     AddItemSheet()
/// }
/// ```
struct AddItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LibraryStore.self) private var libraryStore
    
    @State private var urlString: String = ""
    @State private var title: String = ""
    @State private var tagsString: String = ""
    @State private var detectedKind: LibraryItemKind?
    @State private var detectedYouTubeID: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            sheetHeader
            
            Divider()
            
            // Form content
            Form {
                urlSection
                detailsSection
            }
            .formStyle(.grouped)
            
            Divider()
            
            // Footer with buttons
            sheetFooter
        }
        .frame(width: 400, height: 380)
        .accessibilityIdentifier("addItemSheet")
    }
    
    // MARK: - Header
    
    /// Sheet header with glass styling.
    ///
    /// Uses Liquid Glass for a modern appearance on macOS 26+.
    /// Falls back to solid styling when Reduce Transparency is enabled.
    private var sheetHeader: some View {
        HStack {
            Text("Add Item")
                .font(.headline)
            Spacer()
        }
        .padding()
        .glassStyleFullBleed()
    }
    
    // MARK: - URL Section
    
    private var urlSection: some View {
        Section {
            TextField("URL", text: $urlString, prompt: Text("https://..."))
                .textFieldStyle(.plain)
                .accessibilityIdentifier("addItemSheet.url")
                .onChange(of: urlString) { _, newValue in
                    detectItemType(from: newValue)
                }
            
            if let detectedKind {
                HStack {
                    Image(systemName: iconForKind(detectedKind))
                        .foregroundStyle(.secondary)
                    Text(labelForKind(detectedKind))
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .accessibilityIdentifier("addItemSheet.detectedKind")
                    Spacer()
                }
            }
        } header: {
            Text("Source")
        }
    }
    
    // MARK: - Details Section
    
    private var detailsSection: some View {
        Section {
            TextField("Title", text: $title, prompt: Text("Item title"))
                .textFieldStyle(.plain)
                .accessibilityIdentifier("addItemSheet.title")
            
            TextField("Tags", text: $tagsString, prompt: Text("lofi, chill, focus (optional)"))
                .textFieldStyle(.plain)
                .accessibilityIdentifier("addItemSheet.tags")
        } header: {
            Text("Details")
        } footer: {
            Text("Separate tags with commas")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Footer
    
    /// Sheet footer with glass styling and action buttons.
    ///
    /// Uses Liquid Glass for a modern appearance on macOS 26+.
    /// Falls back to solid styling when Reduce Transparency is enabled.
    private var sheetFooter: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
            .accessibilityIdentifier("addItemSheet.cancel")
            
            Spacer()
            
            Button("Add") {
                addItem()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(!canAdd)
            .accessibilityIdentifier("addItemSheet.add")
        }
        .padding()
        .glassStyleFullBleed()
    }
    
    // MARK: - Validation
    
    /// Whether the current input is valid for adding
    private var canAdd: Bool {
        guard !urlString.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }
        guard detectedKind != nil else {
            return false
        }
        return true
    }
    
    // MARK: - Type Detection
    
    /// Detects the item type from the URL string.
    ///
    /// Sets `detectedKind` and `detectedYouTubeID` based on URL patterns.
    private func detectItemType(from urlString: String) {
        let trimmed = urlString.trimmingCharacters(in: .whitespaces)
        let lowercased = trimmed.lowercased()
        
        // Reset detection
        detectedKind = nil
        detectedYouTubeID = nil
        
        guard !trimmed.isEmpty else { return }
        
        // YouTube detection - use original trimmed string to preserve case-sensitive video ID
        if let youtubeID = extractYouTubeID(from: trimmed) {
            detectedKind = .youtube
            detectedYouTubeID = youtubeID
            return
        }
        
        // Stream detection (playlist files) - use lowercased for extension matching
        let streamExtensions = [".m3u", ".m3u8", ".pls"]
        if streamExtensions.contains(where: { lowercased.contains($0) }) {
            detectedKind = .stream
            return
        }
        
        // Audio URL detection - use lowercased for extension matching
        let audioExtensions = [".mp3", ".aac", ".m4a", ".wav", ".flac", ".ogg"]
        if audioExtensions.contains(where: { lowercased.hasSuffix($0) }) {
            detectedKind = .audioURL
            return
        }
        
        // Default to stream for other URLs that look valid
        if lowercased.hasPrefix("http://") || lowercased.hasPrefix("https://") {
            detectedKind = .stream
        }
    }
    
    /// Extracts YouTube video ID from various URL formats.
    ///
    /// Supports:
    /// - youtube.com/watch?v=VIDEO_ID
    /// - youtu.be/VIDEO_ID
    /// - youtube.com/embed/VIDEO_ID
    ///
    /// Note: YouTube video IDs are case-sensitive, so this function preserves
    /// the original case from the URL.
    private func extractYouTubeID(from urlString: String) -> String? {
        // Check if it's a YouTube URL (case-insensitive check for domain)
        let lowercased = urlString.lowercased()
        let youtubePatterns = ["youtube.com", "youtu.be"]
        guard youtubePatterns.contains(where: { lowercased.contains($0) }) else {
            return nil
        }
        
        // youtu.be/VIDEO_ID format (case-insensitive search, case-preserving extraction)
        if let range = urlString.range(of: "youtu.be/", options: .caseInsensitive) {
            let afterSlash = urlString[range.upperBound...]
            let videoID = afterSlash.prefix(while: { $0 != "?" && $0 != "&" && $0 != "/" })
            if !videoID.isEmpty {
                return String(videoID)
            }
        }
        
        // youtube.com/watch?v=VIDEO_ID format (case-insensitive search, case-preserving extraction)
        if lowercased.contains("watch") {
            if let range = urlString.range(of: "v=", options: .caseInsensitive) {
                let afterV = urlString[range.upperBound...]
                let videoID = afterV.prefix(while: { $0 != "&" && $0 != "/" })
                if !videoID.isEmpty {
                    return String(videoID)
                }
            }
        }
        
        // youtube.com/embed/VIDEO_ID format (case-insensitive search, case-preserving extraction)
        if let range = urlString.range(of: "/embed/", options: .caseInsensitive) {
            let afterEmbed = urlString[range.upperBound...]
            let videoID = afterEmbed.prefix(while: { $0 != "?" && $0 != "&" && $0 != "/" })
            if !videoID.isEmpty {
                return String(videoID)
            }
        }
        
        return nil
    }
    
    // MARK: - Kind Helpers
    
    private func iconForKind(_ kind: LibraryItemKind) -> String {
        switch kind {
        case .stream: return "antenna.radiowaves.left.and.right"
        case .youtube: return "play.rectangle"
        case .audioURL: return "link"
        }
    }
    
    private func labelForKind(_ kind: LibraryItemKind) -> String {
        switch kind {
        case .stream: return "Stream"
        case .youtube: return "YouTube Video"
        case .audioURL: return "Audio File"
        }
    }
    
    // MARK: - Actions
    
    /// Creates and adds the library item, then dismisses the sheet.
    private func addItem() {
        guard let detectedKind else { return }
        
        // Parse tags from comma-separated string
        let tags = tagsString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        // Create source based on type
        let source: LibraryItemSource
        if detectedKind == .youtube, let youtubeID = detectedYouTubeID {
            source = .fromYouTube(youtubeID)
        } else if let url = URL(string: urlString.trimmingCharacters(in: .whitespaces)) {
            source = .fromURL(url)
        } else {
            // Should not happen if validation is correct
            return
        }
        
        // Create the item
        let item = LibraryItem(
            kind: detectedKind,
            title: title.trimmingCharacters(in: .whitespaces),
            source: source,
            tags: tags
        )
        
        // Add to library
        libraryStore.addItem(item)
        
        // Save and dismiss
        try? libraryStore.save()
        dismiss()
    }
}

#Preview {
    AddItemSheet()
        .environment(LibraryStore())
}

#Preview("With YouTube URL") {
    AddItemSheet()
        .environment(LibraryStore())
        .onAppear {
            // Note: State changes in previews require @State wrapper in preview
        }
}
