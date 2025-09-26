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
            return "arrow.right"
        }
    }

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
