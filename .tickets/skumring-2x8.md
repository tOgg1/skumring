---
id: skumring-2x8
status: closed
deps: [skumring-v68]
links: []
created: 2026-01-02T17:47:00.12739+01:00
type: task
priority: 1
parent: skumring-dkq
---
# Implement accessibility fallbacks for glass effects

Ensure glass effects work with accessibility settings:

1. Reduce Transparency support:
   - Detect NSWorkspace.accessibilityDisplayShouldReduceTransparency
   - When enabled, replace glass with solid backgrounds
   - Use opaque materials instead

2. Increase Contrast support:
   - Detect high contrast mode
   - Increase border visibility
   - Ensure text has sufficient contrast

3. Reduce Motion:
   - Simplify glass animations
   - Reduce morphing effects
   - Faster/simpler transitions

4. Implementation approach:
   - Create GlassStyle environment value
   - Components check environment and adapt
   - Centralized theme configuration

5. Fallback styles:
   - .solid: opaque background matching theme
   - .subtle: very light transparency
   - .none: no special background

6. Testing checklist:
   - Enable Reduce Transparency: verify solid backgrounds
   - Enable Increase Contrast: verify readability
   - Enable Reduce Motion: verify simpler animations
   - All combinations

7. User preference (optional):
   - App-level override for glass style
   - Settings: Auto / Glass / Simple
   - Auto uses system preferences

8. Color scheme support:
   - Glass works in both light and dark mode
   - Adjust tint for each mode
   - Test both appearances

Acceptance criteria:
- Reduce Transparency shows solid backgrounds
- Increase Contrast improves readability
- All features remain functional with fallbacks
- No visual glitches in fallback mode
- Smooth transition when toggling settings


