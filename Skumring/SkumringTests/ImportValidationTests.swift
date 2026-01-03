import XCTest
@testable import Skumring

// Type alias to avoid ambiguity with DeveloperToolsSupport.LibraryItem
private typealias LibraryItemSource = Skumring.LibraryItemSource

/// Tests for import validation including schema version, item kind, URL validation, and malformed JSON.
final class ImportValidationTests: XCTestCase {
    
    // MARK: - Schema Version Validation Tests
    
    func testValidSchemaVersionPasses() throws {
        let json = """
        {
            "schemaVersion": 1,
            "exportedAt": "2026-01-02T10:00:00Z",
            "appIdentifier": "com.test.app",
            "items": [],
            "playlists": []
        }
        """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let pack = try decoder.decode(Pack.self, from: json.data(using: .utf8)!)
        
        XCTAssertTrue(pack.isSchemaVersionSupported)
    }
    
    func testSchemaVersionZeroPasses() throws {
        let json = """
        {
            "schemaVersion": 0,
            "exportedAt": "2026-01-02T10:00:00Z",
            "appIdentifier": "com.test.app",
            "items": [],
            "playlists": []
        }
        """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let pack = try decoder.decode(Pack.self, from: json.data(using: .utf8)!)
        
        XCTAssertTrue(pack.isSchemaVersionSupported)
    }
    
    func testFutureSchemaVersionRejected() throws {
        let json = """
        {
            "schemaVersion": 999,
            "exportedAt": "2026-01-02T10:00:00Z",
            "appIdentifier": "com.test.app",
            "items": [],
            "playlists": []
        }
        """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let pack = try decoder.decode(Pack.self, from: json.data(using: .utf8)!)
        
        XCTAssertFalse(pack.isSchemaVersionSupported)
    }
    
    // MARK: - Item Kind Validation Tests
    
    func testValidStreamKind() throws {
        let json = """
        {
            "schemaVersion": 1,
            "exportedAt": "2026-01-02T10:00:00Z",
            "appIdentifier": "com.test.app",
            "items": [{
                "id": "A2B3C4D5-E6F7-4123-8901-23456789ABCD",
                "kind": "stream",
                "title": "Test Stream",
                "source": {"url": "https://example.com/stream.mp3"},
                "addedAt": "2026-01-02T10:00:00Z",
                "tags": [],
                "healthStatus": "unknown",
                "failCount": 0
            }],
            "playlists": []
        }
        """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let pack = try decoder.decode(Pack.self, from: json.data(using: .utf8)!)
        
        XCTAssertEqual(pack.items.first?.kind, .stream)
    }
    
    func testValidYouTubeKind() throws {
        let json = """
        {
            "schemaVersion": 1,
            "exportedAt": "2026-01-02T10:00:00Z",
            "appIdentifier": "com.test.app",
            "items": [{
                "id": "A2B3C4D5-E6F7-4123-8901-23456789ABCD",
                "kind": "youtube",
                "title": "Test Video",
                "source": {"youtubeID": "dQw4w9WgXcQ"},
                "addedAt": "2026-01-02T10:00:00Z",
                "tags": [],
                "healthStatus": "unknown",
                "failCount": 0
            }],
            "playlists": []
        }
        """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let pack = try decoder.decode(Pack.self, from: json.data(using: .utf8)!)
        
        XCTAssertEqual(pack.items.first?.kind, .youtube)
    }
    
    func testValidAudioURLKind() throws {
        let json = """
        {
            "schemaVersion": 1,
            "exportedAt": "2026-01-02T10:00:00Z",
            "appIdentifier": "com.test.app",
            "items": [{
                "id": "A2B3C4D5-E6F7-4123-8901-23456789ABCD",
                "kind": "audioURL",
                "title": "Test Audio",
                "source": {"url": "https://example.com/audio.mp3"},
                "addedAt": "2026-01-02T10:00:00Z",
                "tags": [],
                "healthStatus": "unknown",
                "failCount": 0
            }],
            "playlists": []
        }
        """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let pack = try decoder.decode(Pack.self, from: json.data(using: .utf8)!)
        
        XCTAssertEqual(pack.items.first?.kind, .audioURL)
    }
    
    func testInvalidItemKindRejected() throws {
        let json = """
        {
            "schemaVersion": 1,
            "exportedAt": "2026-01-02T10:00:00Z",
            "appIdentifier": "com.test.app",
            "items": [{
                "id": "A2B3C4D5-E6F7-4123-8901-23456789ABCD",
                "kind": "podcast",
                "title": "Test",
                "source": {"url": "https://example.com"},
                "addedAt": "2026-01-02T10:00:00Z",
                "tags": [],
                "healthStatus": "unknown",
                "failCount": 0
            }],
            "playlists": []
        }
        """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        XCTAssertThrowsError(try decoder.decode(Pack.self, from: json.data(using: .utf8)!)) { error in
            // Decoding should fail for unknown kind
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    // MARK: - Source Validation Tests
    
    func testSourceWithURLIsValid() {
        let source = LibraryItemSource.fromURL(URL(string: "https://example.com/stream")!)
        XCTAssertTrue(source.isValid)
    }
    
    func testSourceWithYouTubeIDIsValid() {
        let source = LibraryItemSource.fromYouTube("dQw4w9WgXcQ")
        XCTAssertTrue(source.isValid)
    }
    
    func testSourceWithBothIsValid() {
        let source = LibraryItemSource(url: URL(string: "https://example.com")!, youtubeID: "abc123")
        XCTAssertTrue(source.isValid)
    }
    
    func testSourceWithNeitherIsInvalid() {
        let source = LibraryItemSource(url: nil, youtubeID: nil)
        XCTAssertFalse(source.isValid)
    }
    
    func testSourceWithEmptyYouTubeIDIsInvalid() {
        let source = LibraryItemSource(url: nil, youtubeID: "")
        XCTAssertFalse(source.isValid)
    }
    
    // MARK: - URL Scheme Validation Tests
    
    func testHTTPSURLAccepted() throws {
        let json = """
        {
            "schemaVersion": 1,
            "exportedAt": "2026-01-02T10:00:00Z",
            "appIdentifier": "com.test.app",
            "items": [{
                "id": "A2B3C4D5-E6F7-4123-8901-23456789ABCD",
                "kind": "stream",
                "title": "Test",
                "source": {"url": "https://example.com/stream"},
                "addedAt": "2026-01-02T10:00:00Z",
                "tags": [],
                "healthStatus": "unknown",
                "failCount": 0
            }],
            "playlists": []
        }
        """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let pack = try decoder.decode(Pack.self, from: json.data(using: .utf8)!)
        
        XCTAssertEqual(pack.items.first?.source.url?.scheme, "https")
    }
    
    func testHTTPURLAccepted() throws {
        let json = """
        {
            "schemaVersion": 1,
            "exportedAt": "2026-01-02T10:00:00Z",
            "appIdentifier": "com.test.app",
            "items": [{
                "id": "A2B3C4D5-E6F7-4123-8901-23456789ABCD",
                "kind": "stream",
                "title": "Test",
                "source": {"url": "http://example.com/stream"},
                "addedAt": "2026-01-02T10:00:00Z",
                "tags": [],
                "healthStatus": "unknown",
                "failCount": 0
            }],
            "playlists": []
        }
        """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let pack = try decoder.decode(Pack.self, from: json.data(using: .utf8)!)
        
        // HTTP URLs should be accepted (per spec, https is recommended but not required)
        XCTAssertEqual(pack.items.first?.source.url?.scheme, "http")
    }
    
    func testFileURLShouldBeRejectedAtApplicationLevel() {
        // Note: file:// URLs can be parsed by Foundation, but should be rejected at the application level
        // This test documents the expected behavior for ImportExportService to implement
        let source = LibraryItemSource.fromURL(URL(string: "file:///etc/passwd")!)
        
        // The source itself is valid from a data perspective
        XCTAssertTrue(source.isValid)
        
        // But the URL scheme is 'file' which should be rejected during import
        XCTAssertEqual(source.url?.scheme, "file")
    }
    
    // MARK: - Malformed JSON Handling Tests
    
    func testMalformedJSONThrows() {
        let json = "{ invalid json }"
        
        let decoder = JSONDecoder()
        
        XCTAssertThrowsError(try decoder.decode(Pack.self, from: json.data(using: .utf8)!)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func testMissingRequiredFieldThrows() {
        // Missing schemaVersion
        let json = """
        {
            "exportedAt": "2026-01-02T10:00:00Z",
            "appIdentifier": "com.test.app",
            "items": [],
            "playlists": []
        }
        """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        XCTAssertThrowsError(try decoder.decode(Pack.self, from: json.data(using: .utf8)!)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func testEmptyJSONThrows() {
        let json = "{}"
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        XCTAssertThrowsError(try decoder.decode(Pack.self, from: json.data(using: .utf8)!)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func testNullJSONThrows() {
        let json = "null"
        
        let decoder = JSONDecoder()
        
        XCTAssertThrowsError(try decoder.decode(Pack.self, from: json.data(using: .utf8)!)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func testArrayInsteadOfObjectThrows() {
        let json = "[]"
        
        let decoder = JSONDecoder()
        
        XCTAssertThrowsError(try decoder.decode(Pack.self, from: json.data(using: .utf8)!)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func testInvalidDateFormatThrows() {
        let json = """
        {
            "schemaVersion": 1,
            "exportedAt": "not-a-date",
            "appIdentifier": "com.test.app",
            "items": [],
            "playlists": []
        }
        """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        XCTAssertThrowsError(try decoder.decode(Pack.self, from: json.data(using: .utf8)!)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func testWrongTypeForSchemaVersionThrows() {
        let json = """
        {
            "schemaVersion": "one",
            "exportedAt": "2026-01-02T10:00:00Z",
            "appIdentifier": "com.test.app",
            "items": [],
            "playlists": []
        }
        """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        XCTAssertThrowsError(try decoder.decode(Pack.self, from: json.data(using: .utf8)!)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    // MARK: - Partial/Incomplete Items Tests
    
    func testItemMissingTitleThrows() {
        let json = """
        {
            "schemaVersion": 1,
            "exportedAt": "2026-01-02T10:00:00Z",
            "appIdentifier": "com.test.app",
            "items": [{
                "id": "A2B3C4D5-E6F7-4123-8901-23456789ABCD",
                "kind": "stream",
                "source": {"url": "https://example.com"},
                "addedAt": "2026-01-02T10:00:00Z",
                "tags": [],
                "healthStatus": "unknown",
                "failCount": 0
            }],
            "playlists": []
        }
        """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        XCTAssertThrowsError(try decoder.decode(Pack.self, from: json.data(using: .utf8)!)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func testItemMissingSourceThrows() {
        let json = """
        {
            "schemaVersion": 1,
            "exportedAt": "2026-01-02T10:00:00Z",
            "appIdentifier": "com.test.app",
            "items": [{
                "id": "A2B3C4D5-E6F7-4123-8901-23456789ABCD",
                "kind": "stream",
                "title": "Test",
                "addedAt": "2026-01-02T10:00:00Z",
                "tags": [],
                "healthStatus": "unknown",
                "failCount": 0
            }],
            "playlists": []
        }
        """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        XCTAssertThrowsError(try decoder.decode(Pack.self, from: json.data(using: .utf8)!)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
}
