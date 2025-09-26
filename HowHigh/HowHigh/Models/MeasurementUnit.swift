import Foundation
import SwiftUI

enum MeasurementUnit: String, Codable, CaseIterable, Identifiable {
    case metric
    case imperial

    var id: String { rawValue }

    var displayNameKey: LocalizedStringKey {
        switch self {
        case .metric:
            return "units.metric"
        case .imperial:
            return "units.imperial"
        }
    }

    var altitudeFormatter: MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.unitStyle = .medium
        formatter.locale = .autoupdatingCurrent
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }

    func formattedAltitude(meters: Double) -> String {
        switch self {
        case .metric:
            let measurement = Measurement(value: meters, unit: UnitLength.meters)
            return altitudeFormatter.string(from: measurement)
        case .imperial:
            let feet = Measurement(value: meters, unit: UnitLength.meters).converted(to: .feet)
            return altitudeFormatter.string(from: feet)
        }
    }

    func formattedGain(meters: Double) -> String {
        formattedAltitude(meters: meters)
    }

    func convertedAltitude(from meters: Double) -> Double {
        switch self {
        case .metric:
            return meters
        case .imperial:
            return Measurement(value: meters, unit: UnitLength.meters).converted(to: .feet).value
        }
    }

    var unitSymbol: String {
        switch self {
        case .metric:
            return "m"
        case .imperial:
            return "ft"
        }
    }

    var shortAltitudeDescription: String {
        switch self {
        case .metric:
            return String(localized: "measure.chart.axis.altitude.metric")
        case .imperial:
            return String(localized: "measure.chart.axis.altitude.imperial")
        }
    }
}
