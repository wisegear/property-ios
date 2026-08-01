//
//  PropertyUITests.swift
//  PropertyUITests
//
//  Created by Lee Wisener on 23/07/2026.
//

import XCTest

final class PropertyUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // XCUIAutomation Documentation
        // https://developer.apple.com/documentation/xcuiautomation
    }

    @MainActor
    func testStressDashboardLoadsRevisedLayout() throws {
        let app = XCUIApplication()
        app.launch()

        app.staticTexts["Stress Dashboard"].firstMatch.tap()

        XCTAssertTrue(app.staticTexts["Property Market Stress"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Overall stress index"].exists)
        XCTAssertTrue(app.staticTexts["How statuses work"].exists)
        XCTAssertTrue(app.staticTexts["Positive"].firstMatch.exists)
        XCTAssertTrue(app.staticTexts["Warning"].firstMatch.exists)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Revised stress dashboard"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    @MainActor
    func testHomePageExplainsTheAppAndSalesSearch() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["Property research, all in one place"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Search sales data in England & Wales"].exists)
        XCTAssertTrue(app.staticTexts["(Not available in Scotland or NI)"].exists)
        XCTAssertFalse(app.staticTexts["Find a property"].exists)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Revised home page"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    @MainActor
    func testExplorePagesUseDedicatedHeaders() throws {
        let app = XCUIApplication()
        app.launch()

        app.staticTexts["Market Dashboard"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["NATIONAL MARKET"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["England & Wales"].exists)
        let marketScreenshot = XCTAttachment(screenshot: app.screenshot())
        marketScreenshot.name = "Market dashboard header"
        marketScreenshot.lifetime = .keepAlways
        add(marketScreenshot)

        app.navigationBars.buttons.firstMatch.tap()
        app.swipeUp()
        app.staticTexts["Swap Rates"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["MORTGAGE PRICING SIGNALS"].waitForExistence(timeout: 10))
        let swapScreenshot = XCTAttachment(screenshot: app.screenshot())
        swapScreenshot.name = "Swap rates header"
        swapScreenshot.lifetime = .keepAlways
        add(swapScreenshot)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
