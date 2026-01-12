---
id: skumring-ckj
status: closed
deps: [skumring-wyw]
links: []
created: 2026-01-02T17:36:52.989192+01:00
type: task
priority: 0
parent: skumring-fo9
---
# Create Add Item flows (Stream, YouTube, Audio URL)

Implement the UI and logic for adding new items to the library:

1. Add Stream flow:
   - Present sheet/dialog with:
     - URL text field (required) - validate http(s) scheme
     - Title text field (optional, can auto-detect)
     - Tags text field (comma-separated)
     - Artwork URL field (optional)
   - Validation:
     - URL must be valid http(s)
     - Detect if URL ends in .m3u or .pls (mark as stream)
   - Create LibraryItem with kind: .stream

2. Add YouTube flow:
   - Present sheet/dialog with:
     - YouTube URL or video ID field (required)
     - Parse video ID from various URL formats:
       - youtube.com/watch?v=VIDEO_ID
       - youtu.be/VIDEO_ID
       - youtube.com/embed/VIDEO_ID
     - Title field (optional, can fetch from YouTube later)
     - Tags text field
   - Validation:
     - Must extract valid video ID (11 chars alphanumeric)
   - Create LibraryItem with kind: .youtube

3. Add Audio URL flow:
   - Present sheet/dialog with:
     - URL text field (required)
     - Title text field (optional)
     - Tags text field
     - Artwork URL field (optional)
   - Validation:
     - URL must be valid http(s)
     - Warn if URL doesn't look like audio (no .mp3/.m4a/.aac extension)
   - Create LibraryItem with kind: .remoteAudio

4. Shared UI components:
   - AddItemSheet view with segmented control to switch types
   - Form validation with inline error messages
   - Cancel and Add buttons
   - Keyboard shortcut: Cmd+L to open

5. Integration:
   - Wire up to LibraryStore.addItem()
   - Show success feedback
   - Select newly added item in UI

Acceptance criteria:
- Can add all three item types
- Invalid URLs show clear error messages
- YouTube IDs are correctly extracted from various URL formats
- New items appear immediately in library
- Cmd+L opens the Add Item sheet


