# Test Runbook

Status: current
Last verified: 2026-01-03

## Fast checks

```bash
# Build for testing (includes compiling tests)
cd Skumring && xcodebuild -scheme Skumring -destination 'platform=macOS' build-for-testing

# Run unit tests only
cd Skumring && xcodebuild -scheme Skumring -destination 'platform=macOS' test
```

## Full suite / CI parity

```bash
# Run all tests with verbose output
cd Skumring && xcodebuild -scheme Skumring -destination 'platform=macOS' test 2>&1 | xcpretty

# Or without xcpretty
cd Skumring && xcodebuild -scheme Skumring -destination 'platform=macOS' test
```

## UI Tests

```bash
# Run UI tests only (requires app to be built first)
cd Skumring && xcodebuild -scheme Skumring -destination 'platform=macOS' \
  -only-testing:SkumringUITests test

# Run all tests including UI tests
cd Skumring && xcodebuild -scheme Skumring -destination 'platform=macOS' test
```

**Note**: UI tests launch the full app and interact with the UI. They take longer than unit tests (~30-60 seconds).

## Test Structure

- **SkumringTests/**: Unit test target
  - `ImportValidationTests.swift`: Tests for import validation logic
  - `LibraryItemTests.swift`: Tests for LibraryItem model
  - `PackTests.swift`: Tests for Pack model
  - `PlaylistTests.swift`: Tests for Playlist model
  - `PlaybackControllerTests.swift`: Tests for PlaybackController
  - `StreamResolverTests.swift`: Tests for M3U/PLS playlist URL resolution

- **SkumringUITests/**: UI test target
  - `SkumringUITests.swift`: Base test class with helpers
  - `AccessibilityIdentifiers.swift`: Centralized accessibility identifiers
  - `AddItemWorkflowTests.swift`: Tests for Add Item sheet workflow

## Notes

- Unit tests: ~110 tests covering all core models and services
- Unit tests should run in < 5 seconds
- UI tests launch the app and simulate user interaction
- Tests use XCTest framework (standard Swift testing)
- The test targets depend on the main app target
- When referencing `LibraryItem` in tests, use `private typealias` due to name collision with `DeveloperToolsSupport.LibraryItem`

## Test Categories

1. **Model tests**: Initialization, Codable round-trip, JSON schema compliance
2. **Validation tests**: Schema version, item kind, URL validation, malformed JSON
3. **Edge cases**: Unicode, long strings, empty collections, special characters
4. **UI tests**: End-to-end workflow tests (Add Item, Playback, etc.)

## Accessibility Identifiers

UI tests use accessibility identifiers to locate elements. These are defined in:
- `SkumringUITests/AccessibilityIdentifiers.swift` (for tests)
- Corresponding `.accessibilityIdentifier()` modifiers in SwiftUI views

When adding new testable UI elements:
1. Add identifier to `AccessibilityIdentifiers.swift`
2. Add `.accessibilityIdentifier("...")` modifier to the SwiftUI view
3. Write test using the identifier
