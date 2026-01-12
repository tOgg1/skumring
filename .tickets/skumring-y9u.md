---
id: skumring-y9u
status: closed
deps: [skumring-4f9]
links: []
created: 2026-01-02T17:46:41.857257+01:00
type: task
priority: 2
parent: skumring-dkq
---
# Apply Liquid Glass to queue popover and overlays

Add Liquid Glass styling to popovers and overlays:

1. Queue popover:
   - Apply glass to popover container
   - Ensure queue list is readable
   - Glass header 'Up Next'

2. Add Item sheet:
   - Glass header bar
   - Form content on solid/material background
   - Glass buttons (Cancel/Add)

3. Context menus:
   - System context menus may auto-style
   - Custom menus: apply appropriate glass

4. Tooltips and hints:
   - Apply glass to custom tooltips
   - Ensure readability

5. Error/status overlays:
   - Reconnecting overlay with glass
   - Error messages with glass background

6. Volume popover (if separate):
   - Glass container for volume slider
   - Consistent with Now Playing bar

7. Implementation approach:
   - Create reusable GlassOverlay component
   - Consistent corner radius
   - Consistent shadow/depth
   - Consistent animation

8. Transitions:
   - Smooth glass appearance animations
   - Spring animations for popover show/hide
   - Consider matchedGeometryEffect for morphing

Acceptance criteria:
- Queue popover has glass styling
- Add Item sheet has glass accents
- All overlays consistent
- Transitions are smooth
- Readable in all contexts


