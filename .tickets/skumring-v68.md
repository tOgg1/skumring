---
id: skumring-v68
status: closed
deps: [skumring-a16]
links: []
created: 2026-01-02T17:46:09.307769+01:00
type: task
priority: 1
parent: skumring-dkq
---
# Apply Liquid Glass to Now Playing bar

Add Liquid Glass styling to the Now Playing bar:

1. Glass effect application:
   - Apply glassEffect modifier to Now Playing bar container
   - Use GlassEffectContainer to wrap related controls
   - Configure appropriate glass style for bar elements

2. Design considerations:
   - Now Playing bar is prime candidate for glass (overlay element)
   - Ensure text remains readable against glass
   - Use proper contrast for icons and controls

3. Implementation steps:
   - Wrap NowPlayingBar in GlassEffectContainer
   - Apply .glassEffect() modifier to bar background
   - Apply modifiers AFTER layout modifiers
   - Test with various content behind bar

4. Control styling:
   - Playback buttons should have glass-compatible appearance
   - Volume slider styled appropriately
   - Consider .interactive configuration for buttons

5. Tint configuration:
   - Use subtle tint if desired (from artwork colors)
   - Or use neutral glass
   - Ensure accessibility

6. Fallback for older macOS:
   - Check for API availability
   - Fall back to .ultraThinMaterial if Liquid Glass unavailable
   - Use @available checks

7. Accessibility:
   - Test with Reduce Transparency enabled
   - Ensure Increase Contrast works
   - Provide fallback solid background if needed

Acceptance criteria:
- Now Playing bar has glass effect on macOS 26
- Text and controls remain readable
- Falls back gracefully on older systems
- Respects accessibility settings
- Performance is smooth


