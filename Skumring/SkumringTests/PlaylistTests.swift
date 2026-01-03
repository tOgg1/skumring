import XCTest
@testable import Skumring

/// Tests for Playlist model initialization, encoding, and item management.
final class PlaylistTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testInitializationWithAllParameters() {
        let id = UUID()
        let createdAt = Date()
        let itemIDs = [UUID(), UUID(), UUID()]
        
        let playlist = Playlist(
            id: id,
            name: "Deep Work",
            itemIDs: itemIDs,
            repeatMode: .all,
            shuffleMode: .on,
            createdAt: createdAt
        )
        
        XCTAssertEqual(playlist.id, id)
        XCTAssertEqual(playlist.name, "Deep Work")
        XCTAssertEqual(playlist.itemIDs, itemIDs)
        XCTAssertEqual(playlist.repeatMode, .all)
        XCTAssertEqual(playlist.shuffleMode, .on)
        XCTAssertEqual(playlist.createdAt, createdAt)
    }
    
    func testInitializationWithDefaults() {
        let playlist = Playlist(name: "New Playlist")
        
        XCTAssertNotNil(playlist.id)
        XCTAssertEqual(playlist.name, "New Playlist")
        XCTAssertEqual(playlist.itemIDs, [])
        XCTAssertEqual(playlist.repeatMode, .off)
        XCTAssertEqual(playlist.shuffleMode, .off)
    }
    
    // MARK: - Codable Round-trip Tests
    
    func testEncodingDecodingRoundTrip() throws {
        let itemIDs = [UUID(), UUID(), UUID()]
        let createdAt = Date()
        
        let originalPlaylist = Playlist(
            name: "Focus Mix",
            itemIDs: itemIDs,
            repeatMode: .one,
            shuffleMode: .off,
            createdAt: createdAt
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(originalPlaylist)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedPlaylist = try decoder.decode(Playlist.self, from: data)
        
        XCTAssertEqual(decodedPlaylist.id, originalPlaylist.id)
        XCTAssertEqual(decodedPlaylist.name, originalPlaylist.name)
        XCTAssertEqual(decodedPlaylist.itemIDs, originalPlaylist.itemIDs)
        XCTAssertEqual(decodedPlaylist.repeatMode, originalPlaylist.repeatMode)
        XCTAssertEqual(decodedPlaylist.shuffleMode, originalPlaylist.shuffleMode)
    }
    
    func testItemIDsOrderingPreserved() throws {
        let itemIDs = (0..<10).map { _ in UUID() }
        
        let playlist = Playlist(name: "Ordered", itemIDs: itemIDs)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(playlist)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Playlist.self, from: data)
        
        XCTAssertEqual(decoded.itemIDs, itemIDs, "Item IDs ordering must be preserved")
    }
    
    // MARK: - RepeatMode and ShuffleMode Encoding Tests
    
    func testRepeatModeEncoding() throws {
        let encoder = JSONEncoder()
        
        for mode in RepeatMode.allCases {
            let playlist = Playlist(name: "Test", repeatMode: mode)
            let data = try encoder.encode(playlist)
            let json = String(data: data, encoding: .utf8)!
            
            XCTAssertTrue(json.contains("\"\(mode.rawValue)\""), "JSON should contain raw value \(mode.rawValue)")
        }
    }
    
    func testShuffleModeEncoding() throws {
        let encoder = JSONEncoder()
        
        for mode in ShuffleMode.allCases {
            let playlist = Playlist(name: "Test", shuffleMode: mode)
            let data = try encoder.encode(playlist)
            let json = String(data: data, encoding: .utf8)!
            
            XCTAssertTrue(json.contains("\"\(mode.rawValue)\""), "JSON should contain raw value \(mode.rawValue)")
        }
    }
    
    func testAllRepeatModeValuesRoundTrip() throws {
        for mode in RepeatMode.allCases {
            let playlist = Playlist(name: "Test", repeatMode: mode)
            
            let encoder = JSONEncoder()
            let data = try encoder.encode(playlist)
            
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(Playlist.self, from: data)
            
            XCTAssertEqual(decoded.repeatMode, mode)
        }
    }
    
    func testAllShuffleModeValuesRoundTrip() throws {
        for mode in ShuffleMode.allCases {
            let playlist = Playlist(name: "Test", shuffleMode: mode)
            
            let encoder = JSONEncoder()
            let data = try encoder.encode(playlist)
            
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(Playlist.self, from: data)
            
            XCTAssertEqual(decoded.shuffleMode, mode)
        }
    }
    
    // MARK: - Item Management Tests
    
    func testAddItem() {
        var playlist = Playlist(name: "Test")
        let itemID = UUID()
        
        playlist.addItem(itemID)
        
        XCTAssertEqual(playlist.itemIDs.count, 1)
        XCTAssertEqual(playlist.itemIDs.first, itemID)
    }
    
    func testAddMultipleItems() {
        var playlist = Playlist(name: "Test")
        let ids = [UUID(), UUID(), UUID()]
        
        for id in ids {
            playlist.addItem(id)
        }
        
        XCTAssertEqual(playlist.itemIDs, ids)
    }
    
    func testRemoveItem() {
        let itemToRemove = UUID()
        var playlist = Playlist(name: "Test", itemIDs: [UUID(), itemToRemove, UUID()])
        
        playlist.removeItem(itemToRemove)
        
        XCTAssertFalse(playlist.itemIDs.contains(itemToRemove))
        XCTAssertEqual(playlist.itemIDs.count, 2)
    }
    
    func testRemoveItemRemovesDuplicates() {
        let duplicateID = UUID()
        var playlist = Playlist(name: "Test", itemIDs: [duplicateID, UUID(), duplicateID, duplicateID])
        
        playlist.removeItem(duplicateID)
        
        XCTAssertFalse(playlist.itemIDs.contains(duplicateID))
        XCTAssertEqual(playlist.itemIDs.count, 1)
    }
    
    func testRemoveNonexistentItem() {
        var playlist = Playlist(name: "Test", itemIDs: [UUID(), UUID()])
        let originalIDs = playlist.itemIDs
        
        playlist.removeItem(UUID())
        
        XCTAssertEqual(playlist.itemIDs, originalIDs)
    }
    
    func testMoveItemForward() {
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()
        var playlist = Playlist(name: "Test", itemIDs: [id1, id2, id3])
        
        playlist.moveItem(from: 0, to: 2)
        
        XCTAssertEqual(playlist.itemIDs, [id2, id1, id3])
    }
    
    func testMoveItemBackward() {
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()
        var playlist = Playlist(name: "Test", itemIDs: [id1, id2, id3])
        
        playlist.moveItem(from: 2, to: 0)
        
        XCTAssertEqual(playlist.itemIDs, [id3, id1, id2])
    }
    
    func testMoveItemToSamePosition() {
        let ids = [UUID(), UUID(), UUID()]
        var playlist = Playlist(name: "Test", itemIDs: ids)
        
        playlist.moveItem(from: 1, to: 1)
        
        XCTAssertEqual(playlist.itemIDs, ids)
    }
    
    func testMoveItemInvalidSourceIndex() {
        let ids = [UUID(), UUID()]
        var playlist = Playlist(name: "Test", itemIDs: ids)
        
        playlist.moveItem(from: 10, to: 0)
        
        XCTAssertEqual(playlist.itemIDs, ids)
    }
    
    func testMoveItemInvalidDestinationIndex() {
        let ids = [UUID(), UUID()]
        var playlist = Playlist(name: "Test", itemIDs: ids)
        
        playlist.moveItem(from: 0, to: -1)
        
        XCTAssertEqual(playlist.itemIDs, ids)
    }
    
    func testContainsItem() {
        let existingID = UUID()
        let playlist = Playlist(name: "Test", itemIDs: [UUID(), existingID, UUID()])
        
        XCTAssertTrue(playlist.contains(existingID))
        XCTAssertFalse(playlist.contains(UUID()))
    }
    
    func testItemCount() {
        let playlist = Playlist(name: "Test", itemIDs: [UUID(), UUID(), UUID()])
        
        XCTAssertEqual(playlist.itemCount, 3)
    }
    
    func testEmptyPlaylistItemCount() {
        let playlist = Playlist(name: "Empty")
        
        XCTAssertEqual(playlist.itemCount, 0)
    }
    
    // MARK: - Edge Cases
    
    func testEmptyItemIDs() throws {
        let playlist = Playlist(name: "Empty", itemIDs: [])
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(playlist)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Playlist.self, from: data)
        
        XCTAssertEqual(decoded.itemIDs, [])
    }
    
    func testUnicodeInName() throws {
        let playlist = Playlist(name: "日本語プレイリスト 🎵")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(playlist)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Playlist.self, from: data)
        
        XCTAssertEqual(decoded.name, "日本語プレイリスト 🎵")
    }
    
    func testVeryLongName() throws {
        let longName = String(repeating: "A", count: 10000)
        let playlist = Playlist(name: longName)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(playlist)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Playlist.self, from: data)
        
        XCTAssertEqual(decoded.name, longName)
    }
    
    func testLargeNumberOfItems() throws {
        let largeItemIDs = (0..<1000).map { _ in UUID() }
        let playlist = Playlist(name: "Large", itemIDs: largeItemIDs)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(playlist)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Playlist.self, from: data)
        
        XCTAssertEqual(decoded.itemIDs, largeItemIDs)
    }
}
