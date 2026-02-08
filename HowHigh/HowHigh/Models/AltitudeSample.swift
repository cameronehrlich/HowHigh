import Foundation

struct AltitudeSample: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let relativeAltitudeMeters: Double
    let pressureKPa: Double
    let absoluteAltitudeMeters: Double

    init(id: UUID = UUID(), timestamp: Date, relativeAltitudeMeters: Double, pressureKPa: Double, absoluteAltitudeMeters: Double) {
        self.id = id
        self.timestamp = timestamp
        self.relativeAltitudeMeters = relativeAltitudeMeters
        self.pressureKPa = pressureKPa
        self.absoluteAltitudeMeters = absoluteAltitudeMeters
    }
}

extension Array where Element == AltitudeSample {
    func recentTrend(window: TimeInterval = 30) -> AltitudeTrend {
        guard let latest = last else { return .steady }
        let cutoff = latest.timestamp.addingTimeInterval(-window)
        let windowSamples = filter { $0.timestamp >= cutoff }
        guard windowSamples.count >= 2 else { return .steady }
        let first = windowSamples.first!
        let delta = latest.pressureKPa - first.pressureKPa
        if delta > 0.08 {
            return .rising
        } else if delta < -0.08 {
            return .falling
        } else {
            return .steady
        }
    }

    func recentAltitudeTrend(window: TimeInterval = 10) -> AltitudeTrend {
        guard let latest = last else { return .steady }
        let cutoff = latest.timestamp.addingTimeInterval(-window)
        let windowSamples = filter { $0.timestamp >= cutoff }
        guard windowSamples.count >= 2 else { return .steady }
        let first = windowSamples.first!
        let delta = latest.absoluteAltitudeMeters - first.absoluteAltitudeMeters
        if delta > 0.6 {
            return .rising
        } else if delta < -0.6 {
            return .falling
        } else {
            return .steady
        }
    }
}
