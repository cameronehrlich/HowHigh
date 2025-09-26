import Foundation
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published private(set) var sessions: [AltitudeSession] = []

    private let sessionStore: SessionStore
    private let mode: AltitudeSession.Mode
    private var cancellables: Set<AnyCancellable> = []

    init(mode: AltitudeSession.Mode, sessionStore: SessionStore) {
        self.mode = mode
        self.sessionStore = sessionStore
        sessionStore.$sessions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessions in
                guard let self else { return }
                self.sessions = sessions.filter { $0.mode == self.mode }
            }
            .store(in: &cancellables)
    }

    func delete(_ session: AltitudeSession) async {
        guard session.mode == mode else { return }
        await sessionStore.delete(session: session)
    }
}
