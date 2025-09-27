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
        DeviceConfig(name: "iPad Pro 13-inch (M4)", idiom: .pad, launchOptions: ScreenshotLaunchOptions(languageArgument: "-AppleLanguages", localeArgument: "-AppleLocale", extraArguments: []))
    ]

    private let locales: [LocaleConfig] = [
        LocaleConfig(languageCode: "en", localeIdentifier: "en_US", name: "en-US", barometerTitle: "Barometer", altimeterTitle: "Altimeter", profileTitle: "Profile"),
        LocaleConfig(languageCode: "en-GB", localeIdentifier: "en_GB", name: "en-GB", barometerTitle: "Barometer", altimeterTitle: "Altimeter", profileTitle: "Profile"),
        LocaleConfig(languageCode: "es", localeIdentifier: "es_ES", name: "es-ES", barometerTitle: "Barómetro", altimeterTitle: "Altímetro", profileTitle: "Perfil"),
        LocaleConfig(languageCode: "es", localeIdentifier: "es_MX", name: "es-MX", barometerTitle: "Barómetro", altimeterTitle: "Altímetro", profileTitle: "Perfil"),
        LocaleConfig(languageCode: "zh-Hans", localeIdentifier: "zh_Hans", name: "zh-Hans", barometerTitle: "气压计", altimeterTitle: "高度计", profileTitle: "个人资料"),
        LocaleConfig(languageCode: "ja", localeIdentifier: "ja_JP", name: "ja", barometerTitle: "気圧計", altimeterTitle: "高度計", profileTitle: "プロフィール"),
        LocaleConfig(languageCode: "ko", localeIdentifier: "ko_KR", name: "ko", barometerTitle: "기압계", altimeterTitle: "고도계", profileTitle: "프로필"),
        LocaleConfig(languageCode: "de-DE", localeIdentifier: "de_DE", name: "de-DE", barometerTitle: "Barometer", altimeterTitle: "Höhenmesser", profileTitle: "Profil"),
        LocaleConfig(languageCode: "fr-FR", localeIdentifier: "fr_FR", name: "fr-FR", barometerTitle: "Baromètre", altimeterTitle: "Altimètre", profileTitle: "Profil"),
        LocaleConfig(languageCode: "pt-BR", localeIdentifier: "pt_BR", name: "pt-BR", barometerTitle: "Barômetro", altimeterTitle: "Altímetro", profileTitle: "Perfil"),
        LocaleConfig(languageCode: "ru", localeIdentifier: "ru_RU", name: "ru", barometerTitle: "Барометр", altimeterTitle: "Высотомер", profileTitle: "Профиль"),
        LocaleConfig(languageCode: "ar", localeIdentifier: "ar_SA", name: "ar-SA", barometerTitle: "البارومتر", altimeterTitle: "مقياس الارتفاع", profileTitle: "الملف الشخصي")
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
