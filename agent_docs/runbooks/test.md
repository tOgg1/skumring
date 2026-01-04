# Test Runbook

Status: current
Last verified: 2026-01-04

## Fast checks

```bash
# Build for testing (includes compiling tests)
cd Skumring && xcodebuild -scheme Skumring -destination 'platform=macOS' build-for-testing

# Run unit tests
cd Skumring && xcodebuild -scheme Skumring -destination 'platform=macOS' test
```

## Full suite / CI parity

```bash
# Run all tests with verbose output
cd Skumring && xcodebuild -scheme Skumring -destination 'platform=macOS' test 2>&1 | xcpretty

# Or without xcpretty
cd Skumring && xcodebuild -scheme Skumring -destination 'platform=macOS' test
```

## Test Structure

- **SkumringTests/**: Unit test target
  - `ImportValidationTests.swift`: Tests for import validation logic
  - `LibraryItemTests.swift`: Tests for LibraryItem model
  - `PackTests.swift`: Tests for Pack model
  - `PlaylistTests.swift`: Tests for Playlist model
  - `PlaybackControllerTests.swift`: Tests for PlaybackController
  - `StreamResolverTests.swift`: Tests for M3U/PLS playlist URL resolution

## Notes

- Unit tests: ~110 tests covering all core models and services
- Unit tests should run in < 5 seconds
- Tests use XCTest framework (standard Swift testing)
- The test target depends on the main app target
- When referencing `LibraryItem` in tests, use `private typealias` due to name collision with `DeveloperToolsSupport.LibraryItem`

## Test Categories

1. **Model tests**: Initialization, Codable round-trip, JSON schema compliance
2. **Validation tests**: Schema version, item kind, URL validation, malformed JSON
3. **Edge cases**: Unicode, long strings, empty collections, special characters
