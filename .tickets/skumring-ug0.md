---
id: skumring-ug0
status: closed
deps: [skumring-wyw]
links: []
created: 2026-01-02T17:37:50.473128+01:00
type: task
priority: 1
parent: skumring-fo9
---
# Create Built-in Focus Pack with curated content

Create the default built-in content pack for first-time users:

1. Built-in Pack structure:
   - Embedded in app bundle as JSON file
   - Not editable by user (read-only)
   - Clearly labeled as 'Built-in Pack' in sidebar
   - Can be hidden but not deleted

2. Curated content (suggestions - verify these work):
   - LoFi Streams:
     - Lofi Girl Radio (if available as stream)
     - SomaFM Drone Zone
     - SomaFM Groove Salad
   - Jazz Streams:
     - KCSM Jazz
     - Jazz24
   - Ambient Streams:
     - SomaFM Space Station
     - Ambient Sleeping Pill
   - YouTube embeds (select 2-3 known 24/7 streams):
     - Lofi Girl live stream
     - ChilledCow alternatives
     - Jazz/rain ambient mixes

3. Default playlists in pack:
   - 'Focus Now' - mix of lofi/ambient
   - 'Deep Work' - ambient/drone
   - 'Coffee Break' - jazz

4. Implementation:
   - Load from bundle on first launch
   - Copy to library if user wants to customize
   - Version the pack for future updates
   - Check stream health on app updates

5. First launch experience:
   - Show Built-in Pack prominently
   - Big 'Play Focus Now' CTA
   - Tutorial hint about adding custom content

Acceptance criteria:
- Built-in pack loads on first launch
- All streams are playable (test before shipping)
- User can play immediately without adding content
- Pack content is clearly distinguished from user content


