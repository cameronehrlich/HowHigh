import Foundation

struct AtmosphericObservation: Identifiable, Codable {
    enum Trend: String, Codable {
        case rising
        case falling
        case steady
    }

    let id: UUID
    let timestamp: Date
    let seaLevelPressureHPa: Double
    let surfacePressureHPa: Double
    let temperatureCelsius: Double
    let conditionDescription: String
    let trend: Trend

    init(id: UUID = UUID(), timestamp: Date, seaLevelPressureHPa: Double, surfacePressureHPa: Double, temperatureCelsius: Double, conditionDescription: String, trend: Trend) {
        self.id = id
        self.timestamp = timestamp
        self.seaLevelPressureHPa = seaLevelPressureHPa
        self.surfacePressureHPa = surfacePressureHPa
        self.temperatureCelsius = temperatureCelsius
        self.conditionDescription = conditionDescription
        self.trend = trend
    }
}

extension AtmosphericObservation.Trend {
    var descriptionKey: String {
        switch self {
        case .rising:
            return "trend.description.rising"
        case .falling:
            return "trend.description.falling"
        case .steady:
            return "trend.description.steady"
        }
    }
}
