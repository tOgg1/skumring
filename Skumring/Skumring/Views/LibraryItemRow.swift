import SwiftUI

/// A compact row view for displaying a library item in a list layout.
///
/// Shows a small artwork thumbnail, title, subtitle, type indicator,
/// and optional tags. Designed for use in List views.
struct LibraryItemRow: View {
    let item: LibraryItem
    
    /// Called when the item is double-clicked to initiate playback
    var onPlay: (() -> Void)?
    
    /// Called when the user selects Delete from context menu
    var onDelete: (() -> Void)?
    
    /// Called when the user selects Edit from context menu
    var onEdit: (() -> Void)?
    
    /// Called when the user selects a playlist to add the item to
    var onAddToPlaylist: ((Playlist) -> Void)?
    
    /// Available playlists for the "Add to Playlist" submenu
    var playlists: [Playlist] = []
    
    private let artworkSize: CGFloat = 44
    
    var body: some View {
        HStack(spacing: 12) {
            artworkView
            textContent
            Spacer()
            typeIndicator
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onPlay?()
        }
        .contextMenu {
            contextMenuContent
        }
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private var contextMenuContent: some View {
        Button {
            onPlay?()
        } label: {
            Label("Play", systemImage: "play.fill")
        }
        
        Divider()
        
        if !playlists.isEmpty {
            Menu {
                ForEach(playlists) { playlist in
                    Button(playlist.name) {
                        onAddToPlaylist?(playlist)
                    }
                }
            } label: {
                Label("Add to Playlist", systemImage: "text.badge.plus")
            }
        }
        
        Button {
            onEdit?()
        } label: {
            Label("Edit...", systemImage: "pencil")
        }
        
        Divider()
        
        Button(role: .destructive) {
            onDelete?()
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    // MARK: - Artwork
    
    @ViewBuilder
    private var artworkView: some View {
        if let artworkURL = item.artworkURL {
            AsyncImage(url: artworkURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholderArtwork
                case .empty:
                    ProgressView()
                        .frame(width: artworkSize, height: artworkSize)
                        .background(Color.secondary.opacity(0.1))
                @unknown default:
                    placeholderArtwork
                }
            }
            .frame(width: artworkSize, height: artworkSize)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            placeholderArtwork
        }
    }
    
    private var placeholderArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.15))
            
            Image(systemName: placeholderIcon)
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
        }
        .frame(width: artworkSize, height: artworkSize)
    }
    
    private var placeholderIcon: String {
        switch item.kind {
        case .stream:
            return "antenna.radiowaves.left.and.right"
        case .youtube:
            return "play.rectangle.fill"
        case .audioURL:
            return "waveform"
        }
    }
    
    // MARK: - Text Content
    
    private var textContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.title)
                .font(.body)
                .lineLimit(1)
                .truncationMode(.tail)
            
            HStack(spacing: 6) {
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                
                if !item.tags.isEmpty {
                    tagsView
                }
            }
        }
    }
    
    // MARK: - Tags
    
    private var tagsView: some View {
        HStack(spacing: 4) {
            ForEach(item.tags.prefix(2), id: \.self) { tag in
                Text(tag)
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            if item.tags.count > 2 {
                Text("+\(item.tags.count - 2)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Type Indicator
    
    private var typeIndicator: some View {
        Image(systemName: typeIcon)
            .font(.caption)
            .foregroundStyle(typeColor)
    }
    
    private var typeIcon: String {
        switch item.kind {
        case .stream: return "antenna.radiowaves.left.and.right"
        case .youtube: return "play.rectangle.fill"
        case .audioURL: return "waveform"
        }
    }
    
    private var typeColor: Color {
        switch item.kind {
        case .stream: return .orange
        case .youtube: return .red
        case .audioURL: return .blue
        }
    }
}

#Preview("Stream Item") {
    List {
        LibraryItemRow(
            item: LibraryItem(
                kind: .stream,
                title: "Lofi Hip Hop Radio - Beats to Relax/Study To",
                subtitle: "ChilledCow",
                source: .fromURL(URL(string: "https://example.com/stream")!),
                tags: ["focus", "lofi", "chill"]
            )
        )
    }
}

#Preview("YouTube Item") {
    List {
        LibraryItemRow(
            item: LibraryItem(
                kind: .youtube,
                title: "Short Title",
                subtitle: "Channel Name",
                source: .fromYouTube("dQw4w9WgXcQ")
            )
        )
    }
}

#Preview("Audio URL Item") {
    List {
        LibraryItemRow(
            item: LibraryItem(
                kind: .audioURL,
                title: "Ambient Sounds - Nature and Rain",
                source: .fromURL(URL(string: "https://example.com/audio.mp3")!)
            )
        )
    }
}
