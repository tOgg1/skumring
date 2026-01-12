import SwiftUI

/// Brand colors extracted from the Skumring logo.
///
/// The color palette consists of warm earth tones balanced with cool slate blues,
/// creating a cozy, twilight-inspired aesthetic that matches the app's name
/// ("skumring" means "twilight" in Norwegian).
extension Color {
    
    // MARK: - Primary Brand Colors
    
    /// Deep teal/slate blue - used for primary accents
    /// Hex: #4A6670
    static let brandTeal = Color(red: 0.290, green: 0.400, blue: 0.439)
    
    /// Warm terracotta - used for warm accents and highlights
    /// Hex: #A75D4E
    static let brandTerracotta = Color(red: 0.655, green: 0.365, blue: 0.306)
    
    /// Deep rust/brown - used for depth and contrast
    /// Hex: #8B4D3B
    static let brandRust = Color(red: 0.545, green: 0.302, blue: 0.231)
    
    /// Soft coral/salmon - used for subtle highlights
    /// Hex: #D4937A
    static let brandCoral = Color(red: 0.831, green: 0.576, blue: 0.478)
    
    // MARK: - Background Colors
    
    /// Warm cream background - main background color
    /// Hex: #E8DDD4
    static let brandCream = Color(red: 0.910, green: 0.867, blue: 0.831)
    
    /// Light off-white - for cards and elevated surfaces
    /// Hex: #F5EDE6
    static let brandOffWhite = Color(red: 0.961, green: 0.929, blue: 0.902)
    
    // MARK: - Accent Variants
    
    /// Light teal variant for subtle backgrounds
    static let brandTealLight = Color(red: 0.290, green: 0.400, blue: 0.439).opacity(0.15)
    
    /// Light coral variant for subtle highlights
    static let brandCoralLight = Color(red: 0.831, green: 0.576, blue: 0.478).opacity(0.2)
}

// MARK: - ShapeStyle Extensions

extension ShapeStyle where Self == Color {
    /// The primary brand accent color (terracotta)
    static var brandAccent: Color { .brandTerracotta }
    
    /// Secondary brand accent (teal)
    static var brandSecondary: Color { .brandTeal }
}
