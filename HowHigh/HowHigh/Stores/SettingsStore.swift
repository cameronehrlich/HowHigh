import Foundation
import Combine

final class SettingsStore: ObservableObject {
    @Published var preferredUnit: MeasurementUnit
    @Published var pressureUnit: PressureUnit
    @Published var seaLevelPressureKPa: Double
    @Published var altitudeDisplayMode: AltitudeDisplayMode
    @Published var weatherKitAutoCalibrationEnabled: Bool
    @Published private(set) var weatherKitLastCalibrationDate: Date?
    @Published var nwsStationIdentifier: String?
    @Published var nwsStationName: String?
    @Published private(set) var nwsLastCalibrationDate: Date?

    private var cancellables: Set<AnyCancellable> = []
    private let defaults: UserDefaults

    private enum Keys {
        static let preferredUnit = "settings.preferredUnit"
        static let pressureUnit = "settings.pressureUnit"
        static let seaLevelPressure = "settings.seaLevelPressure"
        static let altitudeDisplayMode = "settings.altitudeDisplayMode"
        static let weatherKitAutoCalibrationEnabled = "settings.weatherKitAutoCalibrationEnabled"
        static let weatherKitLastCalibrationTimestamp = "settings.weatherKitLastCalibrationTimestamp"
        static let nwsStationIdentifier = "settings.nwsStationIdentifier"
        static let nwsStationName = "settings.nwsStationName"
        static let nwsLastCalibrationTimestamp = "settings.nwsLastCalibrationTimestamp"
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

        weatherKitAutoCalibrationEnabled = defaults.bool(forKey: Keys.weatherKitAutoCalibrationEnabled)

        let storedTimestamp = defaults.double(forKey: Keys.weatherKitLastCalibrationTimestamp)
        if storedTimestamp > 0 {
            weatherKitLastCalibrationDate = Date(timeIntervalSince1970: storedTimestamp)
        } else {
            weatherKitLastCalibrationDate = nil
        }

        nwsStationIdentifier = defaults.string(forKey: Keys.nwsStationIdentifier)
        nwsStationName = defaults.string(forKey: Keys.nwsStationName)

        let storedNWSTimestamp = defaults.double(forKey: Keys.nwsLastCalibrationTimestamp)
        if storedNWSTimestamp > 0 {
            nwsLastCalibrationDate = Date(timeIntervalSince1970: storedNWSTimestamp)
        } else {
            nwsLastCalibrationDate = nil
        }

        setupBindings()
    }

    func applyWeatherKitSeaLevelPressure(hPa: Double, timestamp: Date = Date()) {
        seaLevelPressureKPa = hPa / 10.0
        weatherKitLastCalibrationDate = timestamp
    }

    func applyNWSSeaLevelPressure(hPa: Double,
                                  stationIdentifier: String,
                                  stationName: String?,
                                  timestamp: Date = Date()) {
        seaLevelPressureKPa = hPa / 10.0
        nwsStationIdentifier = stationIdentifier
        nwsStationName = stationName
        nwsLastCalibrationDate = timestamp
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

        $weatherKitAutoCalibrationEnabled
            .sink { [weak self] enabled in
                self?.defaults.set(enabled, forKey: Keys.weatherKitAutoCalibrationEnabled)
            }
            .store(in: &cancellables)

        $weatherKitLastCalibrationDate
            .sink { [weak self] date in
                if let date {
                    self?.defaults.set(date.timeIntervalSince1970, forKey: Keys.weatherKitLastCalibrationTimestamp)
                } else {
                    self?.defaults.removeObject(forKey: Keys.weatherKitLastCalibrationTimestamp)
                }
            }
            .store(in: &cancellables)

        $nwsStationIdentifier
            .sink { [weak self] stationIdentifier in
                if let stationIdentifier, !stationIdentifier.isEmpty {
                    self?.defaults.set(stationIdentifier, forKey: Keys.nwsStationIdentifier)
                } else {
                    self?.defaults.removeObject(forKey: Keys.nwsStationIdentifier)
                }
            }
            .store(in: &cancellables)

        $nwsStationName
            .sink { [weak self] stationName in
                if let stationName, !stationName.isEmpty {
                    self?.defaults.set(stationName, forKey: Keys.nwsStationName)
                } else {
                    self?.defaults.removeObject(forKey: Keys.nwsStationName)
                }
            }
            .store(in: &cancellables)

        $nwsLastCalibrationDate
            .sink { [weak self] date in
                if let date {
                    self?.defaults.set(date.timeIntervalSince1970, forKey: Keys.nwsLastCalibrationTimestamp)
                } else {
                    self?.defaults.removeObject(forKey: Keys.nwsLastCalibrationTimestamp)
                }
            }
            .store(in: &cancellables)
    }
}
