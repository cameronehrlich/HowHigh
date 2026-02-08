import Foundation

enum AltitudeTrend: String, Codable {
    case rising
    case falling
    case steady

    var systemImageName: String {
        switch self {
        case .rising:
            return "arrow.up"
        case .falling:
            return "arrow.down"
        case .steady:
            // Avoid looking like a navigation affordance.
            return "minus"
        }
    }

    // Backwards-compatible default (pressure-centric) strings.
    var descriptionKey: String { pressureDescriptionKey }

    var pressureDescriptionKey: String {
        switch self {
        case .rising:
            return "trend.description.rising"
        case .falling:
            return "trend.description.falling"
        case .steady:
            return "trend.description.steady"
        }
    }

    var altitudeDescriptionKey: String {
        switch self {
        case .rising:
            return "trend.altitude.rising"
        case .falling:
            return "trend.altitude.falling"
        case .steady:
            return "trend.altitude.steady"
        }
    }
}
