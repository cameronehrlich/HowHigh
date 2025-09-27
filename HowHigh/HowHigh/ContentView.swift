import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var altitudeService: AltitudeService

    var body: some View {
        RootView(settingsStore: settingsStore,
                 sessionStore: sessionStore,
                 altitudeService: altitudeService)
    }
}

#Preview {
    let settings = SettingsStore()
    let sessionStore = SessionStore(controller: PersistenceController(inMemory: true))
    let altitudeService = AltitudeService.preview
    return ContentView()
        .environmentObject(settings)
        .environmentObject(sessionStore)
        .environmentObject(altitudeService)
}
