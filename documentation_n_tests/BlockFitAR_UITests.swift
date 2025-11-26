import XCTest

final class BlockFitAR_UITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchAndNavigateToLevelSelect() throws {
        let app = XCUIApplication()
        app.launch()

        // Expect the Level Select tab/icon exists
        let levelTab = app.buttons["LevelsTab"]
        XCTAssertTrue(levelTab.waitForExistence(timeout: 5), "Levels tab should exist")

        levelTab.tap()

        // Confirm Level Select screen is visible
        let levelTitle = app.staticTexts["Level Select"]
        XCTAssertTrue(levelTitle.waitForExistence(timeout: 5), "Level Select screen should display")
    }

    func testTapLevelAndLoadARScene() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Level Select
        app.buttons["LevelsTab"].tap()

        // Tap first level (use accessibility identifier)
        let levelButton = app.buttons["LevelButton_1"]
        XCTAssertTrue(levelButton.waitForExistence(timeout: 5), "Level 1 button should exist")

        levelButton.tap()

        // Detect AR coaching overlay text
        let coachingOverlay = app.staticTexts["move_device_message"]
        XCTAssertTrue(
            coachingOverlay.waitForExistence(timeout: 8),
            "ARKit coaching overlay should appear"
        )
    }

    func testMockLevelCompletionFlow() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Level Select
        app.buttons["LevelsTab"].tap()

        // Tap level
        let levelButton = app.buttons["LevelButton_1"]
        XCTAssertTrue(levelButton.waitForExistence(timeout: 5))
        levelButton.tap()

        // Instead of real AR interaction, press a hidden debug "Complete Level" button
        // Add this button ONLY in DEBUG builds
        let debugCompleteButton = app.buttons["DebugComplete"]
        XCTAssertTrue(debugCompleteButton.waitForExistence(timeout: 5))

        debugCompleteButton.tap()

        // Confirm results screen appears
        let resultsLabel = app.staticTexts["LevelComplete"]
        XCTAssertTrue(resultsLabel.waitForExistence(timeout: 5),
                      "Results screen should appear after level completion")
    }
}
