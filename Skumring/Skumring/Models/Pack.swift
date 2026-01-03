import Foundation

/// A shareable container for library items and playlists.
///
/// Packs are used for import/export functionality, allowing users to share
/// curated collections of focus music sources.
///
/// See PRODUCT_SPECIFICATION.md Section 14 for the JSON schema.
struct Pack: Codable, Sendable {
    /// Schema version for forward/backward compatibility.
    /// Current version: 1
    let schemaVersion: Int
    
    /// When this pack was exported
    let exportedAt: Date
    
    /// Bundle identifier of the exporting app
    let appIdentifier: String
    
    /// Items included in this pack
    let items: [LibraryItem]
    
    /// Playlists included in this pack
    let playlists: [Playlist]
    
    /// Current schema version constant
    static let currentSchemaVersion = 1
    
    /// Default app identifier for Skumring
    static let defaultAppIdentifier = "com.skumring.Skumring"
    
    /// Creates a new pack with the current schema version.
    init(
        items: [LibraryItem],
        playlists: [Playlist],
        exportedAt: Date = Date(),
        appIdentifier: String = Pack.defaultAppIdentifier
    ) {
        self.schemaVersion = Pack.currentSchemaVersion
        self.exportedAt = exportedAt
        self.appIdentifier = appIdentifier
        self.items = items
        self.playlists = playlists
    }
    
    /// Creates a pack from existing data with explicit schema version.
    /// Used when importing packs from older versions.
    init(
        schemaVersion: Int,
        exportedAt: Date,
        appIdentifier: String,
        items: [LibraryItem],
        playlists: [Playlist]
    ) {
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.appIdentifier = appIdentifier
        self.items = items
        self.playlists = playlists
    }
    
    /// Whether this pack's schema version is supported.
    var isSchemaVersionSupported: Bool {
        schemaVersion <= Pack.currentSchemaVersion
    }
}
