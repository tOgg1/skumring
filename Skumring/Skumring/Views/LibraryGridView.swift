import SwiftUI

/// A grid view for displaying library items using LazyVGrid.
///
/// Displays items in an adaptive grid layout with LibraryItemCard views.
/// Handles selection state and double-click to play.
struct LibraryGridView: View {
    let items: [LibraryItem]
    @Binding var selection: Set<UUID>
    
    /// Called when an item is double-clicked to initiate playback
    var onPlay: ((LibraryItem) -> Void)?
    
    /// Called when the user selects Delete from context menu
    var onDelete: ((LibraryItem) -> Void)?
    
    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 220), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { item in
                    LibraryItemCard(item: item, onPlay: {
                        onPlay?(item)
                    }, onDelete: {
                        onDelete?(item)
                    })
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selection.contains(item.id) ? Color.accentColor.opacity(0.15) : Color.clear)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleTap(item: item)
                    }
                }
            }
            .padding()
        }
    }
    
    private func handleTap(item: LibraryItem) {
        if NSEvent.modifierFlags.contains(.command) {
            // Command-click: toggle selection
            if selection.contains(item.id) {
                selection.remove(item.id)
            } else {
                selection.insert(item.id)
            }
        } else if NSEvent.modifierFlags.contains(.shift) && !selection.isEmpty {
            // Shift-click: range selection (simplified - just add to selection)
            selection.insert(item.id)
        } else {
            // Regular click: single selection
            selection = [item.id]
        }
    }
}

#Preview {
    LibraryGridView(
        items: [
            LibraryItem(
                kind: .stream,
                title: "Lofi Hip Hop Radio",
                subtitle: "ChilledCow",
                source: .fromURL(URL(string: "https://example.com/stream")!)
            ),
            LibraryItem(
                kind: .youtube,
                title: "Study Music",
                subtitle: "Focus Channel",
                source: .fromYouTube("dQw4w9WgXcQ")
            ),
            LibraryItem(
                kind: .audioURL,
                title: "Rain Sounds",
                source: .fromURL(URL(string: "https://example.com/rain.mp3")!)
            )
        ],
        selection: .constant([])
    )
}
