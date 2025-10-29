import Foundation
import Combine

final class SettingsStore: ObservableObject {
    @Published var preferredUnit: MeasurementUnit
    @Published var seaLevelPressureKPa: Double
    @Published private(set) var completedSessionsCount: Int
    @Published private(set) var lastReviewRequestDate: Date?

    private var cancellables: Set<AnyCancellable> = []
    private let defaults: UserDefaults

    private enum Keys {
        static let preferredUnit = "settings.preferredUnit"
        static let seaLevelPressure = "settings.seaLevelPressure"
        static let completedSessionsCount = "settings.completedSessionsCount"
        static let lastReviewRequestDate = "settings.lastReviewRequestDate"
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

        completedSessionsCount = defaults.integer(forKey: Keys.completedSessionsCount)

        if let timestamp = defaults.object(forKey: Keys.lastReviewRequestDate) as? TimeInterval {
            lastReviewRequestDate = Date(timeIntervalSince1970: timestamp)
        } else {
            lastReviewRequestDate = nil
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

        $completedSessionsCount
            .sink { [weak self] count in
                self?.defaults.set(count, forKey: Keys.completedSessionsCount)
            }
            .store(in: &cancellables)

        $lastReviewRequestDate
            .sink { [weak self] date in
                if let date {
                    self?.defaults.set(date.timeIntervalSince1970, forKey: Keys.lastReviewRequestDate)
                } else {
                    self?.defaults.removeObject(forKey: Keys.lastReviewRequestDate)
                }
            }
            .store(in: &cancellables)
    }

    func incrementCompletedSessions() {
        completedSessionsCount += 1
    }

    func recordReviewRequested() {
        lastReviewRequestDate = Date()
    }
}
