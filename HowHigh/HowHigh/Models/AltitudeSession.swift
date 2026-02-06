import Foundation

struct AltitudeSession: Identifiable, Codable {
    enum State: String, Codable {
        case recording
        case completed
    }

    enum Mode: String, Codable, CaseIterable {
        case altimeter
        case barometer
    }

    let id: UUID
    let startDate: Date
    var endDate: Date?
    var samples: [AltitudeSample]
    var note: String?
    var state: State
    var mode: Mode

    init(id: UUID = UUID(),
         startDate: Date = Date(),
         endDate: Date? = nil,
         samples: [AltitudeSample] = [],
         note: String? = nil,
         state: State = .recording,
         mode: Mode = .altimeter) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.samples = samples
        self.note = note
        self.state = state
        self.mode = mode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        samples = try container.decode([AltitudeSample].self, forKey: .samples)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        state = try container.decode(State.self, forKey: .state)
        mode = (try? container.decode(Mode.self, forKey: .mode)) ?? .altimeter
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(startDate, forKey: .startDate)
        try container.encodeIfPresent(endDate, forKey: .endDate)
        try container.encode(samples, forKey: .samples)
        try container.encodeIfPresent(note, forKey: .note)
        try container.encode(state, forKey: .state)
        try container.encode(mode, forKey: .mode)
    }

    var duration: TimeInterval {
        guard let endDate else { return Date().timeIntervalSince(startDate) }
        return endDate.timeIntervalSince(startDate)
    }

    var totalAscentMeters: Double {
        guard samples.count >= 2 else { return 0 }
        var ascent: Double = 0
        for index in 1..<samples.count {
            let gain = samples[index].absoluteAltitudeMeters - samples[index - 1].absoluteAltitudeMeters
            if gain > 0 {
                ascent += gain
            }
        }
        return ascent
    }

    var totalDescentMeters: Double {
        guard samples.count >= 2 else { return 0 }
        var descent: Double = 0
        for index in 1..<samples.count {
            let loss = samples[index - 1].absoluteAltitudeMeters - samples[index].absoluteAltitudeMeters
            if loss > 0 {
                descent += loss
            }
        }
        return descent
    }

    var maxAltitudeMeters: Double {
        samples.map { $0.absoluteAltitudeMeters }.max() ?? 0
    }

    var minAltitudeMeters: Double {
        samples.map { $0.absoluteAltitudeMeters }.min() ?? 0
    }

    var netAltitudeChangeMeters: Double {
        guard let first = samples.first, let last = samples.last else { return 0 }
        return last.absoluteAltitudeMeters - first.absoluteAltitudeMeters
    }

    var pressureTrend: AltitudeTrend {
        samples.recentTrend()
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case startDate
        case endDate
        case samples
        case note
        case state
        case mode
    }
}

extension AltitudeSession {
    static let preview: AltitudeSession = sample(mode: .altimeter)

    static func sample(mode: Mode, minutes: Int = 10) -> AltitudeSession {
        var samples: [AltitudeSample] = []
        let interval: TimeInterval = 15
        let start = Date().addingTimeInterval(TimeInterval(-minutes) * 60)

        for index in 0..<(minutes * 60 / Int(interval)) {
            let timestamp = start.addingTimeInterval(Double(index) * interval)
            switch mode {
            case .altimeter:
                let baseAltitude = 150.0
                let climb = sin(Double(index) / 6.0) * 8.0 + Double(index) * 0.5
                let absolute = baseAltitude + climb
                let relative = absolute - baseAltitude
                let pressure = 101.3 - relative * 0.008
                samples.append(AltitudeSample(timestamp: timestamp,
                                              relativeAltitudeMeters: relative,
                                              pressureKPa: pressure,
                                              absoluteAltitudeMeters: absolute))
            case .barometer:
                let basePressure = 101.5
                let oscillation = sin(Double(index) / 8.0) * 0.6
                let drift = Double(index) * -0.01
                let pressure = basePressure + oscillation + drift
                samples.append(AltitudeSample(timestamp: timestamp,
                                              relativeAltitudeMeters: 0,
                                              pressureKPa: pressure,
                                              absoluteAltitudeMeters: 150))
            }
        }

        let startDate = samples.first?.timestamp ?? Date()
        let endDate = samples.last?.timestamp ?? Date()
        return AltitudeSession(startDate: startDate,
                                endDate: endDate,
                                samples: samples.sorted(by: { $0.timestamp < $1.timestamp }),
                                note: mode == .barometer ? "Pressure front approaching" : "Sunset ridge hike",
                                state: .completed,
                                mode: mode)
    }

    static func uiTestSessions() -> [AltitudeSession] {
        let barometerSession = sample(mode: .barometer, minutes: 15)
        let altimeterSession = sample(mode: .altimeter, minutes: 20)
        return [barometerSession, altimeterSession].sorted(by: { $0.startDate > $1.startDate })
    }
}
