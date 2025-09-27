import SwiftUI

@main
struct HowHighApp: App {
    private static let isUITest = ProcessInfo.processInfo.arguments.contains("UITestMode")

    @StateObject private var settingsStore: SettingsStore
    @StateObject private var sessionStore: SessionStore
    @StateObject private var altitudeService: AltitudeService

    init() {
        if Self.isUITest {
            _settingsStore = StateObject(wrappedValue: SettingsStore())
            _sessionStore = StateObject(wrappedValue: SessionStore(controller: PersistenceController(inMemory: true),
                                                                   initialSessions: AltitudeSession.uiTestSessions()))
            _altitudeService = StateObject(wrappedValue: AltitudeService.preview)
        } else {
            _settingsStore = StateObject(wrappedValue: SettingsStore())
            _sessionStore = StateObject(wrappedValue: SessionStore())
            _altitudeService = StateObject(wrappedValue: AltitudeService())
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                settingsStore: settingsStore,
                sessionStore: sessionStore,
                altitudeService: altitudeService
            )
        }
    }
}
