import XCTest
@testable import HowHigh

final class AltitudeSessionMetricsTests: XCTestCase {
    func testAscentAndDescentCalculations() {
        let start = Date()
        let samples = [
            AltitudeSample(timestamp: start, relativeAltitudeMeters: 0, pressureKPa: 101.3, absoluteAltitudeMeters: 100),
            AltitudeSample(timestamp: start.addingTimeInterval(10), relativeAltitudeMeters: 5, pressureKPa: 101.0, absoluteAltitudeMeters: 105),
            AltitudeSample(timestamp: start.addingTimeInterval(20), relativeAltitudeMeters: -2, pressureKPa: 100.8, absoluteAltitudeMeters: 103),
            AltitudeSample(timestamp: start.addingTimeInterval(30), relativeAltitudeMeters: 8, pressureKPa: 100.5, absoluteAltitudeMeters: 111)
        ]
        var session = AltitudeSession(startDate: start)
        session.samples = samples
        session.endDate = start.addingTimeInterval(30)

        XCTAssertEqual(session.totalAscentMeters, 13, accuracy: 0.001)
        XCTAssertEqual(session.totalDescentMeters, 2, accuracy: 0.001)
        XCTAssertEqual(session.duration, 30, accuracy: 0.001)
        XCTAssertEqual(session.maxAltitudeMeters, 111, accuracy: 0.001)
        XCTAssertEqual(session.minAltitudeMeters, 100, accuracy: 0.001)
    }

    func testNetAltitudeChange() {
        let start = Date()
        let samples = [
            AltitudeSample(timestamp: start, relativeAltitudeMeters: 0, pressureKPa: 101.3, absoluteAltitudeMeters: 120),
            AltitudeSample(timestamp: start.addingTimeInterval(10), relativeAltitudeMeters: 0, pressureKPa: 101.0, absoluteAltitudeMeters: 132),
            AltitudeSample(timestamp: start.addingTimeInterval(20), relativeAltitudeMeters: 0, pressureKPa: 100.8, absoluteAltitudeMeters: 128)
        ]
        var session = AltitudeSession(startDate: start)
        session.samples = samples

        XCTAssertEqual(session.netAltitudeChangeMeters, 8, accuracy: 0.001)
    }
}

final class PressureUnitTests: XCTestCase {
    func testPressureUnitConversionFromKPa() {
        XCTAssertEqual(PressureUnit.hectopascals.value(fromKPa: 101.3), 1013, accuracy: 0.001)
        XCTAssertEqual(PressureUnit.kilopascals.value(fromKPa: 101.3), 101.3, accuracy: 0.001)
    }

    func testPressureFormatterMeasurementUsesSelectedUnit() {
        let hpaMeasurement = PressureFormatter.measurement(fromKPa: 100.0, unit: .hectopascals)
        XCTAssertEqual(hpaMeasurement.unit, UnitPressure.hectopascals)
        XCTAssertEqual(hpaMeasurement.value, 1000, accuracy: 0.001)

        let kpaMeasurement = PressureFormatter.measurement(fromKPa: 100.0, unit: .kilopascals)
        XCTAssertEqual(kpaMeasurement.unit, UnitPressure.kilopascals)
        XCTAssertEqual(kpaMeasurement.value, 100, accuracy: 0.001)
    }
}

final class SettingsStoreTests: XCTestCase {
    func testPressureUnitAndDisplayModePersistence() {
        let suiteName = "HowHigh.SettingsStoreTests"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        XCTAssertEqual(store.pressureUnit, .hectopascals)
        XCTAssertEqual(store.altitudeDisplayMode, .gain)

        store.pressureUnit = .kilopascals
        store.altitudeDisplayMode = .net

        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertEqual(reloaded.pressureUnit, .kilopascals)
        XCTAssertEqual(reloaded.altitudeDisplayMode, .net)
    }
}
