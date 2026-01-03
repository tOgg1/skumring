import SwiftUI

/// A card view for displaying a library item in a grid layout.
///
/// Shows artwork (or a placeholder), title (limited to 2 lines), subtitle,
/// and a type badge. Fixed size of approximately 180x200 points.
struct LibraryItemCard: View {
    let item: LibraryItem
    
    /// Called when the item is double-clicked to initiate playback
    var onPlay: (() -> Void)?
    
    private let cardWidth: CGFloat = 180
    private let artworkSize: CGFloat = 160
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            artworkView
            textContent
        }
        .frame(width: cardWidth)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onPlay?()
        }
    }
    
    // MARK: - Artwork
    
    @ViewBuilder
    private var artworkView: some View {
        ZStack(alignment: .bottomTrailing) {
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
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.secondary.opacity(0.1))
                    @unknown default:
                        placeholderArtwork
                    }
                }
                .frame(width: artworkSize, height: artworkSize)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                placeholderArtwork
            }
            
            // Type badge
            typeBadge
                .padding(6)
        }
    }
    
    private var placeholderArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.15))
            
            Image(systemName: placeholderIcon)
                .font(.system(size: 40))
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
    
    // MARK: - Type Badge
    
    private var typeBadge: some View {
        Text(badgeText)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.9))
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
    
    private var badgeText: String {
        switch item.kind {
        case .stream: return "STREAM"
        case .youtube: return "YT"
        case .audioURL: return "AUDIO"
        }
    }
    
    private var badgeColor: Color {
        switch item.kind {
        case .stream: return .orange
        case .youtube: return .red
        case .audioURL: return .blue
        }
    }
    
    // MARK: - Text Content
    
    private var textContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
                .truncationMode(.tail)
            
            if let subtitle = item.subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Stream Item") {
    LibraryItemCard(
        item: LibraryItem(
            kind: .stream,
            title: "Lofi Hip Hop Radio - Beats to Relax/Study To",
            subtitle: "ChilledCow",
            source: .fromURL(URL(string: "https://example.com/stream")!)
        )
    )
    .padding()
}

#Preview("YouTube Item") {
    LibraryItemCard(
        item: LibraryItem(
            kind: .youtube,
            title: "Short Title",
            subtitle: "Channel Name",
            source: .fromYouTube("dQw4w9WgXcQ")
        )
    )
    .padding()
}

#Preview("Audio URL Item") {
    LibraryItemCard(
        item: LibraryItem(
            kind: .audioURL,
            title: "Ambient Sounds",
            source: .fromURL(URL(string: "https://example.com/audio.mp3")!)
        )
    )
    .padding()
}
