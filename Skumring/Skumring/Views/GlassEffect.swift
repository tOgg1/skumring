import SwiftUI

// MARK: - Glass Style

/// Defines the visual style for glass effects based on accessibility preferences
/// and user settings.
///
/// ## Usage
/// Use `.glassStyle()` modifier on views that need glass effects:
/// ```swift
/// myView
///     .glassStyle()
/// ```
///
/// The modifier automatically respects:
/// - Reduce Transparency (System Preferences > Accessibility > Display)
/// - Increase Contrast (System Preferences > Accessibility > Display)
/// - Reduce Motion (System Preferences > Accessibility > Display)
///
/// ## Fallback Behavior
/// - **Reduce Transparency ON**: Uses `.solid` style (opaque background)
/// - **Increase Contrast ON**: Adds visible borders for better definition
/// - **Reduce Motion ON**: Disables complex animations
public enum GlassStyle: String, CaseIterable, Sendable {
    /// Full glass effect with blur and translucency (default).
    /// Uses the system `glassEffect()` modifier on macOS 26+.
    case glass
    
    /// Subtle transparency with less visual complexity.
    /// Useful for users who want some effect but less distraction.
    case subtle
    
    /// Completely opaque background matching the window background.
    /// Used when Reduce Transparency is enabled.
    case solid
    
    /// No special background styling.
    /// The view uses its default background.
    case none
}

// MARK: - Glass Style Preference

/// Environment key for user's preferred glass style override.
/// When set, this overrides the automatic accessibility-based selection.
private struct GlassStylePreferenceKey: EnvironmentKey {
    static let defaultValue: GlassStyle? = nil
}

extension EnvironmentValues {
    /// User's preferred glass style override.
    /// Set to `nil` (default) to use automatic accessibility-based selection.
    var glassStylePreference: GlassStyle? {
        get { self[GlassStylePreferenceKey.self] }
        set { self[GlassStylePreferenceKey.self] = newValue }
    }
}

extension View {
    /// Sets the preferred glass style for this view hierarchy.
    ///
    /// This overrides the automatic accessibility-based selection.
    /// Pass `nil` to return to automatic mode.
    ///
    /// - Parameter style: The glass style to use, or `nil` for automatic.
    public func glassStylePreference(_ style: GlassStyle?) -> some View {
        environment(\.glassStylePreference, style)
    }
}

// MARK: - Glass Effect Modifier

/// A view modifier that applies glass effect styling with accessibility fallbacks.
///
/// This modifier:
/// 1. Checks accessibility settings (Reduce Transparency, Increase Contrast, Reduce Motion)
/// 2. Applies the appropriate visual style based on those settings
/// 3. Uses the new `glassEffect()` modifier on macOS 26+ when glass style is active
/// 4. Falls back to solid colors or subtle materials when needed
///
/// ## Accessibility Behavior
///
/// | Setting | Effect |
/// |---------|--------|
/// | Reduce Transparency | Forces `.solid` style |
/// | Increase Contrast | Adds visible border |
/// | Reduce Motion | Simplifies animations |
///
public struct GlassEffectModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.glassStylePreference) private var stylePreference
    @Environment(\.colorScheme) private var colorScheme
    
    /// Optional tint color for the glass effect.
    let tint: Color?
    
    /// Corner radius for the glass container.
    let cornerRadius: CGFloat
    
    /// Whether to show a border (auto-enabled for Increase Contrast).
    let showBorder: Bool
    
    /// Creates a glass effect modifier.
    ///
    /// - Parameters:
    ///   - tint: Optional tint color for the glass effect.
    ///   - cornerRadius: Corner radius for the glass container. Default is 12.
    ///   - showBorder: Whether to always show a border. Default is false (auto based on accessibility).
    public init(tint: Color? = nil, cornerRadius: CGFloat = 12, showBorder: Bool = false) {
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.showBorder = showBorder
    }
    
    /// The resolved glass style based on preferences and accessibility settings.
    private var resolvedStyle: GlassStyle {
        // User preference takes priority (unless it conflicts with accessibility needs)
        if let preference = stylePreference {
            // Reduce Transparency always wins - glass/subtle not allowed
            if reduceTransparency && (preference == .glass || preference == .subtle) {
                return .solid
            }
            return preference
        }
        
        // Automatic selection based on accessibility
        if reduceTransparency {
            return .solid
        }
        
        // Default to glass
        return .glass
    }
    
    /// Whether to show increased contrast borders.
    private var shouldShowBorder: Bool {
        showBorder || differentiateWithoutColor
    }
    
    public func body(content: Content) -> some View {
        content
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(borderOverlay)
    }
    
    // MARK: - Background View
    
    @ViewBuilder
    private var backgroundView: some View {
        switch resolvedStyle {
        case .glass:
            glassBackground
            
        case .subtle:
            subtleBackground
            
        case .solid:
            solidBackground
            
        case .none:
            Color.clear
        }
    }
    
    /// Full glass effect background using macOS 26+ API.
    @ViewBuilder
    private var glassBackground: some View {
        if let tint {
            Rectangle()
                .fill(.clear)
                .glassEffect()
                .overlay(
                    tint.opacity(0.1)
                )
        } else {
            Rectangle()
                .fill(.clear)
                .glassEffect()
        }
    }
    
    /// Subtle transparency background - less intense than full glass.
    @ViewBuilder
    private var subtleBackground: some View {
        Group {
            if let tint {
                tint.opacity(colorScheme == .dark ? 0.15 : 0.08)
            } else {
                Color(nsColor: .windowBackgroundColor)
                    .opacity(0.9)
            }
        }
        .background(.ultraThinMaterial)
    }
    
    /// Solid opaque background for Reduce Transparency mode.
    @ViewBuilder
    private var solidBackground: some View {
        if let tint {
            tint.opacity(colorScheme == .dark ? 0.2 : 0.1)
                .background(Color(nsColor: .windowBackgroundColor))
        } else {
            Color(nsColor: .windowBackgroundColor)
        }
    }
    
    // MARK: - Border Overlay
    
    @ViewBuilder
    private var borderOverlay: some View {
        if shouldShowBorder {
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    borderColor,
                    lineWidth: differentiateWithoutColor ? 1.5 : 1
                )
        }
    }
    
    /// Border color based on color scheme and accessibility settings.
    private var borderColor: Color {
        if differentiateWithoutColor {
            // Higher contrast border for accessibility
            return colorScheme == .dark
                ? Color.white.opacity(0.3)
                : Color.black.opacity(0.2)
        } else {
            // Subtle border
            return colorScheme == .dark
                ? Color.white.opacity(0.15)
                : Color.black.opacity(0.1)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Applies glass effect styling with automatic accessibility fallbacks.
    ///
    /// This modifier creates a translucent, frosted glass appearance on macOS 26+
    /// that automatically falls back to appropriate styles based on accessibility settings.
    ///
    /// ## Example
    /// ```swift
    /// VStack {
    ///     Text("Hello")
    /// }
    /// .padding()
    /// .glassStyle()
    /// ```
    ///
    /// ## Accessibility
    /// - **Reduce Transparency**: Shows solid background
    /// - **Increase Contrast**: Adds visible border
    /// - **Reduce Motion**: Simplifies animations (handled by system)
    ///
    /// - Parameters:
    ///   - tint: Optional tint color for the glass effect.
    ///   - cornerRadius: Corner radius for the glass container. Default is 12.
    ///   - showBorder: Whether to always show a border. Default is false.
    /// - Returns: A view with glass effect styling applied.
    public func glassStyle(
        tint: Color? = nil,
        cornerRadius: CGFloat = 12,
        showBorder: Bool = false
    ) -> some View {
        modifier(GlassEffectModifier(
            tint: tint,
            cornerRadius: cornerRadius,
            showBorder: showBorder
        ))
    }
    
    /// Applies glass effect styling with no corner radius (full bleed).
    ///
    /// Use this for elements that span the full width of their container
    /// like toolbars and bars.
    ///
    /// - Parameters:
    ///   - tint: Optional tint color for the glass effect.
    ///   - showBorder: Whether to always show a border. Default is false.
    /// - Returns: A view with glass effect styling applied.
    public func glassStyleFullBleed(
        tint: Color? = nil,
        showBorder: Bool = false
    ) -> some View {
        modifier(GlassEffectModifier(
            tint: tint,
            cornerRadius: 0,
            showBorder: showBorder
        ))
    }
}

// MARK: - Animation Helpers

extension View {
    /// Applies animation that respects Reduce Motion accessibility setting.
    ///
    /// When Reduce Motion is enabled, uses a simpler, faster animation.
    /// Otherwise uses the provided animation.
    ///
    /// - Parameter animation: The animation to use when Reduce Motion is off.
    /// - Returns: A view with appropriate animation applied.
    public func accessibilityAnimation(_ animation: Animation = .spring()) -> some View {
        modifier(AccessibilityAnimationModifier(animation: animation))
    }
}

// MARK: - Glass Overlay

/// A reusable glass overlay container for popovers, sheets, and overlays.
///
/// GlassOverlay provides consistent styling across the app:
/// - Glass effect background with accessibility fallbacks
/// - Consistent corner radius (16pt by default for overlays)
/// - Subtle shadow for depth
/// - Optional header with glass styling
///
/// ## Usage
/// ```swift
/// GlassOverlay {
///     VStack {
///         // Your content
///     }
/// }
/// ```
///
/// With custom header:
/// ```swift
/// GlassOverlay(header: "Up Next") {
///     VStack {
///         // Your content
///     }
/// }
/// ```
public struct GlassOverlay<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    
    /// Optional header text displayed at the top of the overlay.
    let header: String?
    
    /// Optional trailing view for the header (e.g., close button).
    let headerTrailing: AnyView?
    
    /// Corner radius for the overlay container.
    let cornerRadius: CGFloat
    
    /// Whether to show a shadow.
    let showShadow: Bool
    
    /// The content to display inside the overlay.
    @ViewBuilder let content: () -> Content
    
    /// Creates a glass overlay container.
    ///
    /// - Parameters:
    ///   - header: Optional header text.
    ///   - headerTrailing: Optional trailing view for the header.
    ///   - cornerRadius: Corner radius for the container. Default is 16.
    ///   - showShadow: Whether to show a shadow. Default is true.
    ///   - content: The content builder.
    public init(
        header: String? = nil,
        headerTrailing: AnyView? = nil,
        cornerRadius: CGFloat = 16,
        showShadow: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.header = header
        self.headerTrailing = headerTrailing
        self.cornerRadius = cornerRadius
        self.showShadow = showShadow
        self.content = content
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header if present
            if let header {
                headerView(title: header)
                Divider()
            }
            
            // Content
            content()
        }
        .background(overlayBackground)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .shadow(
            color: showShadow ? shadowColor : .clear,
            radius: showShadow ? 20 : 0,
            x: 0,
            y: showShadow ? 10 : 0
        )
    }
    
    /// Header view with glass styling.
    @ViewBuilder
    private func headerView(title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
            
            Spacer()
            
            if let trailing = headerTrailing {
                trailing
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassStyleFullBleed()
    }
    
    /// Background for the overlay container.
    @ViewBuilder
    private var overlayBackground: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
    }
    
    /// Shadow color based on color scheme.
    private var shadowColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.4)
            : Color.black.opacity(0.15)
    }
}

// MARK: - GlassOverlay Convenience Initializers

extension GlassOverlay {
    /// Creates a glass overlay with a header and trailing button.
    ///
    /// - Parameters:
    ///   - header: The header title text.
    ///   - trailingButtonTitle: Title for the trailing button.
    ///   - trailingAction: Action when the trailing button is tapped.
    ///   - content: The content builder.
    public init<TrailingButton: View>(
        header: String,
        @ViewBuilder trailingButton: @escaping () -> TrailingButton,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.header = header
        self.headerTrailing = AnyView(trailingButton())
        self.cornerRadius = 16
        self.showShadow = true
        self.content = content
    }
}

// MARK: - Glass Popover Modifier

/// A view modifier that wraps content in a glass-styled popover.
///
/// This modifier provides consistent popover styling with:
/// - Glass background
/// - Spring animation for show/hide
/// - Proper corner radius
///
/// ## Usage
/// ```swift
/// .glassPopover(isPresented: $showPopover) {
///     Text("Popover content")
/// }
/// ```
public struct GlassPopoverModifier<PopoverContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let arrowEdge: Edge
    @ViewBuilder let popoverContent: () -> PopoverContent
    
    public func body(content: Content) -> some View {
        content
            .popover(isPresented: $isPresented, arrowEdge: arrowEdge) {
                popoverContent()
                    .background(.ultraThinMaterial)
            }
    }
}

extension View {
    /// Presents a glass-styled popover.
    ///
    /// - Parameters:
    ///   - isPresented: Binding to control popover visibility.
    ///   - arrowEdge: The edge where the popover arrow appears. Default is .top.
    ///   - content: The popover content builder.
    /// - Returns: A view with a glass popover attached.
    public func glassPopover<Content: View>(
        isPresented: Binding<Bool>,
        arrowEdge: Edge = .top,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(GlassPopoverModifier(
            isPresented: isPresented,
            arrowEdge: arrowEdge,
            popoverContent: content
        ))
    }
}

/// Modifier that provides animation respecting Reduce Motion.
private struct AccessibilityAnimationModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation
    
    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? .easeInOut(duration: 0.15) : animation, value: reduceMotion)
    }
}

// MARK: - Previews

#Preview("Glass Styles") {
    VStack(spacing: 20) {
        ForEach(GlassStyle.allCases, id: \.rawValue) { style in
            Text(style.rawValue.capitalized)
                .padding()
                .frame(width: 200)
                .glassStyle()
                .glassStylePreference(style)
        }
    }
    .padding()
    .background(
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("With Tint") {
    VStack(spacing: 20) {
        Text("Default")
            .padding()
            .frame(width: 200)
            .glassStyle()
        
        Text("Blue Tint")
            .padding()
            .frame(width: 200)
            .glassStyle(tint: .blue)
        
        Text("Orange Tint")
            .padding()
            .frame(width: 200)
            .glassStyle(tint: .orange)
    }
    .padding()
    .background(
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("Full Bleed") {
    VStack {
        Spacer()
        
        HStack {
            Text("Now Playing Bar")
            Spacer()
            Image(systemName: "play.fill")
        }
        .padding()
        .glassStyleFullBleed()
    }
    .frame(width: 400, height: 300)
    .background(
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("Glass Overlay") {
    GlassOverlay(header: "Up Next") {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(0..<5) { i in
                HStack {
                    Text("\(i + 1)")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    Text("Track \(i + 1)")
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    .frame(width: 280)
    .padding()
    .background(
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("Glass Overlay with Button") {
    GlassOverlay(
        header: "Up Next",
        trailingButton: {
            Button("Clear") {}
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
        }
    ) {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(0..<3) { i in
                HStack {
                    Text("\(i + 1)")
                        .foregroundStyle(.secondary)
                    Text("Track \(i + 1)")
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    .frame(width: 280)
    .padding()
    .background(
        LinearGradient(
            colors: [.orange, .red],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
