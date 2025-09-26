import Foundation

enum PressureFormatter {
    private static let measurementFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.unitStyle = .medium
        formatter.locale = .autoupdatingCurrent
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }()

    static func hectopascals(fromKilopascals value: Double) -> String {
        let measurement = Measurement(value: value * 10.0, unit: UnitPressure.hectopascals)
        return measurementFormatter.string(from: measurement)
    }

    static func kilopascals(_ value: Double) -> String {
        let measurement = Measurement(value: value, unit: UnitPressure.kilopascals)
        return measurementFormatter.string(from: measurement)
    }
}
