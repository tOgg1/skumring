---
id: skumring-n5d
status: closed
deps: [skumring-8cg, skumring-fm5]
links: []
created: 2026-01-02T17:49:36.120333+01:00
type: task
priority: 2
parent: skumring-a5b
---
# Implement UI tests for core workflows

Create UI tests for key user workflows:

1. Playlist workflow test:
   - Create new playlist
   - Add items to playlist
   - Reorder items
   - Export playlist
   - Import into clean library
   - Verify imported correctly

2. Add item workflow test:
   - Open Add Item sheet
   - Enter stream URL
   - Submit and verify item appears
   - Edit item
   - Delete item

3. Playback workflow test:
   - Select item and play
   - Verify Now Playing shows item
   - Pause/resume
   - Next/previous

4. Search workflow test:
   - Enter search query
   - Verify results filtered
   - Clear search
   - Verify full list returns

5. Import/Export workflow test:
   - Export library to file
   - Clear library (in test)
   - Import from file
   - Verify data restored

6. UI test setup:
   - Use XCUITest framework
   - Set up test library data
   - Clean state before each test
   - Accessibility identifiers for elements

7. Reliability considerations:
   - Wait for animations
   - Handle async loading
   - Avoid flaky timing issues
   - Use explicit waits

8. CI integration:
   - Tests run on CI
   - Screenshots on failure
   - Test reports

Acceptance criteria:
- Core workflows covered by UI tests
- Tests pass reliably (no flaky tests)
- Tests run in reasonable time (<2 min total)
- Failures produce useful diagnostics


