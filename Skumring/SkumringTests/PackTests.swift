import XCTest
@testable import Skumring

// Type aliases to avoid ambiguity with DeveloperToolsSupport.LibraryItem
private typealias LibraryItem = Skumring.LibraryItem
private typealias LibraryItemKind = Skumring.LibraryItemKind

/// Tests for Pack model encoding, decoding, and validation.
final class PackTests: XCTestCase {
    
    // MARK: - Test Helpers
    
    private func createSampleItem(kind: LibraryItemKind = .stream) -> LibraryItem {
        switch kind {
        case .stream:
            return LibraryItem(
                kind: .stream,
                title: "Test Stream",
                source: .fromURL(URL(string: "https://example.com/stream.mp3")!)
            )
        case .youtube:
            return LibraryItem(
                kind: .youtube,
                title: "Test Video",
                source: .fromYouTube("dQw4w9WgXcQ")
            )
        case .audioURL:
            return LibraryItem(
                kind: .audioURL,
                title: "Test Audio",
                source: .fromURL(URL(string: "https://example.com/audio.mp3")!)
            )
        }
    }
    
    private func createSamplePlaylist(with itemIDs: [UUID] = []) -> Playlist {
        Playlist(
            name: "Test Playlist",
            itemIDs: itemIDs,
            repeatMode: .all,
            shuffleMode: .off
        )
    }
    
    // MARK: - Initialization Tests
    
    func testInitializationWithDefaults() {
        let items = [createSampleItem()]
        let playlists = [createSamplePlaylist()]
        
        let pack = Pack(items: items, playlists: playlists)
        
        XCTAssertEqual(pack.schemaVersion, Pack.currentSchemaVersion)
        XCTAssertEqual(pack.appIdentifier, Pack.defaultAppIdentifier)
        XCTAssertEqual(pack.items.count, 1)
        XCTAssertEqual(pack.playlists.count, 1)
        XCTAssertNil(pack.packType)
        XCTAssertNil(pack.packVersion)
    }
    
    func testInitializationWithCustomValues() {
        let exportedAt = Date()
        let items = [createSampleItem()]
        let playlists = [createSamplePlaylist()]
        
        let pack = Pack(
            items: items,
            playlists: playlists,
            exportedAt: exportedAt,
            appIdentifier: "custom.app.identifier",
            packType: "builtin",
            packVersion: "2026.01.03"
        )
        
        XCTAssertEqual(pack.schemaVersion, Pack.currentSchemaVersion)
        XCTAssertEqual(pack.appIdentifier, "custom.app.identifier")
        XCTAssertEqual(pack.packType, "builtin")
        XCTAssertEqual(pack.packVersion, "2026.01.03")
    }
    
    func testInitializationWithExplicitSchemaVersion() {
        let pack = Pack(
            schemaVersion: 1,
            exportedAt: Date(),
            appIdentifier: "test.app",
            items: [],
            playlists: []
        )
        
        XCTAssertEqual(pack.schemaVersion, 1)
    }
    
    // MARK: - Codable Round-trip Tests
    
    func testFullPackEncodingDecoding() throws {
        let item = createSampleItem()
        let playlist = createSamplePlaylist(with: [item.id])
        let exportedAt = Date()
        
        let originalPack = Pack(
            items: [item],
            playlists: [playlist],
            exportedAt: exportedAt,
            packType: "user",
            packVersion: "1.0.0"
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(originalPack)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedPack = try decoder.decode(Pack.self, from: data)
        
        XCTAssertEqual(decodedPack.schemaVersion, originalPack.schemaVersion)
        XCTAssertEqual(decodedPack.appIdentifier, originalPack.appIdentifier)
        XCTAssertEqual(decodedPack.items.count, originalPack.items.count)
        XCTAssertEqual(decodedPack.playlists.count, originalPack.playlists.count)
        XCTAssertEqual(decodedPack.packType, originalPack.packType)
        XCTAssertEqual(decodedPack.packVersion, originalPack.packVersion)
    }
    
    func testSchemaVersionIsIncluded() throws {
        let pack = Pack(items: [], playlists: [])
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(pack)
        let json = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(json.contains("schemaVersion"))
        XCTAssertTrue(json.contains("\(Pack.currentSchemaVersion)"))
    }
    
    func testExportedAtTimestampFormat() throws {
        let pack = Pack(items: [], playlists: [])
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(pack)
        let json = String(data: data, encoding: .utf8)!
        
        // ISO 8601 format includes 'T' separator and timezone
        XCTAssertTrue(json.contains("exportedAt"))
        // Basic ISO8601 format check - contains year-month-day format
        let pattern = #"\d{4}-\d{2}-\d{2}"#
        XCTAssertNotNil(json.range(of: pattern, options: .regularExpression))
    }
    
    func testItemsAndPlaylistsArrays() throws {
        let items = [
            createSampleItem(kind: .stream),
            createSampleItem(kind: .youtube),
            createSampleItem(kind: .audioURL)
        ]
        let playlists = [
            createSamplePlaylist(with: [items[0].id]),
            createSamplePlaylist(with: [items[1].id, items[2].id])
        ]
        
        let pack = Pack(items: items, playlists: playlists)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(pack)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Pack.self, from: data)
        
        XCTAssertEqual(decoded.items.count, 3)
        XCTAssertEqual(decoded.playlists.count, 2)
    }
    
    // MARK: - Schema Version Validation
    
    func testIsSchemaVersionSupportedForCurrentVersion() {
        let pack = Pack(items: [], playlists: [])
        
        XCTAssertTrue(pack.isSchemaVersionSupported)
    }
    
    func testIsSchemaVersionSupportedForOlderVersion() {
        let pack = Pack(
            schemaVersion: 0,
            exportedAt: Date(),
            appIdentifier: "test",
            items: [],
            playlists: []
        )
        
        XCTAssertTrue(pack.isSchemaVersionSupported)
    }
    
    func testIsSchemaVersionSupportedForNewerVersion() {
        let pack = Pack(
            schemaVersion: Pack.currentSchemaVersion + 1,
            exportedAt: Date(),
            appIdentifier: "test",
            items: [],
            playlists: []
        )
        
        XCTAssertFalse(pack.isSchemaVersionSupported)
    }
    
    // MARK: - Edge Cases
    
    func testEmptyItemsAndPlaylists() throws {
        let pack = Pack(items: [], playlists: [])
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(pack)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Pack.self, from: data)
        
        XCTAssertEqual(decoded.items.count, 0)
        XCTAssertEqual(decoded.playlists.count, 0)
    }
    
    func testLargeNumberOfItems() throws {
        let items = (0..<100).map { _ in createSampleItem() }
        let pack = Pack(items: items, playlists: [])
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(pack)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Pack.self, from: data)
        
        XCTAssertEqual(decoded.items.count, 100)
    }
    
    func testNilPackTypeAndVersion() throws {
        let pack = Pack(items: [], playlists: [])
        
        XCTAssertNil(pack.packType)
        XCTAssertNil(pack.packVersion)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(pack)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Pack.self, from: data)
        
        XCTAssertNil(decoded.packType)
        XCTAssertNil(decoded.packVersion)
    }
    
    // MARK: - JSON Format Validation (matches spec schema)
    
    func testJSONOutputMatchesSpecSchema() throws {
        let itemID = UUID()
        let playlistID = UUID()
        
        let item = LibraryItem(
            id: itemID,
            kind: .stream,
            title: "LoFi Beats Radio",
            subtitle: "Curated",
            source: .fromURL(URL(string: "https://example.com/stream.m3u")!),
            tags: ["lofi", "focus"],
            artworkURL: URL(string: "https://example.com/art.jpg")
        )
        
        let playlist = Playlist(
            id: playlistID,
            name: "Deep Work",
            itemIDs: [itemID],
            repeatMode: .all,
            shuffleMode: .off
        )
        
        let pack = Pack(
            items: [item],
            playlists: [playlist],
            appIdentifier: "com.example.Skumring"
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(pack)
        
        // Decode as generic JSON to verify structure
        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        // Verify top-level keys exist
        XCTAssertNotNil(jsonObject["schemaVersion"])
        XCTAssertNotNil(jsonObject["exportedAt"])
        XCTAssertNotNil(jsonObject["appIdentifier"])
        XCTAssertNotNil(jsonObject["items"])
        XCTAssertNotNil(jsonObject["playlists"])
        
        // Verify schemaVersion is Int
        XCTAssertTrue(jsonObject["schemaVersion"] is Int)
        
        // Verify items array
        let items = jsonObject["items"] as! [[String: Any]]
        XCTAssertEqual(items.count, 1)
        
        let firstItem = items[0]
        XCTAssertNotNil(firstItem["id"])
        XCTAssertNotNil(firstItem["kind"])
        XCTAssertNotNil(firstItem["title"])
        XCTAssertNotNil(firstItem["source"])
        XCTAssertEqual(firstItem["kind"] as? String, "stream")
        
        // Verify playlists array
        let playlists = jsonObject["playlists"] as! [[String: Any]]
        XCTAssertEqual(playlists.count, 1)
        
        let firstPlaylist = playlists[0]
        XCTAssertNotNil(firstPlaylist["id"])
        XCTAssertNotNil(firstPlaylist["name"])
        XCTAssertNotNil(firstPlaylist["itemIDs"])
        XCTAssertEqual(firstPlaylist["repeatMode"] as? String, "all")
        XCTAssertEqual(firstPlaylist["shuffleMode"] as? String, "off")
    }
}
