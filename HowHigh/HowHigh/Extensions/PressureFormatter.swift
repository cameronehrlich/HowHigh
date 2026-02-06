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
        formatted(kPa: value, unit: .hectopascals)
    }

    static func kilopascals(_ value: Double) -> String {
        formatted(kPa: value, unit: .kilopascals)
    }

    static func measurement(fromKPa value: Double, unit: PressureUnit) -> Measurement<UnitPressure> {
        Measurement(value: unit.value(fromKPa: value), unit: unit.unit)
    }

    static func formatted(kPa value: Double, unit: PressureUnit) -> String {
        measurementFormatter.string(from: measurement(fromKPa: value, unit: unit))
    }

    static func formatted(hPa value: Double, unit: PressureUnit) -> String {
        measurementFormatter.string(from: Measurement(value: unit.value(fromHPa: value), unit: unit.unit))
    }
}
