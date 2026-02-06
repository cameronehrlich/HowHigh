import Foundation
import Combine

@MainActor
final class MeasureViewModel: ObservableObject {
    @Published var currentReading: AltitudeReading?
    @Published var isRecording: Bool = false
    @Published var currentSession: AltitudeSession?
    @Published var lastCompletedSession: AltitudeSession?
    @Published var availabilityMessage: String?
    @Published var isCalibrating: Bool = false
    @Published private(set) var recentSessions: [AltitudeSession] = []
    @Published private(set) var confidence: SensorConfidence = .warmingUp

    let mode: AltitudeSession.Mode

    private let altitudeService: AltitudeService
    private let sessionStore: SessionStore
    private let settingsStore: SettingsStore
    private let reviewManager: ReviewManager
    private var cancellables: Set<AnyCancellable> = []
    private var samplesBuffer: [AltitudeSample] = []
    private var sessionStartAltitude: Double?
    private var zeroBaselineAltitude: Double?
    private var pendingCalibration: Bool = false
    private var isMonitoring: Bool = false
    private var recentReadings: [AltitudeReading] = []

    init(mode: AltitudeSession.Mode,
         altitudeService: AltitudeService,
         sessionStore: SessionStore,
         settingsStore: SettingsStore) {
        self.mode = mode
        self.altitudeService = altitudeService
        self.sessionStore = sessionStore
        self.settingsStore = settingsStore
        self.reviewManager = ReviewManager()
        observeSettings()
        subscribeToReadings()
        observeSessionStore()
    }

    var unit: MeasurementUnit { settingsStore.preferredUnit }

    func startRecording() {
        guard !isRecording else { return }
        if !altitudeService.availabilityStatus {
            availabilityMessage = "measure.alert.barometerUnavailable.message"
            return
        }
        sessionStartAltitude = nil
        samplesBuffer.removeAll()
        var session = AltitudeSession(startDate: Date(), mode: mode)
        session.state = .recording
        currentSession = session
        isRecording = true
        altitudeService.startUpdates()
    }

    func pauseRecording() {
        guard isRecording else { return }
        altitudeService.stopUpdates()
        isRecording = false
    }

    func resumeRecording() {
        guard !isRecording, currentSession != nil else { return }
        isRecording = true
        altitudeService.startUpdates()
    }

    func stopRecording() async {
        altitudeService.stopUpdates()
        guard var session = currentSession else { return }
        session.samples = samplesBuffer.sorted(by: { $0.timestamp < $1.timestamp })
        session.endDate = Date()
        session.state = .completed
        session.mode = mode
        currentSession = session
        isRecording = false
        await sessionStore.upsert(session: session)
        samplesBuffer.removeAll()
        sessionStartAltitude = nil
        lastCompletedSession = session
        currentSession = nil

        // Request review at appropriate milestones
        reviewManager.checkAndRequestReview(sessionDuration: session.duration)
    }

    func calibrateToCurrentReading() {
        settingsStore.altitudeDisplayMode = .net
        pendingCalibration = true
        isCalibrating = true
        startMonitoring()
        applyCalibrationIfPossible()
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        altitudeService.startUpdates()
    }

    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        altitudeService.stopUpdates()
    }

    func delete(session: AltitudeSession) async {
        await sessionStore.delete(session: session)
    }

    private func observeSettings() {
        settingsStore.$seaLevelPressureKPa
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pressure in
                self?.altitudeService.setSeaLevelPressure(kPa: pressure)
            }
            .store(in: &cancellables)
    }

    private func subscribeToReadings() {
        altitudeService.readings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] reading in
                guard let self else { return }
                self.currentReading = reading
                self.appendReadingForConfidence(reading)
                self.applyCalibrationIfPossible(using: reading)
                guard self.isRecording else { return }
                let baseline = self.sessionStartAltitude ?? reading.absoluteAltitudeMeters
                if self.sessionStartAltitude == nil {
                    self.sessionStartAltitude = baseline
                }
                let relative = reading.absoluteAltitudeMeters - baseline
                let sample = AltitudeSample(timestamp: reading.timestamp,
                                             relativeAltitudeMeters: relative,
                                             pressureKPa: reading.pressureKPa,
                                             absoluteAltitudeMeters: baseline + relative)
                self.samplesBuffer.append(sample)
                if var session = self.currentSession {
                    session.samples = self.samplesBuffer
                    self.currentSession = session
                }
            }
            .store(in: &cancellables)
    }

    private func observeSessionStore() {
        sessionStore.$sessions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessions in
                guard let self else { return }
                let filtered = sessions.filter { $0.mode == self.mode }
                recentSessions = filtered
                lastCompletedSession = filtered.first
            }
            .store(in: &cancellables)
    }
}

extension MeasureViewModel {
    var canCalibrate: Bool {
        mode == .altimeter
    }

    var netAltitudeDeltaMeters: Double? {
        guard mode == .altimeter else { return nil }
        if let reading = currentReading {
            if isRecording, let sessionStartAltitude {
                return reading.absoluteAltitudeMeters - sessionStartAltitude
            }
            if let zeroBaselineAltitude {
                return reading.absoluteAltitudeMeters - zeroBaselineAltitude
            }
        }
        if let session = currentSession ?? lastCompletedSession, !session.samples.isEmpty {
            return session.netAltitudeChangeMeters
        }
        return nil
    }

    var gainAltitudeMeters: Double? {
        guard mode == .altimeter else { return nil }
        return (currentSession ?? lastCompletedSession)?.totalAscentMeters
    }

    var amslAltitudeMeters: Double? {
        if let reading = currentReading {
            return reading.absoluteAltitudeMeters
        }
        return (currentSession ?? lastCompletedSession)?.samples.last?.absoluteAltitudeMeters
    }

    private func applyCalibrationIfPossible() {
        guard pendingCalibration, let reading = currentReading else { return }
        applyCalibrationIfPossible(using: reading)
    }

    private func applyCalibrationIfPossible(using reading: AltitudeReading) {
        guard pendingCalibration else { return }
        pendingCalibration = false
        isCalibrating = false
        zeroBaselineAltitude = reading.absoluteAltitudeMeters
        if isRecording {
            sessionStartAltitude = reading.absoluteAltitudeMeters
            samplesBuffer.removeAll()
            if var session = currentSession {
                session.samples.removeAll()
                currentSession = session
            }
        }
    }
}

private extension MeasureViewModel {
    func appendReadingForConfidence(_ reading: AltitudeReading) {
        recentReadings.append(reading)
        if recentReadings.count > 32 {
            recentReadings.removeFirst(recentReadings.count - 32)
        }
        let result = SensorConfidenceEstimator.estimate(
            readings: recentReadings,
            mode: mode,
            isCalibrating: isCalibrating || pendingCalibration,
            isAvailable: altitudeService.availabilityStatus,
            now: Date()
        )
        confidence = result.confidence
    }
}

extension MeasureViewModel {
    static func preview(mode: AltitudeSession.Mode = .altimeter) -> MeasureViewModel {
        MeasureViewModel(mode: mode,
                         altitudeService: AltitudeService.preview,
                         sessionStore: SessionStore(controller: PersistenceController(inMemory: true)),
                         settingsStore: SettingsStore())
    }
}
