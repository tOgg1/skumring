import XCTest

/// Base UI test class with shared setup and helper methods.
///
/// All UI tests inherit from this class to get consistent:
/// - App launch configuration
/// - Wait/assertion helpers
/// - Screenshot capture on failure
class SkumringUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        
        // Configure launch environment for testing
        app.launchEnvironment["UI_TESTING"] = "1"
        
        // Launch the app
        app.launch()
    }
    
    override func tearDownWithError() throws {
        // Take screenshot on failure for diagnostics
        if let failureCount = testRun?.failureCount, failureCount > 0 {
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Failure Screenshot"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        
        app.terminate()
        app = nil
    }
    
    // MARK: - Test Helpers
    
    /// Waits for an element to exist with a timeout.
    /// - Parameters:
    ///   - element: The element to wait for
    ///   - timeout: Maximum time to wait (default 5 seconds)
    /// - Returns: True if element exists within timeout
    @discardableResult
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        element.waitForExistence(timeout: timeout)
    }
    
    /// Waits for an element to disappear with a timeout.
    /// - Parameters:
    ///   - element: The element to wait for
    ///   - timeout: Maximum time to wait (default 5 seconds)
    /// - Returns: True if element no longer exists within timeout
    @discardableResult
    func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    /// Waits for an element to become hittable (visible and enabled).
    /// - Parameters:
    ///   - element: The element to wait for
    ///   - timeout: Maximum time to wait (default 5 seconds)
    /// - Returns: True if element becomes hittable within timeout
    @discardableResult
    func waitForElementToBeHittable(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    /// Takes a named screenshot and attaches it to the test results.
    /// - Parameter name: Name for the screenshot
    func takeScreenshot(named name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
