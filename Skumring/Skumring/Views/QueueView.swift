import SwiftUI

/// Popover view displaying the playback queue with "Up Next" items.
///
/// The QueueView shows:
/// - Now Playing: Current item highlighted at the top
/// - Up Next: Upcoming items in playback order
/// - Queue actions: Clear upcoming, reorder via drag-and-drop
///
/// Items can be:
/// - Clicked to jump to that position
/// - Removed via swipe or button
/// - Reordered via drag-and-drop (except the current item)
struct QueueView: View {
    @Environment(PlaybackController.self) private var playbackController
    
    /// Width of the popover
    private let popoverWidth: CGFloat = 320
    
    /// Height of each queue row
    private let rowHeight: CGFloat = 56
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Content
            if playbackController.currentItem == nil && playbackController.queue.isEmpty {
                emptyStateView
            } else {
                queueListView
            }
        }
        .frame(width: popoverWidth)
        .frame(minHeight: 200, maxHeight: 500)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Text("Up Next")
                .font(.headline)
            
            Spacer()
            
            if !playbackController.upcomingItems.isEmpty {
                Button("Clear") {
                    playbackController.clearUpcoming()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.subheadline)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "text.line.first.and.arrowtriangle.forward")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            
            Text("No upcoming items")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("Play a playlist or add items to queue")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Queue List
    
    private var queueListView: some View {
        List {
            // Now Playing section
            if let currentItem = playbackController.currentItem {
                Section {
                    QueueRowView(
                        item: currentItem,
                        isCurrentlyPlaying: true,
                        position: nil,
                        onPlay: nil,
                        onRemove: nil
                    )
                } header: {
                    Text("Now Playing")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Up Next section
            if !playbackController.upcomingItems.isEmpty {
                Section {
                    ForEach(Array(playbackController.upcomingItems.enumerated()), id: \.element.id) { offset, item in
                        QueueRowView(
                            item: item,
                            isCurrentlyPlaying: false,
                            position: offset + 1,
                            onPlay: {
                                // Calculate actual queue index
                                if let currentIndex = playbackController.queueIndex {
                                    let targetIndex = currentIndex + 1 + offset
                                    Task {
                                        try? await playbackController.jumpToQueueIndex(targetIndex)
                                    }
                                }
                            },
                            onRemove: {
                                // Calculate actual queue index
                                if let currentIndex = playbackController.queueIndex {
                                    let targetIndex = currentIndex + 1 + offset
                                    playbackController.removeFromQueue(at: targetIndex)
                                }
                            }
                        )
                    }
                    .onMove { source, destination in
                        // Convert from upcoming indices to queue indices
                        if let currentIndex = playbackController.queueIndex {
                            let baseIndex = currentIndex + 1
                            for sourceIndex in source {
                                let fromQueueIndex = baseIndex + sourceIndex
                                let toQueueIndex = baseIndex + destination
                                playbackController.moveInQueue(from: fromQueueIndex, to: toQueueIndex)
                            }
                        }
                    }
                } header: {
                    Text("Up Next (\(playbackController.upcomingItems.count))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Queue Row View

/// A single row in the queue list showing item info and actions.
struct QueueRowView: View {
    let item: LibraryItem
    let isCurrentlyPlaying: Bool
    let position: Int?
    let onPlay: (() -> Void)?
    let onRemove: (() -> Void)?
    
    /// Artwork thumbnail size
    private let artworkSize: CGFloat = 40
    
    var body: some View {
        HStack(spacing: 12) {
            // Position number or now playing indicator
            positionView
                .frame(width: 24)
            
            // Artwork
            artworkView
            
            // Title and subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(isCurrentlyPlaying ? .semibold : .regular)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    // Source type icon
                    Image(systemName: sourceIcon)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Remove button (for non-current items)
            if !isCurrentlyPlaying, let onRemove = onRemove {
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isCurrentlyPlaying {
                onPlay?()
            }
        }
    }
    
    // MARK: - Position View
    
    @ViewBuilder
    private var positionView: some View {
        if isCurrentlyPlaying {
            // Animated playing indicator
            Image(systemName: "speaker.wave.2.fill")
                .font(.caption)
                .foregroundStyle(Color.accentColor)
        } else if let position = position {
            Text("\(position)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
    
    // MARK: - Artwork View
    
    private var artworkView: some View {
        Group {
            if let artworkURL = item.artworkURL {
                AsyncImage(url: artworkURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        artworkPlaceholder
                    case .empty:
                        ProgressView()
                            .frame(width: artworkSize, height: artworkSize)
                    @unknown default:
                        artworkPlaceholder
                    }
                }
            } else {
                artworkPlaceholder
            }
        }
        .frame(width: artworkSize, height: artworkSize)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    private var artworkPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(.quaternary)
            Image(systemName: "music.note")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
    
    // MARK: - Source Icon
    
    private var sourceIcon: String {
        switch item.kind {
        case .stream:
            return "antenna.radiowaves.left.and.right"
        case .youtube:
            return "play.rectangle.fill"
        case .audioURL:
            return "link"
        }
    }
}

// MARK: - Previews

#Preview("With Items") {
    let controller = PlaybackController()
    return QueueView()
        .environment(controller)
}

#Preview("Empty") {
    QueueView()
        .environment(PlaybackController())
}
