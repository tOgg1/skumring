import XCTest
@testable import Skumring

/// Tests for StreamResolver playlist URL resolution.
///
/// Tests cover M3U parsing, PLS parsing, recursive resolution,
/// and error handling scenarios.
final class StreamResolverTests: XCTestCase {
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        
        // Configure StreamResolver to use a session with our mock protocol
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        StreamResolver.testSessionConfiguration = config
    }
    
    override func tearDown() {
        StreamResolver.testSessionConfiguration = nil
        MockURLProtocol.reset()
        super.tearDown()
    }
    
    // MARK: - Direct URL Tests (Non-Playlist)
    
    func testDirectMP3URLReturnsUnchanged() async throws {
        let directURL = URL(string: "https://stream.example.com/radio.mp3")!
        
        let resolved = try await StreamResolver.resolve(url: directURL)
        
        XCTAssertEqual(resolved, directURL)
    }
    
    func testDirectOggURLReturnsUnchanged() async throws {
        let directURL = URL(string: "https://stream.example.com/radio.ogg")!
        
        let resolved = try await StreamResolver.resolve(url: directURL)
        
        XCTAssertEqual(resolved, directURL)
    }
    
    func testDirectAACURLReturnsUnchanged() async throws {
        let directURL = URL(string: "https://stream.example.com/radio.aac")!
        
        let resolved = try await StreamResolver.resolve(url: directURL)
        
        XCTAssertEqual(resolved, directURL)
    }
    
    func testURLWithoutExtensionReturnsUnchanged() async throws {
        let directURL = URL(string: "https://stream.example.com/live")!
        
        let resolved = try await StreamResolver.resolve(url: directURL)
        
        XCTAssertEqual(resolved, directURL)
    }
    
    // MARK: - M3U Parsing Tests
    
    func testParseSimpleM3U() async throws {
        let playlistURL = URL(string: "https://example.com/playlist.m3u")!
        let streamURL = "https://stream.example.com/radio.mp3"
        let m3uContent = streamURL
        
        MockURLProtocol.setMockResponse(
            for: playlistURL,
            data: m3uContent.data(using: .utf8)!,
            statusCode: 200
        )
        
        let resolved = try await StreamResolver.resolve(url: playlistURL)
        
        XCTAssertEqual(resolved.absoluteString, streamURL)
    }
    
    func testParseM3UWithComments() async throws {
        let playlistURL = URL(string: "https://example.com/playlist.m3u")!
        let streamURL = "https://stream.example.com/radio.mp3"
        let m3uContent = """
        # This is a comment
        # Another comment
        \(streamURL)
        """
        
        MockURLProtocol.setMockResponse(
            for: playlistURL,
            data: m3uContent.data(using: .utf8)!,
            statusCode: 200
        )
        
        let resolved = try await StreamResolver.resolve(url: playlistURL)
        
        XCTAssertEqual(resolved.absoluteString, streamURL)
    }
    
    func testParseExtendedM3U() async throws {
        let playlistURL = URL(string: "https://example.com/playlist.m3u")!
        let streamURL = "https://stream.example.com/radio.mp3"
        let m3uContent = """
        #EXTM3U
        #EXTINF:-1,Radio Station Name
        \(streamURL)
        """
        
        MockURLProtocol.setMockResponse(
            for: playlistURL,
            data: m3uContent.data(using: .utf8)!,
            statusCode: 200
        )
        
        let resolved = try await StreamResolver.resolve(url: playlistURL)
        
        XCTAssertEqual(resolved.absoluteString, streamURL)
    }
    
    func testParseM3UWithMultipleURLsPicksFirst() async throws {
        let playlistURL = URL(string: "https://example.com/playlist.m3u")!
        let firstStreamURL = "https://stream1.example.com/radio.mp3"
        let m3uContent = """
        #EXTM3U
        \(firstStreamURL)
        https://stream2.example.com/radio.mp3
        https://stream3.example.com/radio.mp3
        """
        
        MockURLProtocol.setMockResponse(
            for: playlistURL,
            data: m3uContent.data(using: .utf8)!,
            statusCode: 200
        )
        
        let resolved = try await StreamResolver.resolve(url: playlistURL)
        
        XCTAssertEqual(resolved.absoluteString, firstStreamURL)
    }
    
    func testParseM3UWithEmptyLines() async throws {
        let playlistURL = URL(string: "https://example.com/playlist.m3u")!
        let streamURL = "https://stream.example.com/radio.mp3"
        let m3uContent = """
        
        
        #EXTM3U
        
        #EXTINF:-1,Station
        
        \(streamURL)
        
        """
        
        MockURLProtocol.setMockResponse(
            for: playlistURL,
            data: m3uContent.data(using: .utf8)!,
            statusCode: 200
        )
        
        let resolved = try await StreamResolver.resolve(url: playlistURL)
        
        XCTAssertEqual(resolved.absoluteString, streamURL)
    }
    
    func testParseM3UWithWhitespace() async throws {
        let playlistURL = URL(string: "https://example.com/playlist.m3u")!
        let streamURL = "https://stream.example.com/radio.mp3"
        let m3uContent = "   \(streamURL)   "
        
        MockURLProtocol.setMockResponse(
            for: playlistURL,
            data: m3uContent.data(using: .utf8)!,
            statusCode: 200
        )
        
        let resolved = try await StreamResolver.resolve(url: playlistURL)
        
        XCTAssertEqual(resolved.absoluteString, streamURL)
    }
    
    func testParseM3U8Extension() async throws {
        let playlistURL = URL(string: "https://example.com/playlist.m3u8")!
        let streamURL = "https://stream.example.com/radio.mp3"
        let m3uContent = streamURL
        
        MockURLProtocol.setMockResponse(
            for: playlistURL,
            data: m3uContent.data(using: .utf8)!,
            statusCode: 200
        )
        
        let resolved = try await StreamResolver.resolve(url: playlistURL)
        
        XCTAssertEqual(resolved.absoluteString, streamURL)
    }
    
    // MARK: - PLS Parsing Tests
    
    func testParseSimplePLS() async throws {
        let playlistURL = URL(string: "https://example.com/playlist.pls")!
        let streamURL = "https://stream.example.com/radio.mp3"
        let plsContent = """
        [playlist]
        File1=\(streamURL)
        """
        
        MockURLProtocol.setMockResponse(
            for: playlistURL,
            data: plsContent.data(using: .utf8)!,
            statusCode: 200
        )
        
        let resolved = try await StreamResolver.resolve(url: playlistURL)
        
        XCTAssertEqual(resolved.absoluteString, streamURL)
    }
    
    func testParsePLSWithMetadata() async throws {
        let playlistURL = URL(string: "https://example.com/playlist.pls")!
        let streamURL = "https://stream.example.com/radio.mp3"
        let plsContent = """
        [playlist]
        NumberOfEntries=1
        File1=\(streamURL)
        Title1=My Radio Station
        Length1=-1
        Version=2
        """
        
        MockURLProtocol.setMockResponse(
            for: playlistURL,
            data: plsContent.data(using: .utf8)!,
            statusCode: 200
        )
        
        let resolved = try await StreamResolver.resolve(url: playlistURL)
        
        XCTAssertEqual(resolved.absoluteString, streamURL)
    }
    
    func testParsePLSWithMultipleEntriesPicksFirst() async throws {
        let playlistURL = URL(string: "https://example.com/playlist.pls")!
        let firstStreamURL = "https://stream1.example.com/radio.mp3"
        let plsContent = """
        [playlist]
        NumberOfEntries=3
        File1=\(firstStreamURL)
        Title1=Primary Stream
        File2=https://stream2.example.com/radio.mp3
        Title2=Backup Stream 1
        File3=https://stream3.example.com/radio.mp3
        Title3=Backup Stream 2
        Version=2
        """
        
        MockURLProtocol.setMockResponse(
            for: playlistURL,
            data: plsContent.data(using: .utf8)!,
            statusCode: 200
        )
        
        let resolved = try await StreamResolver.resolve(url: playlistURL)
        
        XCTAssertEqual(resolved.absoluteString, firstStreamURL)
    }
    
    func testParsePLSOutOfOrderEntriesPicksLowestNumber() async throws {
        let playlistURL = URL(string: "https://example.com/playlist.pls")!
        let firstStreamURL = "https://stream1.example.com/radio.mp3"
        let plsContent = """
        [playlist]
        File3=https://stream3.example.com/radio.mp3
        File1=\(firstStreamURL)
        File2=https://stream2.example.com/radio.mp3
        """
        
        MockURLProtocol.setMockResponse(
            for: playlistURL,
            data: plsContent.data(using: .utf8)!,
            statusCode: 200
        )
        
        let resolved = try await StreamResolver.resolve(url: playlistURL)
        
        XCTAssertEqual(resolved.absoluteString, firstStreamURL)
    }
    
    func testParsePLSCaseInsensitive() async throws {
        let playlistURL = URL(string: "https://example.com/playlist.pls")!
        let streamURL = "https://stream.example.com/radio.mp3"
        let plsContent = """
        [PLAYLIST]
        FILE1=\(streamURL)
        """
        
        MockURLProtocol.setMockResponse(
            for: playlistURL,
            data: plsContent.data(using: .utf8)!,
            statusCode: 200
        )
        
        let resolved = try await StreamResolver.resolve(url: playlistURL)
        
        XCTAssertEqual(resolved.absoluteString, streamURL)
    }
    
    func testParsePLSWithWhitespace() async throws {
        let playlistURL = URL(string: "https://example.com/playlist.pls")!
        let streamURL = "https://stream.example.com/radio.mp3"
        let plsContent = """
        [playlist]
          File1=\(streamURL)  
        """
        
        MockURLProtocol.setMockResponse(
            for: playlistURL,
            data: plsContent.data(using: .utf8)!,
            statusCode: 200
        )
        
        let resolved = try await StreamResolver.resolve(url: playlistURL)
        
        XCTAssertEqual(resolved.absoluteString, streamURL)
    }
    
    // MARK: - Recursive Resolution Tests
    
    func testRecursiveM3UResolution() async throws {
        let outerPlaylistURL = URL(string: "https://example.com/outer.m3u")!
        let innerPlaylistURL = URL(string: "https://example.com/inner.m3u")!
        let streamURL = "https://stream.example.com/radio.mp3"
        
        // Outer playlist points to inner playlist
        MockURLProtocol.setMockResponse(
            for: outerPlaylistURL,
            data: innerPlaylistURL.absoluteString.data(using: .utf8)!,
            statusCode: 200
        )
        
        // Inner playlist points to actual stream
        MockURLProtocol.setMockResponse(
            for: innerPlaylistURL,
            data: streamURL.data(using: .utf8)!,
            statusCode: 200
        )
        
        let resolved = try await StreamResolver.resolve(url: outerPlaylistURL)
        
        XCTAssertEqual(resolved.absoluteString, streamURL)
    }
    
    func testRecursivePLSToM3UResolution() async throws {
        let plsURL = URL(string: "https://example.com/playlist.pls")!
        let m3uURL = URL(string: "https://example.com/stream.m3u")!
        let streamURL = "https://stream.example.com/radio.mp3"
        
        // PLS points to M3U
        let plsContent = """
        [playlist]
        File1=\(m3uURL.absoluteString)
        """
        MockURLProtocol.setMockResponse(
            for: plsURL,
            data: plsContent.data(using: .utf8)!,
            statusCode: 200
        )
        
        // M3U points to actual stream
        MockURLProtocol.setMockResponse(
            for: m3uURL,
            data: streamURL.data(using: .utf8)!,
            statusCode: 200
        )
        
        let resolved = try await StreamResolver.resolve(url: plsURL)
        
        XCTAssertEqual(resolved.absoluteString, streamURL)
    }
    
    func testMaxDepthExceeded() async throws {
        // Create a chain of 4 playlists (exceeds max depth of 3)
        let urls = (0..<5).map { URL(string: "https://example.com/level\($0).m3u")! }
        
        // Each playlist points to the next
        for i in 0..<4 {
            MockURLProtocol.setMockResponse(
                for: urls[i],
                data: urls[i + 1].absoluteString.data(using: .utf8)!,
                statusCode: 200
            )
        }
        
        // Final playlist has a stream
        MockURLProtocol.setMockResponse(
            for: urls[4],
            data: "https://stream.example.com/radio.mp3".data(using: .utf8)!,
            statusCode: 200
        )
        
        do {
            _ = try await StreamResolver.resolve(url: urls[0])
            XCTFail("Expected maxDepthExceeded error")
        } catch let error as StreamResolverError {
            if case .maxDepthExceeded = error {
                // Expected
            } else {
                XCTFail("Expected maxDepthExceeded error, got \(error)")
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkErrorThrowsError() async throws {
        let playlistURL = URL(string: "https://example.com/playlist.m3u")!
        
        MockURLProtocol.setMockError(
            for: playlistURL,
            error: URLError(.notConnectedToInternet)
        )
        
        do {
            _ = try await StreamResolver.resolve(url: playlistURL)
            XCTFail("Expected networkError")
        } catch let error as StreamResolverError {
            if case .networkError = error {
                // Expected
            } else {
                XCTFail("Expected networkError, got \(error)")
            }
        }
    }
    
    func testHTTPErrorThrowsNetworkError() async throws {
        let playlistURL = URL(string: "https://example.com/playlist.m3u")!
        
        MockURLProtocol.setMockResponse(
            for: playlistURL,
            data: "Not Found".data(using: .utf8)!,
            statusCode: 404
        )
        
        do {
            _ = try await StreamResolver.resolve(url: playlistURL)
            XCTFail("Expected networkError for HTTP 404")
        } catch let error as StreamResolverError {
            if case .networkError = error {
                // Expected
            } else {
                XCTFail("Expected networkError, got \(error)")
            }
        }
    }
    
    func testEmptyM3UThrowsNoValidURL() async throws {
        let playlistURL = URL(string: "https://example.com/playlist.m3u")!
        
        MockURLProtocol.setMockResponse(
            for: playlistURL,
            data: "".data(using: .utf8)!,
            statusCode: 200
        )
        
        do {
            _ = try await StreamResolver.resolve(url: playlistURL)
            XCTFail("Expected noValidURL error")
        } catch let error as StreamResolverError {
            if case .noValidURL = error {
                // Expected
            } else {
                XCTFail("Expected noValidURL error, got \(error)")
            }
        }
    }
    
    func testM3UWithOnlyCommentsThrowsNoValidURL() async throws {
        let playlistURL = URL(string: "https://example.com/playlist.m3u")!
        let m3uContent = """
        #EXTM3U
        # Comment line 1
        # Comment line 2
        """
        
        MockURLProtocol.setMockResponse(
            for: playlistURL,
            data: m3uContent.data(using: .utf8)!,
            statusCode: 200
        )
        
        do {
            _ = try await StreamResolver.resolve(url: playlistURL)
            XCTFail("Expected noValidURL error")
        } catch let error as StreamResolverError {
            if case .noValidURL = error {
                // Expected
            } else {
                XCTFail("Expected noValidURL error, got \(error)")
            }
        }
    }
    
    func testEmptyPLSThrowsNoValidURL() async throws {
        let playlistURL = URL(string: "https://example.com/playlist.pls")!
        let plsContent = """
        [playlist]
        NumberOfEntries=0
        """
        
        MockURLProtocol.setMockResponse(
            for: playlistURL,
            data: plsContent.data(using: .utf8)!,
            statusCode: 200
        )
        
        do {
            _ = try await StreamResolver.resolve(url: playlistURL)
            XCTFail("Expected noValidURL error")
        } catch let error as StreamResolverError {
            if case .noValidURL = error {
                // Expected
            } else {
                XCTFail("Expected noValidURL error, got \(error)")
            }
        }
    }
    
    func testMalformedPLSThrowsNoValidURL() async throws {
        let playlistURL = URL(string: "https://example.com/playlist.pls")!
        let plsContent = """
        [playlist]
        File1=not-a-valid-url
        File2=also-invalid
        """
        
        MockURLProtocol.setMockResponse(
            for: playlistURL,
            data: plsContent.data(using: .utf8)!,
            statusCode: 200
        )
        
        do {
            _ = try await StreamResolver.resolve(url: playlistURL)
            XCTFail("Expected noValidURL error")
        } catch let error as StreamResolverError {
            if case .noValidURL = error {
                // Expected
            } else {
                XCTFail("Expected noValidURL error, got \(error)")
            }
        }
    }
    
    func testM3UWithOnlyInvalidURLsThrowsNoValidURL() async throws {
        let playlistURL = URL(string: "https://example.com/playlist.m3u")!
        let m3uContent = """
        #EXTM3U
        relative/path/to/stream
        ftp://invalid-scheme.example.com/stream
        not-a-url-at-all
        """
        
        MockURLProtocol.setMockResponse(
            for: playlistURL,
            data: m3uContent.data(using: .utf8)!,
            statusCode: 200
        )
        
        do {
            _ = try await StreamResolver.resolve(url: playlistURL)
            XCTFail("Expected noValidURL error")
        } catch let error as StreamResolverError {
            if case .noValidURL = error {
                // Expected
            } else {
                XCTFail("Expected noValidURL error, got \(error)")
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testM3UWithMixedValidAndInvalidURLs() async throws {
        let playlistURL = URL(string: "https://example.com/playlist.m3u")!
        let validURL = "https://stream.example.com/radio.mp3"
        let m3uContent = """
        #EXTM3U
        not-a-valid-url
        ftp://wrong-scheme.example.com/stream
        \(validURL)
        https://backup.example.com/stream.mp3
        """
        
        MockURLProtocol.setMockResponse(
            for: playlistURL,
            data: m3uContent.data(using: .utf8)!,
            statusCode: 200
        )
        
        let resolved = try await StreamResolver.resolve(url: playlistURL)
        
        XCTAssertEqual(resolved.absoluteString, validURL)
    }
    
    func testURLWithQueryParameters() async throws {
        let playlistURL = URL(string: "https://example.com/playlist.m3u?token=abc123")!
        let streamURL = "https://stream.example.com/radio.mp3?quality=high"
        
        MockURLProtocol.setMockResponse(
            for: playlistURL,
            data: streamURL.data(using: .utf8)!,
            statusCode: 200
        )
        
        let resolved = try await StreamResolver.resolve(url: playlistURL)
        
        XCTAssertEqual(resolved.absoluteString, streamURL)
    }
    
    func testHTTPSInM3U() async throws {
        let playlistURL = URL(string: "https://example.com/playlist.m3u")!
        let streamURL = "https://secure-stream.example.com/radio.mp3"
        
        MockURLProtocol.setMockResponse(
            for: playlistURL,
            data: streamURL.data(using: .utf8)!,
            statusCode: 200
        )
        
        let resolved = try await StreamResolver.resolve(url: playlistURL)
        
        XCTAssertEqual(resolved.absoluteString, streamURL)
    }
    
    func testHTTPInM3U() async throws {
        let playlistURL = URL(string: "https://example.com/playlist.m3u")!
        let streamURL = "http://insecure-stream.example.com/radio.mp3"
        
        MockURLProtocol.setMockResponse(
            for: playlistURL,
            data: streamURL.data(using: .utf8)!,
            statusCode: 200
        )
        
        let resolved = try await StreamResolver.resolve(url: playlistURL)
        
        XCTAssertEqual(resolved.absoluteString, streamURL)
    }
    
    // MARK: - StreamResolverError Tests
    
    func testErrorDescriptions() {
        let networkError = StreamResolverError.networkError(URLError(.notConnectedToInternet))
        XCTAssertTrue(networkError.errorDescription?.contains("Network error") ?? false)
        
        let parseError = StreamResolverError.parseError("Invalid format")
        XCTAssertTrue(parseError.errorDescription?.contains("Parse error") ?? false)
        XCTAssertTrue(parseError.errorDescription?.contains("Invalid format") ?? false)
        
        let noValidURL = StreamResolverError.noValidURL
        XCTAssertTrue(noValidURL.errorDescription?.contains("No valid stream URL") ?? false)
        
        let timeout = StreamResolverError.timeout
        XCTAssertTrue(timeout.errorDescription?.contains("timed out") ?? false)
        
        let maxDepth = StreamResolverError.maxDepthExceeded
        XCTAssertTrue(maxDepth.errorDescription?.contains("depth exceeded") ?? false)
    }
}

// MARK: - Mock URL Protocol

/// A URLProtocol subclass for mocking network responses in tests.
///
/// Usage:
/// 1. Register the protocol: `URLProtocol.registerClass(MockURLProtocol.self)`
/// 2. Set mock responses: `MockURLProtocol.setMockResponse(for:data:statusCode:)`
/// 3. Unregister when done: `URLProtocol.unregisterClass(MockURLProtocol.self)`
final class MockURLProtocol: URLProtocol {
    
    /// Storage for mock responses keyed by URL string.
    /// Note: nonisolated(unsafe) is used because access is protected by the lock below.
    nonisolated(unsafe) private static var mockResponses: [String: MockResponse] = [:]
    
    /// Storage for mock errors keyed by URL string.
    /// Note: nonisolated(unsafe) is used because access is protected by the lock below.
    nonisolated(unsafe) private static var mockErrors: [String: Error] = [:]
    
    /// Thread-safe access to mock storage.
    private static let lock = NSLock()
    
    /// A mock HTTP response.
    private struct MockResponse {
        let data: Data
        let statusCode: Int
        let headers: [String: String]
    }
    
    /// Sets a mock response for a URL.
    static func setMockResponse(
        for url: URL,
        data: Data,
        statusCode: Int,
        headers: [String: String] = ["Content-Type": "text/plain"]
    ) {
        lock.lock()
        defer { lock.unlock() }
        mockResponses[url.absoluteString] = MockResponse(
            data: data,
            statusCode: statusCode,
            headers: headers
        )
    }
    
    /// Sets a mock error for a URL.
    static func setMockError(for url: URL, error: Error) {
        lock.lock()
        defer { lock.unlock() }
        mockErrors[url.absoluteString] = error
    }
    
    /// Clears all mock responses and errors.
    static func reset() {
        lock.lock()
        defer { lock.unlock() }
        mockResponses.removeAll()
        mockErrors.removeAll()
    }
    
    // MARK: - URLProtocol Overrides
    
    override class func canInit(with request: URLRequest) -> Bool {
        // Handle all requests when used in test configuration
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        
        Self.lock.lock()
        let mockResponse = Self.mockResponses[url.absoluteString]
        let mockError = Self.mockErrors[url.absoluteString]
        Self.lock.unlock()
        
        if let error = mockError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        
        guard let mock = mockResponse else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        
        let response = HTTPURLResponse(
            url: url,
            statusCode: mock.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: mock.headers
        )!
        
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: mock.data)
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
        // Nothing to do
    }
}
