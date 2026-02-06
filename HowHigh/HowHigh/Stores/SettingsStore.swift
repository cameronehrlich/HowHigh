import Foundation
import Combine

final class SettingsStore: ObservableObject {
    @Published var preferredUnit: MeasurementUnit
    @Published var pressureUnit: PressureUnit
    @Published var seaLevelPressureKPa: Double
    @Published var altitudeDisplayMode: AltitudeDisplayMode

    private var cancellables: Set<AnyCancellable> = []
    private let defaults: UserDefaults

    private enum Keys {
        static let preferredUnit = "settings.preferredUnit"
        static let pressureUnit = "settings.pressureUnit"
        static let seaLevelPressure = "settings.seaLevelPressure"
        static let altitudeDisplayMode = "settings.altitudeDisplayMode"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let storedUnit = defaults.string(forKey: Keys.preferredUnit), let unit = MeasurementUnit(rawValue: storedUnit) {
            preferredUnit = unit
        } else {
            preferredUnit = .metric
        }

        if let storedPressureUnit = defaults.string(forKey: Keys.pressureUnit),
           let unit = PressureUnit(rawValue: storedPressureUnit) {
            pressureUnit = unit
        } else {
            pressureUnit = .hectopascals
        }

        let storedPressure = defaults.double(forKey: Keys.seaLevelPressure)
        seaLevelPressureKPa = storedPressure == 0 ? 101.325 : storedPressure

        if let storedMode = defaults.string(forKey: Keys.altitudeDisplayMode),
           let mode = AltitudeDisplayMode(rawValue: storedMode) {
            altitudeDisplayMode = mode
        } else {
            altitudeDisplayMode = .gain
        }

        setupBindings()
    }

    private func setupBindings() {
        $preferredUnit
            .sink { [weak self] unit in
                self?.defaults.set(unit.rawValue, forKey: Keys.preferredUnit)
            }
            .store(in: &cancellables)

        $seaLevelPressureKPa
            .sink { [weak self] pressure in
                self?.defaults.set(pressure, forKey: Keys.seaLevelPressure)
            }
            .store(in: &cancellables)

        $pressureUnit
            .sink { [weak self] unit in
                self?.defaults.set(unit.rawValue, forKey: Keys.pressureUnit)
            }
            .store(in: &cancellables)

        $altitudeDisplayMode
            .sink { [weak self] mode in
                self?.defaults.set(mode.rawValue, forKey: Keys.altitudeDisplayMode)
            }
            .store(in: &cancellables)
    }
}
