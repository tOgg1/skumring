import XCTest
@testable import Skumring

// Type aliases to avoid ambiguity with DeveloperToolsSupport.LibraryItem
private typealias LibraryItem = Skumring.LibraryItem

/// Tests for LibraryItem model initialization, encoding, and behavior.
final class LibraryItemTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testInitializationWithAllParameters() {
        let id = UUID()
        let addedAt = Date()
        let artworkURL = URL(string: "https://example.com/art.jpg")!
        
        let item = LibraryItem(
            id: id,
            kind: .stream,
            title: "Test Stream",
            subtitle: "Test Subtitle",
            source: .fromURL(URL(string: "https://example.com/stream.mp3")!),
            addedAt: addedAt,
            tags: ["lofi", "focus"],
            artworkURL: artworkURL,
            healthStatus: .ok,
            failCount: 1
        )
        
        XCTAssertEqual(item.id, id)
        XCTAssertEqual(item.kind, .stream)
        XCTAssertEqual(item.title, "Test Stream")
        XCTAssertEqual(item.subtitle, "Test Subtitle")
        XCTAssertEqual(item.addedAt, addedAt)
        XCTAssertEqual(item.tags, ["lofi", "focus"])
        XCTAssertEqual(item.artworkURL, artworkURL)
        XCTAssertEqual(item.healthStatus, .ok)
        XCTAssertEqual(item.failCount, 1)
    }
    
    func testInitializationWithDefaults() {
        let item = LibraryItem(
            kind: .youtube,
            title: "Test Video",
            source: .fromYouTube("dQw4w9WgXcQ")
        )
        
        XCTAssertNotNil(item.id)
        XCTAssertEqual(item.kind, .youtube)
        XCTAssertEqual(item.title, "Test Video")
        XCTAssertNil(item.subtitle)
        XCTAssertEqual(item.tags, [])
        XCTAssertNil(item.artworkURL)
        XCTAssertEqual(item.healthStatus, .unknown)
        XCTAssertEqual(item.failCount, 0)
    }
    
    // MARK: - Codable Round-trip Tests
    
    func testEncodingDecodingRoundTrip() throws {
        let id = UUID()
        let addedAt = Date()
        
        let originalItem = LibraryItem(
            id: id,
            kind: .stream,
            title: "LoFi Beats Radio",
            subtitle: "Curated",
            source: .fromURL(URL(string: "https://example.com/stream.m3u")!),
            addedAt: addedAt,
            tags: ["lofi", "focus"],
            artworkURL: URL(string: "https://example.com/art.jpg"),
            healthStatus: .ok,
            failCount: 0
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(originalItem)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedItem = try decoder.decode(LibraryItem.self, from: data)
        
        XCTAssertEqual(decodedItem.id, originalItem.id)
        XCTAssertEqual(decodedItem.kind, originalItem.kind)
        XCTAssertEqual(decodedItem.title, originalItem.title)
        XCTAssertEqual(decodedItem.subtitle, originalItem.subtitle)
        XCTAssertEqual(decodedItem.tags, originalItem.tags)
        XCTAssertEqual(decodedItem.artworkURL, originalItem.artworkURL)
        XCTAssertEqual(decodedItem.healthStatus, originalItem.healthStatus)
        XCTAssertEqual(decodedItem.failCount, originalItem.failCount)
    }
    
    func testEncodingDecodingYouTubeItem() throws {
        let item = LibraryItem(
            kind: .youtube,
            title: "Rainy Jazz Café",
            subtitle: "YouTube",
            source: .fromYouTube("M7lc1UVf-VE"),
            tags: ["jazz", "rain"]
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(item)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedItem = try decoder.decode(LibraryItem.self, from: data)
        
        XCTAssertEqual(decodedItem.kind, .youtube)
        XCTAssertEqual(decodedItem.source.youtubeID, "M7lc1UVf-VE")
        XCTAssertNil(decodedItem.source.url)
    }
    
    func testEncodingDecodingAudioURLItem() throws {
        let item = LibraryItem(
            kind: .audioURL,
            title: "Sample Audio",
            source: .fromURL(URL(string: "https://example.com/audio.mp3")!)
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(item)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedItem = try decoder.decode(LibraryItem.self, from: data)
        
        XCTAssertEqual(decodedItem.kind, .audioURL)
        XCTAssertEqual(decodedItem.source.url?.absoluteString, "https://example.com/audio.mp3")
    }
    
    // MARK: - All ItemKind Cases Tests
    
    func testAllItemKindCases() {
        let streamItem = LibraryItem(kind: .stream, title: "Stream", source: .fromURL(URL(string: "https://stream.com")!))
        let youtubeItem = LibraryItem(kind: .youtube, title: "YouTube", source: .fromYouTube("abc123"))
        let audioItem = LibraryItem(kind: .audioURL, title: "Audio", source: .fromURL(URL(string: "https://audio.com/file.mp3")!))
        
        XCTAssertEqual(streamItem.kind, .stream)
        XCTAssertEqual(youtubeItem.kind, .youtube)
        XCTAssertEqual(audioItem.kind, .audioURL)
    }
    
    // MARK: - Health Status Tests
    
    func testRecordSuccess() {
        var item = LibraryItem(
            kind: .stream,
            title: "Test",
            source: .fromURL(URL(string: "https://example.com")!),
            healthStatus: .failing,
            failCount: 5
        )
        
        item.recordSuccess()
        
        XCTAssertEqual(item.healthStatus, .ok)
        XCTAssertEqual(item.failCount, 0)
    }
    
    func testRecordFailureBeforeThreshold() {
        var item = LibraryItem(
            kind: .stream,
            title: "Test",
            source: .fromURL(URL(string: "https://example.com")!),
            healthStatus: .unknown,
            failCount: 0
        )
        
        item.recordFailure()
        XCTAssertEqual(item.failCount, 1)
        XCTAssertEqual(item.healthStatus, .unknown) // Not yet failing
        
        item.recordFailure()
        XCTAssertEqual(item.failCount, 2)
        XCTAssertEqual(item.healthStatus, .unknown) // Still not failing
    }
    
    func testRecordFailureAtThreshold() {
        var item = LibraryItem(
            kind: .stream,
            title: "Test",
            source: .fromURL(URL(string: "https://example.com")!),
            healthStatus: .unknown,
            failCount: 2
        )
        
        item.recordFailure()
        
        XCTAssertEqual(item.failCount, 3)
        XCTAssertEqual(item.healthStatus, .failing)
    }
    
    func testResetForRetry() {
        var item = LibraryItem(
            kind: .stream,
            title: "Test",
            source: .fromURL(URL(string: "https://example.com")!),
            healthStatus: .failing,
            failCount: 5
        )
        
        item.resetForRetry()
        
        XCTAssertEqual(item.healthStatus, .unknown)
        XCTAssertEqual(item.failCount, 0)
    }
    
    // MARK: - Source Key Tests
    
    func testSourceKeyForURL() {
        let item = LibraryItem(
            kind: .stream,
            title: "Test",
            source: .fromURL(URL(string: "HTTPS://Example.COM/stream.mp3")!)
        )
        
        // Should be normalized to lowercase scheme and host
        XCTAssertEqual(item.sourceKey, "https://example.com/stream.mp3")
    }
    
    func testSourceKeyForYouTube() {
        let item = LibraryItem(
            kind: .youtube,
            title: "Test",
            source: .fromYouTube("dQw4w9WgXcQ")
        )
        
        XCTAssertEqual(item.sourceKey, "youtube:dQw4w9WgXcQ")
    }
    
    // MARK: - Edge Cases
    
    func testUnicodeInTitle() throws {
        let item = LibraryItem(
            kind: .stream,
            title: "日本語タイトル 🎵 émoji",
            source: .fromURL(URL(string: "https://example.com")!)
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(item)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(LibraryItem.self, from: data)
        
        XCTAssertEqual(decoded.title, "日本語タイトル 🎵 émoji")
    }
    
    func testVeryLongTitle() throws {
        let longTitle = String(repeating: "A", count: 10000)
        let item = LibraryItem(
            kind: .stream,
            title: longTitle,
            source: .fromURL(URL(string: "https://example.com")!)
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(item)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(LibraryItem.self, from: data)
        
        XCTAssertEqual(decoded.title, longTitle)
    }
    
    func testEmptyTags() throws {
        let item = LibraryItem(
            kind: .stream,
            title: "Test",
            source: .fromURL(URL(string: "https://example.com")!),
            tags: []
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(item)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(LibraryItem.self, from: data)
        
        XCTAssertEqual(decoded.tags, [])
    }
    
    func testSpecialCharactersInURL() throws {
        let urlWithSpecialChars = URL(string: "https://example.com/stream?param=value&other=test%20space")!
        let item = LibraryItem(
            kind: .stream,
            title: "Test",
            source: .fromURL(urlWithSpecialChars)
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(item)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(LibraryItem.self, from: data)
        
        XCTAssertEqual(decoded.source.url, urlWithSpecialChars)
    }
    
    // MARK: - Identifiable & Hashable Tests
    
    func testIdentifiable() {
        let item1 = LibraryItem(kind: .stream, title: "Test1", source: .fromURL(URL(string: "https://a.com")!))
        let item2 = LibraryItem(kind: .stream, title: "Test2", source: .fromURL(URL(string: "https://b.com")!))
        
        XCTAssertNotEqual(item1.id, item2.id)
    }
    
    func testHashable() {
        let item1 = LibraryItem(kind: .stream, title: "Test", source: .fromURL(URL(string: "https://a.com")!))
        var item2 = item1
        item2.title = "Changed"
        
        // Items with same ID should hash the same (since Hashable is based on all fields by default)
        var set = Set<LibraryItem>()
        set.insert(item1)
        
        // Since we changed title, item2 should be different
        XCTAssertNotEqual(item1, item2)
    }
}
