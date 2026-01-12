---
id: skumring-ot5
status: closed
deps: [skumring-ksb]
links: []
created: 2026-01-02T17:46:26.588761+01:00
type: task
priority: 2
parent: skumring-dkq
---
# Apply Liquid Glass to toolbar and sidebar accents

Add Liquid Glass styling to navigation elements:

1. Toolbar glass effects:
   - Search field container
   - Toolbar button groups
   - Apply glass to floating toolbar elements

2. Sidebar accents:
   - Consider glass for sidebar header/title
   - Glass on selected item highlight (if appropriate)
   - Section headers with subtle glass

3. GlassEffectContainer usage:
   - Group related glass elements in containers
   - Per Apple docs: better morphing and performance
   - Avoid too many separate glass regions

4. Design constraints (from spec):
   - DO NOT apply glass to every list row
   - DO NOT stack too many glass layers
   - Keep glass for overlay/navigation elements only

5. Where to apply (recommended):
   - Floating action buttons
   - Popover headers
   - Modal sheet headers
   - Toolbar backgrounds
   - Search container

6. Where NOT to apply:
   - Individual library item cards
   - List row backgrounds
   - Main content background

7. Consistency:
   - Use same glass configuration across app
   - Consistent tint if any
   - Consistent blur amount

8. Performance testing:
   - Test with large library visible
   - Ensure scrolling remains smooth
   - Profile GPU usage

Acceptance criteria:
- Toolbar has glass elements where appropriate
- Glass is NOT overused (per spec constraints)
- Visual noise is minimal
- Performance is acceptable
- Consistent appearance


