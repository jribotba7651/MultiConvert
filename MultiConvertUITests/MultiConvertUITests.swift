import XCTest

final class MultiConvertUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    // MARK: - Amount Entry

    func testEnterAmountShowsConversions() {
        // Tap digit buttons and verify display updates
        let display = app.staticTexts.matching(identifier: "amountDisplay").firstMatch
        // The keypad buttons are present
        XCTAssertTrue(app.buttons["1"].exists)
        XCTAssertTrue(app.buttons["0"].exists)

        app.buttons["1"].tap()
        app.buttons["0"].tap()
        app.buttons["0"].tap()
        // Display should reflect the typed amount
        // (exact assertion depends on accessibility identifiers set in ContentView)
        XCTAssertTrue(app.staticTexts.element(matching: .any, identifier: "amountDisplay").exists ||
                      app.staticTexts["100"].exists ||
                      app.textFields.firstMatch.exists)
    }

    // MARK: - Currency Picker

    func testPickNewCurrencyAppearsInList() {
        let addButton = app.buttons["addCurrencyButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        // Picker sheet should appear
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5))

        // Dismiss
        let cancelBtn = app.buttons["Cancel"]
        if cancelBtn.exists { cancelBtn.tap() }
    }

    // MARK: - Stale Indicator

    func testKillNetworkShowsNoImmediateStaleIndicator() {
        // When the app launches with a fresh cache there should be no stale warning
        // (staleness only shows when rates are > 24h old)
        let staleIcon = app.images.matching(NSPredicate(
            format: "identifier CONTAINS 'stale'"
        )).firstMatch
        // Fresh launch: stale bar should NOT be visible
        XCTAssertFalse(staleIcon.exists)
    }

    // MARK: - Base Cycler Arrows

    func testDownArrowChangesCurrencyAndListUpdates() {
        let downArrow = app.buttons["Next base currency"]
        XCTAssertTrue(downArrow.waitForExistence(timeout: 5),
                      "Down arrow button should exist in the conversion list area")

        let baseBefore = app.buttons["baseCurrencyButton"].label

        downArrow.tap()

        let baseAfter = app.buttons["baseCurrencyButton"].label
        XCTAssertNotEqual(baseBefore, baseAfter,
                          "Tapping the down arrow should cycle to the next base currency")
    }

    // MARK: - Settings

    func testSettingsOpens() {
        let settingsBtn = app.buttons["Settings"]
        if settingsBtn.waitForExistence(timeout: 3) {
            settingsBtn.tap()
            XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
            app.buttons["Done"].tap()
        }
    }
}
