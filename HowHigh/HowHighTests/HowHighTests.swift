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
}
