import Foundation
import Combine

struct InsightCard: Identifiable {
    enum Style {
        case info
        case warning
        case success
    }

    let id = UUID()
    let title: String
    let message: String
    let style: Style
}

@MainActor
final class InsightsViewModel: ObservableObject {
    @Published private(set) var cards: [InsightCard] = []

    private let sessionStore: SessionStore
    private let settingsStore: SettingsStore
    private let atmosphereStore: AtmosphereStore
    private var cancellables: Set<AnyCancellable> = []

    private let temperatureFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.unitStyle = .medium
        formatter.locale = .autoupdatingCurrent
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }()

    init(sessionStore: SessionStore, settingsStore: SettingsStore, atmosphereStore: AtmosphereStore) {
        self.sessionStore = sessionStore
        self.settingsStore = settingsStore
        self.atmosphereStore = atmosphereStore
        sessionStore.$sessions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.rebuildCards()
            }
            .store(in: &cancellables)

        atmosphereStore.$latestObservation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.rebuildCards()
            }
            .store(in: &cancellables)
    }

    private func rebuildCards() {
        let sessions = sessionStore.sessions
        var newCards: [InsightCard] = []

        if let observation = atmosphereStore.latestObservation {
            let pressure = PressureFormatter.hectopascals(fromKilopascals: observation.seaLevelPressureHPa / 10.0)
            let temperatureMeasurement = Measurement(value: observation.temperatureCelsius, unit: UnitTemperature.celsius)
            let temperature = temperatureFormatter.string(from: temperatureMeasurement)
            let trendText = NSLocalizedString(observation.trend.descriptionKey, comment: "")
            let title = String(localized: "insights.card.localPressure.title")
            let format = String(localized: "insights.card.localPressure.message.format", bundle: .main)
            let message = String(format: format, locale: .autoupdatingCurrent, pressure, trendText.localizedLowercase, temperature)
            newCards.append(InsightCard(title: title,
                                        message: message,
                                        style: observation.trend == .falling ? .warning : .info))
        }

        guard !sessions.isEmpty else {
            if newCards.isEmpty {
                newCards = [InsightCard(title: String(localized: "insights.card.empty.title"),
                                        message: String(localized: "insights.card.empty.message"),
                                        style: .info)]
            }
            cards = newCards
            return
        }

        if let latest = sessions.first {
            let unit = settingsStore.preferredUnit
            let ascent = unit.formattedGain(meters: latest.totalAscentMeters)
            let duration = latest.duration.formattedHoursMinutes()
            let lastTitle = String(localized: "insights.card.lastSession.title")
            let lastFormat = String(localized: "insights.card.lastSession.message.format", bundle: .main)
            let lastMessage = String(format: lastFormat, locale: .autoupdatingCurrent, ascent, duration)
            newCards.append(InsightCard(title: lastTitle,
                                        message: lastMessage,
                                        style: .info))
            let trendTitle = String(localized: "insights.card.pressureTrend.title")
            let trendMessage = NSLocalizedString(latest.pressureTrend.descriptionKey, comment: "")
            newCards.append(InsightCard(title: trendTitle,
                                        message: trendMessage,
                                        style: latest.pressureTrend == .falling ? .warning : .info))
        }

        let pressureChanges = sessions.compactMap { session -> Double? in
            guard let first = session.samples.first?.pressureKPa, let last = session.samples.last?.pressureKPa else { return nil }
            return last - first
        }
        if let avgChange = average(pressureChanges), abs(avgChange) > 0.08 {
            let directionKey = avgChange > 0 ? "insights.direction.rising" : "insights.direction.dropping"
            let direction = NSLocalizedString(directionKey, comment: "")
            let title = String(localized: "insights.card.weeklyTrend.title")
            let format = String(localized: "insights.card.weeklyTrend.message.format", bundle: .main)
            let delta = String(format: "%.2f", locale: .autoupdatingCurrent, abs(avgChange))
            let message = String(format: format, locale: .autoupdatingCurrent, direction, delta)
            newCards.append(InsightCard(title: title,
                                        message: message,
                                        style: avgChange < 0 ? .warning : .info))
        }

        if sessions.count >= 5 {
            let totalAscent = sessions.reduce(0) { $0 + $1.totalAscentMeters }
            let unit = settingsStore.preferredUnit
            let formatted = unit.formattedGain(meters: totalAscent)
            let title = String(localized: "insights.card.cumulativeGain.title")
            let format = String(localized: "insights.card.cumulativeGain.message.format", bundle: .main)
            let countString = sessions.count.formatted()
            let message = String(format: format, locale: .autoupdatingCurrent, formatted, countString)
            newCards.append(InsightCard(title: title,
                                        message: message,
                                        style: .success))
        }

        cards = newCards
    }

    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let total = values.reduce(0, +)
        return total / Double(values.count)
    }
}
