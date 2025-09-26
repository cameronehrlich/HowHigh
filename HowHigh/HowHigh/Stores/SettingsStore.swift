import Foundation
import Combine

final class SettingsStore: ObservableObject {
    @Published var preferredUnit: MeasurementUnit
    @Published var seaLevelPressureKPa: Double

    private var cancellables: Set<AnyCancellable> = []
    private let defaults: UserDefaults

    private enum Keys {
        static let preferredUnit = "settings.preferredUnit"
        static let seaLevelPressure = "settings.seaLevelPressure"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let storedUnit = defaults.string(forKey: Keys.preferredUnit), let unit = MeasurementUnit(rawValue: storedUnit) {
            preferredUnit = unit
        } else {
            preferredUnit = .metric
        }

        let storedPressure = defaults.double(forKey: Keys.seaLevelPressure)
        seaLevelPressureKPa = storedPressure == 0 ? 101.325 : storedPressure

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
    }
}
