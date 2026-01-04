# Gotchas / Pitfalls

Status: evolving
Last verified: 2026-01-04

Add short entries that prevent repeated failures.

## Format
- **Symptom:** what you see
- **Cause:** why it happens
- **Fix:** exact commands / code pointers

## Entries

### MPMediaItemArtwork closure actor isolation crash

- **Symptom:** App crashes with `EXC_BAD_INSTRUCTION (SIGILL)` and stack trace showing `dispatch_assert_queue_fail` in `NowPlayingService.loadArtwork`. Thread is `*/accessQueue` (MediaPlayer's internal queue).
- **Cause:** `MPMediaItemArtwork`'s `requestHandler` closure is called by MediaPlayer on a background queue, not the main thread. If the closure captures `@MainActor`-isolated state or uses `NSImage` directly, Swift concurrency runtime detects the actor isolation violation.
- **Fix:** Extract `CGImage` from `NSImage` before creating the artwork. Create a fresh `NSImage` from the `CGImage` inside the closure. CGImage is thread-safe once created. See `NowPlayingService.createArtwork(from:)`.

### Test target LibraryItem name collision

- **Symptom:** Build error "Ambiguous use of 'LibraryItem'" in test files.
- **Cause:** `DeveloperToolsSupport` framework has its own `LibraryItem` type that conflicts with the app's model.
- **Fix:** Use `private typealias LibraryItem = Skumring.LibraryItem` at the top of test files that use `LibraryItem`.
