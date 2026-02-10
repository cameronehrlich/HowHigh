import Foundation

enum BarometricAltitudeEstimator {
    // Standard atmosphere approximation (no temperature compensation).
    // Returns altitude in meters; can be negative if pressure > reference pressure.
    static func altitudeMeters(pressureKPa: Double, seaLevelPressureKPa: Double) -> Double {
        guard pressureKPa > 0, seaLevelPressureKPa > 0 else { return 0 }
        let ratio = pressureKPa / seaLevelPressureKPa
        return 44330.0 * (1.0 - pow(ratio, 0.1903))
    }
}

