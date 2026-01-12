---
id: skumring-gxf
status: closed
deps: [skumring-fza, skumring-25r]
links: []
created: 2026-01-02T17:49:18.10323+01:00
type: task
priority: 1
parent: skumring-a5b
---
# Implement integration tests for playback

Create integration tests for playback functionality:

1. AVPlayer integration tests:
   - Test playing a sample MP3 URL
   - Test playing a sample stream (if available)
   - Test play/pause state transitions
   - Test volume changes
   - Test seek (for finite content)

2. YouTube integration tests (smoke):
   - Test WebView loads
   - Test JavaScript bridge responds
   - Test play/pause commands sent
   - Note: Full YouTube tests may require network

3. PlaybackController tests:
   - Test backend routing (stream vs YouTube)
   - Test queue management
   - Test next/previous navigation
   - Test repeat modes
   - Test shuffle behavior

4. State management tests:
   - Test state published correctly
   - Test current item updates
   - Test error states
   - Test playback completion

5. Mock backends:
   - Create MockPlaybackBackend for unit testing
   - Simulates state transitions
   - Allows testing controller logic without real playback

6. Test helpers:
   - Sample audio file in test bundle
   - Known good stream URL (or mock)
   - Async test utilities

7. Performance tests:
   - Playback starts within 2 seconds (spec requirement)
   - Measure startup time

Acceptance criteria:
- AVPlayer can play test audio
- Controller correctly routes to backends
- State updates propagate correctly
- Tests pass reliably in CI
- Mocked tests are fast


