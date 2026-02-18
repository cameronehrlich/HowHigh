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

    func testWeatherKitCalibrationPersistence() {
        let suiteName = "HowHigh.SettingsStoreTests.WeatherKit"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        XCTAssertFalse(store.weatherKitAutoCalibrationEnabled)
        XCTAssertNil(store.weatherKitLastCalibrationDate)

        store.weatherKitAutoCalibrationEnabled = true
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        store.applyWeatherKitSeaLevelPressure(hPa: 1015.0, timestamp: timestamp)

        XCTAssertEqual(store.seaLevelPressureKPa, 101.5, accuracy: 0.0001)
        XCTAssertNotNil(store.weatherKitLastCalibrationDate)
        XCTAssertEqual(store.weatherKitLastCalibrationDate!.timeIntervalSince1970, timestamp.timeIntervalSince1970, accuracy: 0.001)

        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertTrue(reloaded.weatherKitAutoCalibrationEnabled)
        XCTAssertEqual(reloaded.seaLevelPressureKPa, 101.5, accuracy: 0.0001)
        XCTAssertNotNil(reloaded.weatherKitLastCalibrationDate)
        XCTAssertEqual(reloaded.weatherKitLastCalibrationDate!.timeIntervalSince1970, timestamp.timeIntervalSince1970, accuracy: 0.001)
    }
}

final class IdleTimerPolicyTests: XCTestCase {
    func testDisablesIdleTimerWhenEnabledUnlessAppIsBackgrounded() {
        XCTAssertTrue(
            IdleTimerPolicy.shouldDisableIdleTimer(
                keepScreenOn: true,
                scenePhase: .active
            )
        )

        XCTAssertFalse(
            IdleTimerPolicy.shouldDisableIdleTimer(
                keepScreenOn: false,
                scenePhase: .active
            )
        )

        XCTAssertTrue(
            IdleTimerPolicy.shouldDisableIdleTimer(
                keepScreenOn: true,
                scenePhase: .inactive
            )
        )

        XCTAssertFalse(
            IdleTimerPolicy.shouldDisableIdleTimer(
                keepScreenOn: true,
                scenePhase: .background
            )
        )
    }
}

final class SensorConfidenceEstimatorTests: XCTestCase {
    func testWarmingUpWithTooFewSamples() {
        let now = Date()
        let readings = makeAltitudeReadings(start: now.addingTimeInterval(-2), count: 3, interval: 0.5, slopePerSecond: 0.2, noiseAmplitude: 0.05)
        let result = SensorConfidenceEstimator.estimate(
            readings: readings,
            mode: .altimeter,
            isCalibrating: false,
            isAvailable: true,
            now: now
        )
        XCTAssertEqual(result.confidence, .warmingUp)
    }

    func testGoodConfidenceWithLowJitter() {
        let now = Date()
        let readings = makeAltitudeReadings(start: now.addingTimeInterval(-7), count: 20, interval: 0.35, slopePerSecond: 0.4, noiseAmplitude: 0.08)
        let result = SensorConfidenceEstimator.estimate(
            readings: readings,
            mode: .altimeter,
            isCalibrating: false,
            isAvailable: true,
            now: now
        )
        XCTAssertEqual(result.confidence, .good)
        XCTAssertNotNil(result.residualRMS)
    }

    func testPoorConfidenceWithHighJitter() {
        let now = Date()
        let readings = makeAltitudeReadings(start: now.addingTimeInterval(-7), count: 20, interval: 0.35, slopePerSecond: 0.4, noiseAmplitude: 2.0)
        let result = SensorConfidenceEstimator.estimate(
            readings: readings,
            mode: .altimeter,
            isCalibrating: false,
            isAvailable: true,
            now: now
        )
        XCTAssertEqual(result.confidence, .poor)
        XCTAssertNotNil(result.residualRMS)
    }

    func testCalibratingOverridesSignal() {
        let now = Date()
        let readings = makeAltitudeReadings(start: now.addingTimeInterval(-7), count: 20, interval: 0.35, slopePerSecond: 0.0, noiseAmplitude: 5.0)
        let result = SensorConfidenceEstimator.estimate(
            readings: readings,
            mode: .altimeter,
            isCalibrating: true,
            isAvailable: true,
            now: now
        )
        XCTAssertEqual(result.confidence, .calibrating)
    }

    func testUnavailableWhenSensorUnavailable() {
        let now = Date()
        let readings = makeAltitudeReadings(start: now.addingTimeInterval(-7), count: 20, interval: 0.35, slopePerSecond: 0.0, noiseAmplitude: 0.1)
        let result = SensorConfidenceEstimator.estimate(
            readings: readings,
            mode: .altimeter,
            isCalibrating: false,
            isAvailable: false,
            now: now
        )
        XCTAssertEqual(result.confidence, .unavailable)
    }
}

final class AltitudeServiceSeaLevelPressureFreezeTests: XCTestCase {
    func testSeaLevelPressureSetWhileNotFrozenAppliesImmediately() {
        let service = AltitudeService(altimeter: nil, queue: OperationQueue())
        XCTAssertEqual(service.currentSeaLevelPressureKPa, 101.325, accuracy: 0.0001)

        service.setSeaLevelPressure(kPa: 99.9)
        XCTAssertEqual(service.currentSeaLevelPressureKPa, 99.9, accuracy: 0.0001)
    }

    func testSeaLevelPressureSetWhileFrozenDefersUntilUnfrozen() {
        let service = AltitudeService(altimeter: nil, queue: OperationQueue())
        let original = service.currentSeaLevelPressureKPa

        service.beginSeaLevelPressureFreeze()
        service.setSeaLevelPressure(kPa: 102.0)
        XCTAssertEqual(service.currentSeaLevelPressureKPa, original, accuracy: 0.0001)

        service.endSeaLevelPressureFreeze()
        XCTAssertEqual(service.currentSeaLevelPressureKPa, 102.0, accuracy: 0.0001)
    }

    func testNestedFreezeDefersUntilFinalEnd() {
        let service = AltitudeService(altimeter: nil, queue: OperationQueue())
        let original = service.currentSeaLevelPressureKPa

        service.beginSeaLevelPressureFreeze()
        service.beginSeaLevelPressureFreeze()
        service.setSeaLevelPressure(kPa: 103.3)
        XCTAssertEqual(service.currentSeaLevelPressureKPa, original, accuracy: 0.0001)

        service.endSeaLevelPressureFreeze()
        XCTAssertEqual(service.currentSeaLevelPressureKPa, original, accuracy: 0.0001)

        service.endSeaLevelPressureFreeze()
        XCTAssertEqual(service.currentSeaLevelPressureKPa, 103.3, accuracy: 0.0001)
    }

    func testLastPendingValueWins() {
        let service = AltitudeService(altimeter: nil, queue: OperationQueue())
        service.beginSeaLevelPressureFreeze()

        service.setSeaLevelPressure(kPa: 100.1)
        service.setSeaLevelPressure(kPa: 100.2)
        service.setSeaLevelPressure(kPa: 100.3)

        service.endSeaLevelPressureFreeze()
        XCTAssertEqual(service.currentSeaLevelPressureKPa, 100.3, accuracy: 0.0001)
    }
}

final class NWSServiceTests: XCTestCase {
    func testComputeSeaLevelPressureFallbackMatchesKnownSample() {
        // Sample from https://api.weather.gov/stations/KLAX/observations/latest (2026-02-08):
        // barometricPressure.value=102065.75 Pa, elevation.value=32 m, seaLevelPressure.value=null
        let stationPressurePa = 102_065.75
        let elevationMeters = 32.0

        let seaLevelHPa = NWSService.computeSeaLevelPressureHPa(
            stationPressurePa: stationPressurePa,
            elevationMeters: elevationMeters
        )

        XCTAssertNotNil(seaLevelHPa)
        XCTAssertEqual(seaLevelHPa!, 1024.538, accuracy: 0.05)
    }

    func testComputeSeaLevelPressureReturnsNilForInvalidElevation() {
        let seaLevelHPa = NWSService.computeSeaLevelPressureHPa(
            stationPressurePa: 100_000,
            elevationMeters: 44_330 // denom becomes 0
        )
        XCTAssertNil(seaLevelHPa)
    }
}

final class BarometricAltitudeEstimatorTests: XCTestCase {
    func testPressureEqualsSeaLevelPressureReturnsNearZero() {
        let meters = BarometricAltitudeEstimator.altitudeMeters(pressureKPa: 101.325, seaLevelPressureKPa: 101.325)
        XCTAssertEqual(meters, 0, accuracy: 0.0001)
    }

    func testLowerPressureYieldsPositiveAltitude() {
        let meters = BarometricAltitudeEstimator.altitudeMeters(pressureKPa: 90.0, seaLevelPressureKPa: 101.325)
        XCTAssertGreaterThan(meters, 0)
    }

    func testHigherPressureYieldsNegativeAltitude() {
        let meters = BarometricAltitudeEstimator.altitudeMeters(pressureKPa: 103.0, seaLevelPressureKPa: 101.325)
        XCTAssertLessThan(meters, 0)
    }
}

final class SessionExportServiceTests: XCTestCase {
    func testBarometerExportWritesPressureDeltaAndPressureAltitudeColumns() throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let samples = [
            AltitudeSample(timestamp: start, relativeAltitudeMeters: 0, pressureKPa: 101.0, absoluteAltitudeMeters: 0),
            AltitudeSample(timestamp: start.addingTimeInterval(1), relativeAltitudeMeters: 0, pressureKPa: 100.5, absoluteAltitudeMeters: 0)
        ]
        let session = AltitudeSession(startDate: start,
                                      endDate: start.addingTimeInterval(1),
                                      samples: samples,
                                      state: .completed,
                                      mode: .barometer)

        let url = try SessionExportService.exportCSV(session: session, preferredUnit: .imperial, pressureUnit: .hectopascals)
        let contents = try String(contentsOf: url, encoding: .utf8)
        let lines = contents.split(separator: "\n", omittingEmptySubsequences: false)
        XCTAssertGreaterThanOrEqual(lines.count, 3)
        XCTAssertEqual(lines[0], "timestamp,pressure_hPa,pressure_delta_hPa,pressure_altitude_ft,pressure_altitude_delta_ft")

        let row1 = lines[1].split(separator: ",")
        let row2 = lines[2].split(separator: ",")
        XCTAssertEqual(row1.count, 5)
        XCTAssertEqual(row2.count, 5)

        let row1Delta = Double(row1[2])!
        let row2Delta = Double(row2[2])!
        XCTAssertEqual(row1Delta, 0, accuracy: 0.0001)
        XCTAssertEqual(row2Delta, -5.0, accuracy: 0.0001)

        let row1Alt = Double(row1[3])!
        let row2Alt = Double(row2[3])!
        XCTAssertNotEqual(row1Alt, 0, accuracy: 0.0001)
        XCTAssertNotEqual(row2Alt, 0, accuracy: 0.0001)
    }
}

private func makeAltitudeReadings(
    start: Date,
    count: Int,
    interval: TimeInterval,
    slopePerSecond: Double,
    noiseAmplitude: Double
) -> [AltitudeReading] {
    var readings: [AltitudeReading] = []
    readings.reserveCapacity(count)
    var t: TimeInterval = 0

    // Deterministic pseudo-noise (no randomness in tests).
    for index in 0..<count {
        let ts = start.addingTimeInterval(t)
        let noise = sin(Double(index) * 1.7) * noiseAmplitude
        let altitude = 100.0 + slopePerSecond * t + noise
        readings.append(
            AltitudeReading(
                timestamp: ts,
                relativeAltitudeMeters: 0,
                pressureKPa: 101.325,
                absoluteAltitudeMeters: altitude
            )
        )
        t += interval
    }
    return readings
}
