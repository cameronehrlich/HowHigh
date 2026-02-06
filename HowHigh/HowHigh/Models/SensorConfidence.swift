import Foundation

enum SensorConfidence: String, Codable {
    case unavailable
    case calibrating
    case warmingUp
    case good
    case poor

    var labelLocalizationKey: String {
        switch self {
        case .unavailable:
            return "measure.confidence.unavailable"
        case .calibrating:
            return "measure.confidence.calibrating"
        case .warmingUp:
            return "measure.confidence.warmingUp"
        case .good:
            return "measure.confidence.good"
        case .poor:
            return "measure.confidence.poor"
        }
    }

    var systemImageName: String {
        switch self {
        case .unavailable:
            return "xmark.octagon.fill"
        case .calibrating:
            return "waveform.path.ecg"
        case .warmingUp:
            return "hourglass"
        case .good:
            return "checkmark.seal.fill"
        case .poor:
            return "exclamationmark.triangle.fill"
        }
    }
}

struct SensorConfidenceEstimator {
    struct Result: Equatable {
        let confidence: SensorConfidence
        let residualRMS: Double?
        let sampleCount: Int
    }

    static func estimate(
        readings: [AltitudeReading],
        mode: AltitudeSession.Mode,
        isCalibrating: Bool,
        isAvailable: Bool,
        now: Date
    ) -> Result {
        guard isAvailable else {
            return Result(confidence: .unavailable, residualRMS: nil, sampleCount: 0)
        }
        if isCalibrating {
            return Result(confidence: .calibrating, residualRMS: nil, sampleCount: readings.count)
        }

        // Restrict to a short recency window so the UI reflects current conditions.
        let windowSeconds: TimeInterval = 8
        let recent = readings
            .filter { now.timeIntervalSince($0.timestamp) <= windowSeconds }
            .sorted { $0.timestamp < $1.timestamp }

        if recent.count < 6 {
            return Result(confidence: .warmingUp, residualRMS: nil, sampleCount: recent.count)
        }

        // Estimate jitter by fitting a line over time and measuring residual RMS.
        let t0 = recent.first!.timestamp
        var t: [Double] = []
        var y: [Double] = []
        t.reserveCapacity(recent.count)
        y.reserveCapacity(recent.count)

        for reading in recent {
            t.append(reading.timestamp.timeIntervalSince(t0))
            switch mode {
            case .altimeter:
                y.append(reading.absoluteAltitudeMeters)
            case .barometer:
                y.append(reading.pressureKPa)
            }
        }

        let fit = linearFit(x: t, y: y)
        guard let fit else {
            return Result(confidence: .poor, residualRMS: nil, sampleCount: recent.count)
        }

        let residuals = zip(t, y).map { (ti, yi) in yi - (fit.intercept + fit.slope * ti) }
        let rms = rootMeanSquare(residuals)

        let threshold: Double
        switch mode {
        case .altimeter:
            threshold = 0.6 // meters
        case .barometer:
            threshold = 0.015 // kPa (0.15 hPa)
        }

        let confidence: SensorConfidence = (rms <= threshold) ? .good : .poor
        return Result(confidence: confidence, residualRMS: rms, sampleCount: recent.count)
    }

    private struct LinearFit {
        let intercept: Double
        let slope: Double
    }

    private static func linearFit(x: [Double], y: [Double]) -> LinearFit? {
        guard x.count == y.count, x.count >= 2 else { return nil }
        let n = Double(x.count)
        let meanX = x.reduce(0, +) / n
        let meanY = y.reduce(0, +) / n

        var sxx: Double = 0
        var sxy: Double = 0
        for (xi, yi) in zip(x, y) {
            let dx = xi - meanX
            sxx += dx * dx
            sxy += dx * (yi - meanY)
        }
        guard sxx > 0 else { return nil }
        let slope = sxy / sxx
        let intercept = meanY - slope * meanX
        return LinearFit(intercept: intercept, slope: slope)
    }

    private static func rootMeanSquare(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sumSquares = values.reduce(0) { $0 + $1 * $1 }
        return sqrt(sumSquares / Double(values.count))
    }
}

