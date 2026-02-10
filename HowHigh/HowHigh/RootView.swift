import SwiftUI
import CoreLocation

struct RootView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var sessionStore: SessionStore
    @ObservedObject var altitudeService: AltitudeService

    @StateObject private var barometerViewModel: MeasureViewModel
    @StateObject private var altimeterViewModel: MeasureViewModel
    @StateObject private var atmosphereStore: AtmosphereStore = AtmosphereStore()
    @State private var didAttemptAutoWeatherKitCalibration: Bool = false

    init(settingsStore: SettingsStore,
         sessionStore: SessionStore,
         altitudeService: AltitudeService) {
        _settingsStore = ObservedObject(initialValue: settingsStore)
        _sessionStore = ObservedObject(initialValue: sessionStore)
        _altitudeService = ObservedObject(initialValue: altitudeService)
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
        .task {
            await attemptAutoWeatherKitCalibrationIfNeeded()
        }
    }

    private func attemptAutoWeatherKitCalibrationIfNeeded() async {
        guard !didAttemptAutoWeatherKitCalibration else { return }
        didAttemptAutoWeatherKitCalibration = true

        guard settingsStore.weatherKitAutoCalibrationEnabled else { return }

        let status = CLLocationManager().authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else { return }

        if let last = settingsStore.weatherKitLastCalibrationDate,
           Date().timeIntervalSince(last) < 12 * 60 * 60 {
            return
        }

        await atmosphereStore.refresh()
        if let observation = atmosphereStore.latestObservation {
            settingsStore.applyWeatherKitSeaLevelPressure(hPa: observation.seaLevelPressureHPa, timestamp: observation.timestamp)
        }
    }
}

#Preview {
    let settings = SettingsStore()
    let sessionStore = SessionStore(controller: PersistenceController(inMemory: true))
    let service = AltitudeService.preview
    return RootView(settingsStore: settings,
                    sessionStore: sessionStore,
                    altitudeService: service)
}
