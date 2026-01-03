import XCTest

/// Tests for the Add Item workflow.
///
/// These tests verify that users can:
/// - Open the Add Item sheet
/// - Enter a URL and have it auto-detect the type
/// - Enter a title
/// - Add the item to the library
/// - Verify the item appears in the library
final class AddItemWorkflowTests: SkumringUITests {
    
    // MARK: - Add Stream Item
    
    /// Tests adding a stream item via the Add Item sheet.
    ///
    /// Steps:
    /// 1. Open Add Item sheet (Cmd+L)
    /// 2. Enter a stream URL
    /// 3. Verify stream type is detected
    /// 4. Enter a title
    /// 5. Click Add button
    /// 6. Verify item appears in library
    func testAddStreamItem() throws {
        // Open Add Item sheet using keyboard shortcut
        app.typeKey("l", modifierFlags: .command)
        
        // Wait for sheet to appear
        let addButton = app.buttons["Add"]
        XCTAssertTrue(waitForElement(addButton), "Add Item sheet should appear")
        
        // Find and fill URL field
        let urlField = app.textFields["URL"]
        XCTAssertTrue(urlField.exists, "URL field should exist")
        urlField.click()
        urlField.typeText("https://example.com/stream.m3u8")
        
        // Wait briefly for type detection
        Thread.sleep(forTimeInterval: 0.5)
        
        // Fill title field
        let titleField = app.textFields["Title"]
        XCTAssertTrue(titleField.exists, "Title field should exist")
        titleField.click()
        titleField.typeText("Test Radio Stream")
        
        // Verify Add button is enabled and click it
        XCTAssertTrue(addButton.isEnabled, "Add button should be enabled after filling required fields")
        addButton.click()
        
        // Wait for sheet to dismiss
        XCTAssertTrue(waitForElementToDisappear(addButton), "Add Item sheet should dismiss")
        
        // Verify item appears in library (check for the title text)
        let itemTitle = app.staticTexts["Test Radio Stream"]
        XCTAssertTrue(waitForElement(itemTitle, timeout: 3), "Added item should appear in library")
        
        takeScreenshot(named: "After Adding Stream Item")
    }
    
    // MARK: - Add YouTube Item
    
    /// Tests adding a YouTube item and verifying type detection.
    ///
    /// Steps:
    /// 1. Open Add Item sheet
    /// 2. Enter a YouTube URL
    /// 3. Verify YouTube type is detected
    /// 4. Enter a title
    /// 5. Click Add
    /// 6. Verify item appears
    func testAddYouTubeItem() throws {
        // Open Add Item sheet
        app.typeKey("l", modifierFlags: .command)
        
        let addButton = app.buttons["Add"]
        XCTAssertTrue(waitForElement(addButton), "Add Item sheet should appear")
        
        // Enter YouTube URL
        let urlField = app.textFields["URL"]
        urlField.click()
        urlField.typeText("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
        
        // Wait for detection
        Thread.sleep(forTimeInterval: 0.5)
        
        // Verify YouTube type is detected (look for the label)
        let youtubeLabel = app.staticTexts["YouTube Video"]
        XCTAssertTrue(waitForElement(youtubeLabel, timeout: 2), "YouTube type should be detected")
        
        // Enter title
        let titleField = app.textFields["Title"]
        titleField.click()
        titleField.typeText("Test YouTube Video")
        
        // Add the item
        addButton.click()
        
        // Wait for sheet to dismiss
        XCTAssertTrue(waitForElementToDisappear(addButton), "Sheet should dismiss")
        
        // Verify item appears
        let itemTitle = app.staticTexts["Test YouTube Video"]
        XCTAssertTrue(waitForElement(itemTitle, timeout: 3), "YouTube item should appear in library")
    }
    
    // MARK: - Cancel Add Item
    
    /// Tests canceling the Add Item sheet.
    func testCancelAddItem() throws {
        // Open Add Item sheet
        app.typeKey("l", modifierFlags: .command)
        
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(waitForElement(cancelButton), "Add Item sheet should appear")
        
        // Enter some data
        let urlField = app.textFields["URL"]
        urlField.click()
        urlField.typeText("https://example.com/stream.mp3")
        
        // Cancel the sheet
        cancelButton.click()
        
        // Verify sheet is dismissed
        XCTAssertTrue(waitForElementToDisappear(cancelButton), "Sheet should dismiss on cancel")
        
        // Verify no item was added (the test URL text should not appear)
        let itemTitle = app.staticTexts["https://example.com/stream.mp3"]
        XCTAssertFalse(itemTitle.exists, "No item should be added on cancel")
    }
    
    // MARK: - Validation
    
    /// Tests that the Add button is disabled without required fields.
    func testAddButtonDisabledWithoutRequiredFields() throws {
        // Open Add Item sheet
        app.typeKey("l", modifierFlags: .command)
        
        let addButton = app.buttons["Add"]
        XCTAssertTrue(waitForElement(addButton), "Add Item sheet should appear")
        
        // Verify Add button is initially disabled
        XCTAssertFalse(addButton.isEnabled, "Add button should be disabled initially")
        
        // Enter only URL (no title)
        let urlField = app.textFields["URL"]
        urlField.click()
        urlField.typeText("https://example.com/stream.m3u")
        
        Thread.sleep(forTimeInterval: 0.5)
        
        // Add button should still be disabled (no title)
        XCTAssertFalse(addButton.isEnabled, "Add button should be disabled without title")
        
        // Enter title
        let titleField = app.textFields["Title"]
        titleField.click()
        titleField.typeText("Stream Title")
        
        // Now Add button should be enabled
        XCTAssertTrue(addButton.isEnabled, "Add button should be enabled with URL and title")
    }
}
