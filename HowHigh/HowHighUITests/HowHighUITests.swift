//
//  HowHighUITests.swift
//  HowHighUITests
//
//  Created by Cameron Ehrlich on 9/16/25.
//

import XCTest

final class HowHighUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testAppRendersAtAccessibilityTextSize() {
        let app = XCUIApplication()
        app.launchArguments += [
            "UITestMode",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXL"
        ]
        app.launch()

        XCTAssertTrue(
            app.staticTexts["measure.sessionSummary.title"].waitForExistence(timeout: 5),
            "Expected summary section to load at accessibility text size."
        )

        activateTab(title: "Altimeter", fallbackIndex: 1, app: app)
        let modeControl = app.descendants(matching: .any)["measure.mode.picker"]
        XCTAssertTrue(
            modeControl.waitForExistence(timeout: 5),
            "Expected display mode picker to be present at accessibility text size."
        )

        activateTab(title: "Settings", fallbackIndex: 2, app: app)
        let unitsControl = app.descendants(matching: .any)["profile.units.picker"]
        XCTAssertTrue(
            unitsControl.waitForExistence(timeout: 5),
            "Expected settings controls to load at accessibility text size."
        )
    }

    private func activateTab(title: String, fallbackIndex: Int, app: XCUIApplication) {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            XCTFail("Tab bar did not appear.")
            return
        }

        let namedButton = tabBar.buttons[title]
        if namedButton.exists {
            namedButton.tap()
            return
        }

        let fallback = tabBar.buttons.element(boundBy: fallbackIndex)
        XCTAssertTrue(fallback.exists, "Fallback tab at index \(fallbackIndex) does not exist.")
        fallback.tap()
    }
}
