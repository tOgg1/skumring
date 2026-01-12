---
id: skumring-z464
status: closed
deps: []
links: []
created: 2026-01-04T07:26:53.266446+01:00
type: feature
priority: 2
---
# Update NowPlayingBar to use iOS 26 Liquid Glass styling

Update the NowPlayingBar component to use the new Liquid Glass design language introduced in iOS/macOS 26.

**Reference:** https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass

**Implementation:**
- Apply .glassEffect() modifier to the NowPlayingBar container
- Use appropriate glass prominence (.regular, .subtle, or .prominent) based on context
- Ensure proper contrast for text and controls over the glass background
- Handle Reduce Transparency accessibility setting gracefully (fall back to solid background)
- Consider using .containerBackground() for proper edge-to-edge glass appearance

**Design considerations:**
- The bar should feel integrated with the window chrome
- Controls and text should remain highly legible
- Artwork thumbnail should work well against the translucent background
- Progress bar/seek slider should be visible and interactive

**Testing:**
- Verify appearance with different window backgrounds
- Test with Reduce Transparency enabled
- Ensure controls remain accessible and usable


