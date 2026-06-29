import XCTest

final class ScreenshotTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testTakeScreenshots() throws {
        // Wait for the app to load past splash/auth
        let timeout: TimeInterval = 15

        // Wait until main content appears (tab bar or any tab button)
        let tabBar = app.tabBars.firstMatch
        let clientsButton = app.buttons["Клиенты"]
        let taxButton = app.buttons["Налоги"]
        let analyticsButton = app.buttons["Аналитика"]

        // The app uses a custom FloatingTabBar, so look for buttons by label
        // Wait for app to reach main state
        let anyTabButton = app.buttons.matching(NSPredicate(format: "label IN %@", ["Главная", "Клиенты", "Налоги", "Аналитика", "Операции", "Настройки"])).firstMatch
        let appeared = anyTabButton.waitForExistence(timeout: timeout)

        // If the app shows auth/welcome, try to navigate past it
        if !appeared {
            // Take whatever screen we have
            let screenshot = XCUIScreen.main.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "current_state"
            attachment.lifetime = .keepAlways
            add(attachment)
            return
        }

        // --- Clients Tab ---
        let clients = app.buttons.matching(NSPredicate(format: "label == %@", "Клиенты")).firstMatch
        if clients.exists { clients.tap() }
        Thread.sleep(forTimeInterval: 1.0)
        addScreenshot(name: "clients")

        // --- Analytics Tab (Динамика) ---
        let analytics = app.buttons.matching(NSPredicate(format: "label == %@", "Аналитика")).firstMatch
        if analytics.exists { analytics.tap() }
        Thread.sleep(forTimeInterval: 1.5)
        addScreenshot(name: "analytics_dynamics")

        // --- Analytics Tab (Сезонность) ---
        let seasonality = app.buttons["Сезонность"]
        if seasonality.waitForExistence(timeout: 3) { seasonality.tap() }
        Thread.sleep(forTimeInterval: 1.5)
        addScreenshot(name: "analytics_seasonal")

        // --- Taxes Tab ---
        let taxes = app.buttons.matching(NSPredicate(format: "label == %@", "Налоги")).firstMatch
        if taxes.exists { taxes.tap() }
        Thread.sleep(forTimeInterval: 3.0)
        addScreenshot(name: "taxes_npd")
    }

    private func addScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        // Also save to /tmp for easy access
        if let data = screenshot.pngRepresentation as Data? {
            let url = URL(fileURLWithPath: "/tmp/finery_\(name).png")
            try? data.write(to: url)
        }
    }
}
