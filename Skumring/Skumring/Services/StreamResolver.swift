import Foundation

/// Errors that can occur during stream resolution.
enum StreamResolverError: Error, LocalizedError {
    case networkError(Error)
    case parseError(String)
    case noValidURL
    case timeout
    case maxDepthExceeded
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parseError(let message):
            return "Parse error: \(message)"
        case .noValidURL:
            return "No valid stream URL found in playlist"
        case .timeout:
            return "Request timed out"
        case .maxDepthExceeded:
            return "Maximum playlist recursion depth exceeded"
        }
    }
}

/// Resolves playlist URLs (M3U, PLS) to their underlying stream URLs.
///
/// Internet radio streams are often served via playlist files that contain
/// the actual streaming URL. This service handles fetching and parsing
/// these playlists to extract the direct stream URL.
///
/// Supported formats:
/// - M3U/M3U8: Line-based format, lines starting with # are comments
/// - PLS: INI-like format with File1=, File2= entries
///
/// Usage:
/// ```swift
/// let streamURL = try await StreamResolver.resolve(url: playlistURL)
/// // Use streamURL with AVPlayer
/// ```
enum StreamResolver {
    
    /// Default timeout for network requests in seconds.
    private static let defaultTimeout: TimeInterval = 10
    
    /// Maximum recursion depth for nested playlists.
    private static let maxRecursionDepth = 3
    
    /// Resolves a URL to its underlying stream URL.
    ///
    /// If the URL points to a playlist file (.m3u, .m3u8, .pls), this method
    /// fetches and parses the playlist to extract the actual stream URL.
    /// If the URL is not a playlist, it is returned unchanged.
    ///
    /// Handles nested playlists up to 3 levels deep.
    ///
    /// - Parameter url: The URL to resolve
    /// - Returns: The resolved stream URL
    /// - Throws: `StreamResolverError` if resolution fails
    static func resolve(url: URL) async throws -> URL {
        try await resolve(url: url, depth: 0)
    }
    
    /// Internal recursive resolution method.
    private static func resolve(url: URL, depth: Int) async throws -> URL {
        guard depth < maxRecursionDepth else {
            throw StreamResolverError.maxDepthExceeded
        }
        
        // Check if this is a playlist URL
        let pathExtension = url.pathExtension.lowercased()
        
        switch pathExtension {
        case "m3u", "m3u8":
            let content = try await fetchContent(from: url)
            let streamURL = try parseM3U(content)
            // Recursively resolve in case the result is also a playlist
            return try await resolve(url: streamURL, depth: depth + 1)
            
        case "pls":
            let content = try await fetchContent(from: url)
            let streamURL = try parsePLS(content)
            // Recursively resolve in case the result is also a playlist
            return try await resolve(url: streamURL, depth: depth + 1)
            
        default:
            // Not a playlist, return as-is
            return url
        }
    }
    
    /// Fetches content from a URL with timeout.
    private static func fetchContent(from url: URL) async throws -> String {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = defaultTimeout
        config.timeoutIntervalForResource = defaultTimeout
        
        let session = URLSession(configuration: config)
        
        do {
            let (data, response) = try await session.data(from: url)
            
            // Check for HTTP errors
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                throw StreamResolverError.networkError(
                    NSError(domain: "HTTPError", code: httpResponse.statusCode)
                )
            }
            
            guard let content = String(data: data, encoding: .utf8) else {
                throw StreamResolverError.parseError("Could not decode content as UTF-8")
            }
            
            return content
            
        } catch let error as StreamResolverError {
            throw error
        } catch let error as URLError where error.code == .timedOut {
            throw StreamResolverError.timeout
        } catch {
            throw StreamResolverError.networkError(error)
        }
    }
    
    /// Parses M3U/M3U8 playlist content to extract the first valid stream URL.
    ///
    /// M3U format:
    /// - Lines starting with # are comments or metadata
    /// - Non-comment lines are URLs
    /// - First valid http(s) URL is returned
    private static func parseM3U(_ content: String) throws -> URL {
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines and comments
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }
            
            // Check if it's a valid http(s) URL
            if let url = URL(string: trimmed),
               let scheme = url.scheme?.lowercased(),
               scheme == "http" || scheme == "https" {
                return url
            }
        }
        
        throw StreamResolverError.noValidURL
    }
    
    /// Parses PLS playlist content to extract the first stream URL.
    ///
    /// PLS format (INI-like):
    /// ```
    /// [playlist]
    /// File1=http://stream.example.com/stream
    /// Title1=Station Name
    /// Length1=-1
    /// NumberOfEntries=1
    /// Version=2
    /// ```
    private static func parsePLS(_ content: String) throws -> URL {
        let lines = content.components(separatedBy: .newlines)
        
        // Look for File1=, File2=, etc. (prefer lower numbers)
        var fileEntries: [(index: Int, url: URL)] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Match File<N>= pattern (case-insensitive)
            if let range = trimmed.range(of: "^File(\\d+)=", options: [.regularExpression, .caseInsensitive]) {
                let keyPart = String(trimmed[range])
                let urlString = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                
                // Extract the file number
                if let numberRange = keyPart.range(of: "\\d+", options: .regularExpression),
                   let index = Int(keyPart[numberRange]),
                   let url = URL(string: urlString),
                   let scheme = url.scheme?.lowercased(),
                   scheme == "http" || scheme == "https" {
                    fileEntries.append((index: index, url: url))
                }
            }
        }
        
        // Return the entry with the lowest index
        if let firstEntry = fileEntries.min(by: { $0.index < $1.index }) {
            return firstEntry.url
        }
        
        throw StreamResolverError.noValidURL
    }
}
