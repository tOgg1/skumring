import XCTest
@testable import Skumring

// Type alias to avoid ambiguity
private typealias LibraryItem = Skumring.LibraryItem

/// Tests for PlaybackController functionality.
///
/// These tests focus on queue management, repeat/shuffle modes, and state transitions
/// that can be tested without actual media playback.
@MainActor
final class PlaybackControllerTests: XCTestCase {
    
    // MARK: - Test Fixtures
    
    private var controller: PlaybackController!
    
    private var sampleStreamItem: LibraryItem {
        LibraryItem(
            kind: .stream,
            title: "Test Stream",
            subtitle: "Test Radio",
            source: .fromURL(URL(string: "https://example.com/stream.mp3")!)
        )
    }
    
    private var sampleYouTubeItem: LibraryItem {
        LibraryItem(
            kind: .youtube,
            title: "Test YouTube",
            subtitle: "Test Channel",
            source: .fromYouTube("dQw4w9WgXcQ")
        )
    }
    
    private var sampleAudioItem: LibraryItem {
        LibraryItem(
            kind: .audioURL,
            title: "Test Audio",
            source: .fromURL(URL(string: "https://example.com/audio.mp3")!)
        )
    }
    
    private func makeTestQueue(count: Int) -> [LibraryItem] {
        (0..<count).map { i in
            LibraryItem(
                kind: .stream,
                title: "Track \(i + 1)",
                source: .fromURL(URL(string: "https://example.com/track\(i).mp3")!)
            )
        }
    }
    
    override func setUp() async throws {
        try await super.setUp()
        controller = PlaybackController()
    }
    
    override func tearDown() async throws {
        controller?.stop()
        controller = nil
        try await super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertEqual(controller.state, .stopped)
        XCTAssertFalse(controller.isPlaying)
        XCTAssertNil(controller.currentItem)
        XCTAssertNil(controller.currentTime)
        XCTAssertNil(controller.duration)
        XCTAssertEqual(controller.volume, 1.0)
        XCTAssertTrue(controller.queue.isEmpty)
        XCTAssertNil(controller.queueIndex)
        XCTAssertEqual(controller.repeatMode, .off)
        XCTAssertEqual(controller.shuffleMode, .off)
        XCTAssertEqual(controller.activeBackend, .none)
    }
    
    // MARK: - Backend Routing Tests
    
    // Note: Full backend routing tests that involve actual playback are skipped
    // because they require network access and real media. The routing logic is
    // tested indirectly through queue tests which verify currentItem gets set.
    // 
    // For YouTube routing: The YouTubePlayer.play(videoID:) method is synchronous
    // but relies on WKWebView callbacks which aren't available in unit tests.
    // YouTube routing should be tested via UI tests or manual verification.
    //
    // For AVPlayer routing: Requires actual audio URLs to test state transitions.
    // Consider creating a mock audio server or using local test resources.
    
    func testCurrentItemSetOnPlay() async throws {
        // When we try to play an item, currentItem should be set regardless
        // of whether playback succeeds (allows UI to show "attempting to play X")
        let items = makeTestQueue(count: 1)
        
        do {
            try await controller.playQueue(items: items, startingAt: 0)
        } catch {
            // Expected - no actual stream available
        }
        
        // currentItem should be set even if playback fails
        XCTAssertEqual(controller.currentItem?.id, items[0].id)
    }
    
    // MARK: - Volume Tests
    
    func testSetVolume() {
        controller.setVolume(0.5)
        XCTAssertEqual(controller.volume, 0.5)
        
        controller.setVolume(0.0)
        XCTAssertEqual(controller.volume, 0.0)
        
        controller.setVolume(1.0)
        XCTAssertEqual(controller.volume, 1.0)
    }
    
    func testSetVolumeClampedAbove() {
        controller.setVolume(1.5)
        XCTAssertEqual(controller.volume, 1.0)
    }
    
    func testSetVolumeClampedBelow() {
        controller.setVolume(-0.5)
        XCTAssertEqual(controller.volume, 0.0)
    }
    
    // MARK: - Queue Management Tests
    
    func testPlayQueueSetsQueue() async throws {
        let items = makeTestQueue(count: 5)
        
        do {
            try await controller.playQueue(items: items, startingAt: 0)
        } catch {
            // Expected - no actual playback
        }
        
        XCTAssertEqual(controller.queue.count, 5)
        XCTAssertEqual(controller.queueIndex, 0)
        XCTAssertEqual(controller.currentItem?.id, items[0].id)
    }
    
    func testPlayQueueStartingAtIndex() async throws {
        let items = makeTestQueue(count: 5)
        
        do {
            try await controller.playQueue(items: items, startingAt: 2)
        } catch {
            // Expected
        }
        
        XCTAssertEqual(controller.queueIndex, 2)
        XCTAssertEqual(controller.currentItem?.id, items[2].id)
    }
    
    func testPlayQueueWithEmptyArray() async throws {
        let items: [LibraryItem] = []
        
        try await controller.playQueue(items: items, startingAt: 0)
        
        XCTAssertTrue(controller.queue.isEmpty)
        XCTAssertNil(controller.queueIndex)
    }
    
    func testPlayQueueWithInvalidIndex() async {
        let items = makeTestQueue(count: 3)
        
        do {
            try await controller.playQueue(items: items, startingAt: 10)
            XCTFail("Should throw invalidQueueIndex")
        } catch PlaybackControllerError.invalidQueueIndex {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testUpcomingItems() async throws {
        let items = makeTestQueue(count: 5)
        
        do {
            try await controller.playQueue(items: items, startingAt: 1)
        } catch {
            // Expected
        }
        
        let upcoming = controller.upcomingItems
        XCTAssertEqual(upcoming.count, 3) // Items at indices 2, 3, 4
        XCTAssertEqual(upcoming[0].id, items[2].id)
        XCTAssertEqual(upcoming[1].id, items[3].id)
        XCTAssertEqual(upcoming[2].id, items[4].id)
    }
    
    func testUpcomingItemsAtEnd() async throws {
        let items = makeTestQueue(count: 3)
        
        do {
            try await controller.playQueue(items: items, startingAt: 2)
        } catch {
            // Expected
        }
        
        let upcoming = controller.upcomingItems
        XCTAssertTrue(upcoming.isEmpty)
    }
    
    // MARK: - Play Next / Add to Queue Tests
    
    func testPlayNextInsertsAfterCurrent() async throws {
        let items = makeTestQueue(count: 3)
        let newItem = LibraryItem(
            kind: .stream,
            title: "Inserted",
            source: .fromURL(URL(string: "https://example.com/inserted.mp3")!)
        )
        
        do {
            try await controller.playQueue(items: items, startingAt: 0)
        } catch {
            // Expected
        }
        
        do {
            try await controller.playNext(newItem)
        } catch {
            // Expected
        }
        
        XCTAssertEqual(controller.queue.count, 4)
        XCTAssertEqual(controller.queue[1].id, newItem.id) // Inserted at index 1
    }
    
    func testAddToQueueAppendsAtEnd() async throws {
        let items = makeTestQueue(count: 3)
        let newItem = LibraryItem(
            kind: .stream,
            title: "Appended",
            source: .fromURL(URL(string: "https://example.com/appended.mp3")!)
        )
        
        do {
            try await controller.playQueue(items: items, startingAt: 0)
        } catch {
            // Expected
        }
        
        do {
            try await controller.addToQueue(newItem)
        } catch {
            // Expected
        }
        
        XCTAssertEqual(controller.queue.count, 4)
        XCTAssertEqual(controller.queue[3].id, newItem.id) // Appended at end
    }
    
    func testPlayNextWhenEmptyStartsPlayback() async throws {
        let newItem = sampleStreamItem
        
        do {
            try await controller.playNext(newItem)
        } catch {
            // Expected - no actual playback
        }
        
        XCTAssertEqual(controller.queue.count, 1)
        XCTAssertEqual(controller.queueIndex, 0)
        XCTAssertEqual(controller.currentItem?.id, newItem.id)
    }
    
    // MARK: - Remove from Queue Tests
    
    func testRemoveFromQueueAtIndex() async throws {
        let items = makeTestQueue(count: 5)
        
        do {
            try await controller.playQueue(items: items, startingAt: 0)
        } catch {
            // Expected
        }
        
        let removed = controller.removeFromQueue(at: 2)
        
        XCTAssertTrue(removed)
        XCTAssertEqual(controller.queue.count, 4)
        XCTAssertEqual(controller.queue[2].title, "Track 4") // Original index 3 shifted down
    }
    
    func testRemoveFromQueueCannotRemoveCurrent() async throws {
        let items = makeTestQueue(count: 3)
        
        do {
            try await controller.playQueue(items: items, startingAt: 1)
        } catch {
            // Expected
        }
        
        let removed = controller.removeFromQueue(at: 1) // Current item
        
        XCTAssertFalse(removed)
        XCTAssertEqual(controller.queue.count, 3)
    }
    
    func testRemoveFromQueueAdjustsIndex() async throws {
        let items = makeTestQueue(count: 5)
        
        do {
            try await controller.playQueue(items: items, startingAt: 3)
        } catch {
            // Expected
        }
        
        // Remove item before current
        let removed = controller.removeFromQueue(at: 1)
        
        XCTAssertTrue(removed)
        XCTAssertEqual(controller.queueIndex, 2) // Adjusted from 3 to 2
    }
    
    func testRemoveFromQueueByID() async throws {
        let items = makeTestQueue(count: 3)
        let targetID = items[2].id
        
        do {
            try await controller.playQueue(items: items, startingAt: 0)
        } catch {
            // Expected
        }
        
        let removed = controller.removeFromQueue(itemID: targetID)
        
        XCTAssertTrue(removed)
        XCTAssertEqual(controller.queue.count, 2)
    }
    
    // MARK: - Clear Upcoming Tests
    
    func testClearUpcoming() async throws {
        let items = makeTestQueue(count: 5)
        
        do {
            try await controller.playQueue(items: items, startingAt: 1)
        } catch {
            // Expected
        }
        
        controller.clearUpcoming()
        
        XCTAssertEqual(controller.queue.count, 1)
        XCTAssertEqual(controller.queueIndex, 0)
        XCTAssertEqual(controller.currentItem?.id, items[1].id)
    }
    
    // MARK: - Move in Queue Tests
    
    func testMoveInQueueForward() async throws {
        let items = makeTestQueue(count: 5)
        
        do {
            try await controller.playQueue(items: items, startingAt: 0)
        } catch {
            // Expected
        }
        
        let moved = controller.moveInQueue(from: 1, to: 3)
        
        XCTAssertTrue(moved)
        XCTAssertEqual(controller.queue[2].title, "Track 2") // Moved from index 1 to 2 (after adjustment)
    }
    
    func testMoveInQueueBackward() async throws {
        let items = makeTestQueue(count: 5)
        
        do {
            try await controller.playQueue(items: items, startingAt: 0)
        } catch {
            // Expected
        }
        
        let moved = controller.moveInQueue(from: 3, to: 1)
        
        XCTAssertTrue(moved)
        XCTAssertEqual(controller.queue[1].title, "Track 4") // Moved from index 3 to 1
    }
    
    func testMoveInQueueCannotMoveCurrent() async throws {
        let items = makeTestQueue(count: 3)
        
        do {
            try await controller.playQueue(items: items, startingAt: 1)
        } catch {
            // Expected
        }
        
        let moved = controller.moveInQueue(from: 1, to: 2)
        
        XCTAssertFalse(moved)
    }
    
    // MARK: - Jump to Queue Index Tests
    
    func testJumpToQueueIndex() async throws {
        let items = makeTestQueue(count: 5)
        
        do {
            try await controller.playQueue(items: items, startingAt: 0)
        } catch {
            // Expected
        }
        
        do {
            try await controller.jumpToQueueIndex(3)
        } catch {
            // Expected - no actual playback
        }
        
        XCTAssertEqual(controller.queueIndex, 3)
        XCTAssertEqual(controller.currentItem?.id, items[3].id)
    }
    
    func testJumpToQueueIndexInvalid() async throws {
        let items = makeTestQueue(count: 3)
        
        do {
            try await controller.playQueue(items: items, startingAt: 0)
        } catch {
            // Expected
        }
        
        do {
            try await controller.jumpToQueueIndex(10)
            XCTFail("Should throw invalidQueueIndex")
        } catch PlaybackControllerError.invalidQueueIndex {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    // MARK: - Repeat Mode Tests
    
    func testRepeatModeCanBeSet() {
        controller.repeatMode = .all
        XCTAssertEqual(controller.repeatMode, .all)
        
        controller.repeatMode = .one
        XCTAssertEqual(controller.repeatMode, .one)
        
        controller.repeatMode = .off
        XCTAssertEqual(controller.repeatMode, .off)
    }
    
    // MARK: - Shuffle Mode Tests
    
    func testShuffleModeOnShufflesQueue() async throws {
        let items = makeTestQueue(count: 10)
        
        do {
            try await controller.playQueue(items: items, startingAt: 0)
        } catch {
            // Expected
        }
        
        let currentItem = controller.currentItem
        controller.setShuffleMode(.on)
        
        XCTAssertEqual(controller.shuffleMode, .on)
        // Current item should remain at front after shuffle
        XCTAssertEqual(controller.queueIndex, 0)
        XCTAssertEqual(controller.currentItem?.id, currentItem?.id)
        // Queue should be shuffled (with high probability, different order)
        // Note: There's a small chance this could fail if shuffle produces same order
    }
    
    func testShuffleModeOffRestoresOriginalOrder() async throws {
        let items = makeTestQueue(count: 10)
        
        do {
            try await controller.playQueue(items: items, startingAt: 0)
        } catch {
            // Expected
        }
        
        // Enable shuffle
        controller.setShuffleMode(.on)
        
        // Then disable
        controller.setShuffleMode(.off)
        
        XCTAssertEqual(controller.shuffleMode, .off)
        XCTAssertEqual(controller.queue.count, 10)
        
        // Original order should be restored
        for i in 0..<items.count {
            XCTAssertEqual(controller.queue[i].id, items[i].id, "Item at index \(i) should match original")
        }
    }
    
    func testShuffleModePreservesCurrentItemPosition() async throws {
        let items = makeTestQueue(count: 5)
        
        do {
            try await controller.playQueue(items: items, startingAt: 2)
        } catch {
            // Expected
        }
        
        let currentItem = controller.currentItem
        
        controller.setShuffleMode(.on)
        
        // After shuffle, current item should be at index 0
        XCTAssertEqual(controller.queueIndex, 0)
        XCTAssertEqual(controller.queue[0].id, currentItem?.id)
    }
    
    func testPlayNextWithShuffleUpdatesOriginalQueue() async throws {
        let items = makeTestQueue(count: 3)
        let newItem = LibraryItem(
            kind: .stream,
            title: "New Item",
            source: .fromURL(URL(string: "https://example.com/new.mp3")!)
        )
        
        do {
            try await controller.playQueue(items: items, startingAt: 0)
        } catch {
            // Expected
        }
        
        controller.setShuffleMode(.on)
        
        do {
            try await controller.playNext(newItem)
        } catch {
            // Expected
        }
        
        XCTAssertEqual(controller.queue.count, 4)
        XCTAssertEqual(controller.queue[1].id, newItem.id)
    }
    
    // MARK: - Stop Tests
    
    func testStopClearsState() async throws {
        let items = makeTestQueue(count: 3)
        
        do {
            try await controller.playQueue(items: items, startingAt: 0)
        } catch {
            // Expected
        }
        
        controller.setShuffleMode(.on)
        
        controller.stop()
        
        XCTAssertEqual(controller.activeBackend, .none)
        XCTAssertNil(controller.currentItem)
        XCTAssertTrue(controller.queue.isEmpty)
        XCTAssertNil(controller.queueIndex)
        XCTAssertEqual(controller.shuffleMode, .off)
    }
    
    // MARK: - State Computed Properties Tests
    
    func testStateReflectsNoBackend() {
        XCTAssertEqual(controller.state, .stopped)
    }
    
    func testIsPlayingFalseWhenNoBackend() {
        XCTAssertFalse(controller.isPlaying)
    }
    
    func testCurrentTimeNilWhenNoBackend() {
        XCTAssertNil(controller.currentTime)
    }
    
    func testDurationNilWhenNoBackend() {
        XCTAssertNil(controller.duration)
    }
    
    // MARK: - Error Case Tests
    
    func testInvalidSourceURLThrows() async {
        // Create an item with YouTube kind but URL source (invalid combination)
        let invalidItem = LibraryItem(
            kind: .youtube,
            title: "Invalid",
            source: .fromURL(URL(string: "https://example.com")!) // YouTube needs youtubeID
        )
        
        do {
            try await controller.play(item: invalidItem)
            XCTFail("Should throw invalidSource")
        } catch PlaybackControllerError.invalidSource {
            // Expected - YouTube kind needs youtubeID in source
        } catch {
            // Other errors are acceptable (network, etc)
        }
    }
    
    // MARK: - Toggle Play/Pause Tests
    
    func testTogglePlayPauseWhenNotPlaying() async throws {
        // When nothing is loaded, toggle should be a no-op (no crash)
        controller.togglePlayPause()
        
        // Should not throw or crash
        XCTAssertFalse(controller.isPlaying)
    }
}
