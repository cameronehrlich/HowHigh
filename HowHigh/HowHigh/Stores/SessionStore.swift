import Foundation
import CoreData

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var sessions: [AltitudeSession] = []

    private let container: NSPersistentContainer
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let maxSessions = 30

    init(controller: PersistenceController = .shared, initialSessions: [AltitudeSession]? = nil) {
        container = controller.container
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        if let initialSessions {
            self.sessions = initialSessions
        } else {
            Task {
                await loadSessions()
            }
        }
    }

    func loadSessions() async {
        let context = container.viewContext
        let request: NSFetchRequest<AltitudeSessionEntity> = AltitudeSessionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AltitudeSessionEntity.startDate, ascending: false)]
        do {
            let entities = try context.fetch(request)
            sessions = entities.compactMap { entity in
                guard let session = try? decoder.decode(AltitudeSession.self, from: entity.payload) else { return nil }
                return session
            }
        } catch {
            print("Failed to fetch sessions: \(error)")
        }
    }

    func upsert(session: AltitudeSession) async {
        let context = container.viewContext
        let request: NSFetchRequest<AltitudeSessionEntity> = AltitudeSessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", session.id as CVarArg)
        do {
            let entity: AltitudeSessionEntity
            if let existing = try context.fetch(request).first {
                entity = existing
            } else {
                entity = AltitudeSessionEntity(context: context)
                entity.id = session.id
            }
            entity.startDate = session.startDate
            entity.endDate = session.endDate
            entity.payload = try encoder.encode(session)
            try context.save()
            await loadSessions()
            enforceLimit()
        } catch {
            context.rollback()
            print("Failed to upsert session: \(error)")
        }
    }

    func delete(session: AltitudeSession) async {
        let context = container.viewContext
        let request: NSFetchRequest<AltitudeSessionEntity> = AltitudeSessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", session.id as CVarArg)
        do {
            if let entity = try context.fetch(request).first {
                context.delete(entity)
                try context.save()
                await loadSessions()
            }
        } catch {
            context.rollback()
            print("Failed to delete session: \(error)")
        }
    }

    func sessions(for mode: AltitudeSession.Mode) -> [AltitudeSession] {
        sessions.filter { $0.mode == mode }
    }

    private func enforceLimit() {
        Task {
            for mode in AltitudeSession.Mode.allCases {
                let filtered = sessions.filter { $0.mode == mode }
                guard filtered.count > maxSessions else { continue }
                let sorted = filtered.sorted(by: { $0.startDate > $1.startDate })
                for session in sorted.dropFirst(maxSessions) {
                    await delete(session: session)
                }
            }
        }
    }
}

extension AltitudeSessionEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<AltitudeSessionEntity> {
        NSFetchRequest<AltitudeSessionEntity>(entityName: "AltitudeSessionEntity")
    }
}
