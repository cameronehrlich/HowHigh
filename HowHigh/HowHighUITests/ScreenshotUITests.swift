import XCTest
import UIKit

final class ScreenshotUITests: XCTestCase {
    private struct DeviceConfig {
        let name: String
        let idiom: UIUserInterfaceIdiom
        let launchOptions: ScreenshotLaunchOptions
    }

    private struct ScreenshotLaunchOptions {
        let languageArgument: String
        let localeArgument: String
        let extraArguments: [String]
    }

    private struct LocaleConfig {
        let languageCode: String
        let localeIdentifier: String
        let name: String
        let barometerTitle: String
        let altimeterTitle: String
        let profileTitle: String
    }

    private let devices: [DeviceConfig] = [
        DeviceConfig(name: "iPhone 14 Plus", idiom: .phone, launchOptions: ScreenshotLaunchOptions(languageArgument: "-AppleLanguages", localeArgument: "-AppleLocale", extraArguments: [])),
        DeviceConfig(name: "iPad Pro (12.9-inch) (6th generation)", idiom: .pad, launchOptions: ScreenshotLaunchOptions(languageArgument: "-AppleLanguages", localeArgument: "-AppleLocale", extraArguments: []))
    ]

    private let locales: [LocaleConfig] = [
        LocaleConfig(languageCode: "en", localeIdentifier: "en_US", name: "en-US", barometerTitle: "Barometer", altimeterTitle: "Altimeter", profileTitle: "Profile"),
        LocaleConfig(languageCode: "es", localeIdentifier: "es_ES", name: "es-ES", barometerTitle: "Barómetro", altimeterTitle: "Altímetro", profileTitle: "Perfil")
    ]

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testCaptureLocalizedScreenshots() {
        let currentIdiom = UIDevice.current.userInterfaceIdiom
        for device in devices where device.idiom == currentIdiom {
            for locale in locales {
                let app = XCUIApplication()
                app.launchArguments += ["UITestMode"]
                app.launchArguments += [device.launchOptions.languageArgument, "(\(locale.languageCode))"]
                app.launchArguments += [device.launchOptions.localeArgument, locale.localeIdentifier]
                app.launchArguments += device.launchOptions.extraArguments
                app.launchEnvironment["UITEST_LOCALE"] = locale.languageCode
                app.launchEnvironment["UITEST_DEVICE"] = device.name

                app.launch()
                XCUIDevice.shared.orientation = .portrait
                adjustLayoutIfNeeded(app: app, deviceName: device.name)
                captureScreenshots(for: locale, deviceName: device.name, app: app)
                app.terminate()
            }
        }
    }

    private func captureScreenshots(for locale: LocaleConfig, deviceName: String, app: XCUIApplication) {
        activateTab(withTitle: locale.barometerTitle, app: app)
        waitForMeasureContent(in: app)
        captureScreenshot(name: "\(locale.name)-\(deviceName)-barometer", app: app)

        activateTab(withTitle: locale.altimeterTitle, app: app)
        waitForMeasureContent(in: app)
        captureScreenshot(name: "\(locale.name)-\(deviceName)-altimeter", app: app)

        activateTab(withTitle: locale.profileTitle, app: app)
        waitForProfileContent(in: app)
        captureScreenshot(name: "\(locale.name)-\(deviceName)-profile", app: app)
    }

    private func adjustLayoutIfNeeded(app: XCUIApplication, deviceName: String) {
        if deviceName.contains("iPad") {
            // Placeholder for future iPad-specific adjustments (split view, popovers, etc.).
        }
    }

    private func waitForMeasureContent(in app: XCUIApplication) {
        let summaryTitle = app.staticTexts["measure.sessionSummary.title"]
        XCTAssertTrue(summaryTitle.waitForExistence(timeout: 5.0), "Measure view did not load in time")
    }

    private func waitForProfileContent(in app: XCUIApplication) {
        let slider = app.sliders["profile.seaLevel.slider"]
        XCTAssertTrue(slider.waitForExistence(timeout: 5.0), "Profile view did not load in time")
    }

    private func activateTab(withTitle title: String, app: XCUIApplication) {
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            let button = tabBar.buttons[title]
            XCTAssertTrue(button.waitForExistence(timeout: 5.0), "Expected tab \(title) to exist")
            button.tap()
            return
        }

        let sidebarButton = app.buttons[title].firstMatch
        XCTAssertTrue(sidebarButton.waitForExistence(timeout: 5.0), "Expected sidebar button \(title) to exist")
        sidebarButton.tap()
    }

    private func captureScreenshot(name: String, app: XCUIApplication) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
