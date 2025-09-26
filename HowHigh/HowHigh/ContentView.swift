import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var altitudeService: AltitudeService
    @EnvironmentObject var atmosphereStore: AtmosphereStore

    var body: some View {
        RootView(settingsStore: settingsStore,
                 sessionStore: sessionStore,
                 altitudeService: altitudeService,
                 atmosphereStore: atmosphereStore)
    }
}

#Preview {
    let settings = SettingsStore()
    let sessionStore = SessionStore(controller: PersistenceController(inMemory: true))
    let altitudeService = AltitudeService.preview
    let atmosphere = AtmosphereStore.preview()
    return ContentView()
        .environmentObject(settings)
        .environmentObject(sessionStore)
        .environmentObject(altitudeService)
        .environmentObject(atmosphere)
}
