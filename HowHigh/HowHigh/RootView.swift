import SwiftUI

struct RootView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var sessionStore: SessionStore
    @ObservedObject var altitudeService: AltitudeService
    @ObservedObject var atmosphereStore: AtmosphereStore

    @StateObject private var barometerViewModel: MeasureViewModel
    @StateObject private var altimeterViewModel: MeasureViewModel

    init(settingsStore: SettingsStore,
         sessionStore: SessionStore,
         altitudeService: AltitudeService,
         atmosphereStore: AtmosphereStore) {
        _settingsStore = ObservedObject(initialValue: settingsStore)
        _sessionStore = ObservedObject(initialValue: sessionStore)
        _altitudeService = ObservedObject(initialValue: altitudeService)
        _atmosphereStore = ObservedObject(initialValue: atmosphereStore)
        _barometerViewModel = StateObject(wrappedValue: MeasureViewModel(mode: .barometer,
                                                                         altitudeService: altitudeService,
                                                                         sessionStore: sessionStore,
                                                                         settingsStore: settingsStore))
        _altimeterViewModel = StateObject(wrappedValue: MeasureViewModel(mode: .altimeter,
                                                                         altitudeService: altitudeService,
                                                                         sessionStore: sessionStore,
                                                                         settingsStore: settingsStore))
    }

    var body: some View {
        TabView {
            MeasureView(viewModel: barometerViewModel, settingsStore: settingsStore)
                .tabItem {
                    Label(String(localized: "tab.barometer.title"), systemImage: "gauge")
                }

            MeasureView(viewModel: altimeterViewModel, settingsStore: settingsStore)
                .tabItem {
                    Label(String(localized: "tab.altimeter.title"), systemImage: "mountain.2")
                }

            ProfileView(settingsStore: settingsStore, atmosphereStore: atmosphereStore)
                .tabItem {
                    Label(String(localized: "tab.profile.title"), systemImage: "person")
                }
        }
    }
}

#Preview {
    let settings = SettingsStore()
    let sessionStore = SessionStore(controller: PersistenceController(inMemory: true))
    let service = AltitudeService.preview
    let atmosphere = AtmosphereStore.preview()
    return RootView(settingsStore: settings,
                    sessionStore: sessionStore,
                    altitudeService: service,
                    atmosphereStore: atmosphere)
}
