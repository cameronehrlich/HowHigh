import Foundation
import Combine

@MainActor
final class MeasureViewModel: ObservableObject {
    @Published var currentReading: AltitudeReading?
    @Published var isRecording: Bool = false
    @Published var currentSession: AltitudeSession?
    @Published var lastCompletedSession: AltitudeSession?
    @Published var availabilityMessage: String?
    @Published private(set) var recentSessions: [AltitudeSession] = []

    let mode: AltitudeSession.Mode

    private let altitudeService: AltitudeService
    private let sessionStore: SessionStore
    private let settingsStore: SettingsStore
    private var cancellables: Set<AnyCancellable> = []
    private var samplesBuffer: [AltitudeSample] = []
    private var baselineAltitude: Double?

    init(mode: AltitudeSession.Mode,
         altitudeService: AltitudeService,
         sessionStore: SessionStore,
         settingsStore: SettingsStore) {
        self.mode = mode
        self.altitudeService = altitudeService
        self.sessionStore = sessionStore
        self.settingsStore = settingsStore
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
        baselineAltitude = nil
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
        baselineAltitude = nil
        lastCompletedSession = session
        currentSession = nil
    }

    func calibrateToCurrentReading() {
        baselineAltitude = currentReading?.absoluteAltitudeMeters
        samplesBuffer.removeAll()
        if var session = currentSession {
            session.samples.removeAll()
            currentSession = session
        }
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
                guard self.isRecording else { return }
                let baseline = self.baselineAltitude ?? reading.absoluteAltitudeMeters
                if self.baselineAltitude == nil {
                    self.baselineAltitude = baseline
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
}

extension MeasureViewModel {
    static func preview(mode: AltitudeSession.Mode = .altimeter) -> MeasureViewModel {
        MeasureViewModel(mode: mode,
                         altitudeService: AltitudeService.preview,
                         sessionStore: SessionStore(controller: PersistenceController(inMemory: true)),
                         settingsStore: SettingsStore())
    }
}
