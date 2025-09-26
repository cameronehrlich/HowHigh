import Foundation
import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = PersistenceController.makeModel()
        container = NSPersistentContainer(name: "HowHighModel", managedObjectModel: model)
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unresolved error \(error)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let sessionEntity = NSEntityDescription()
        sessionEntity.name = "AltitudeSessionEntity"
        sessionEntity.managedObjectClassName = NSStringFromClass(AltitudeSessionEntity.self)

        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = false

        let startDate = NSAttributeDescription()
        startDate.name = "startDate"
        startDate.attributeType = .dateAttributeType
        startDate.isOptional = false

        let endDate = NSAttributeDescription()
        endDate.name = "endDate"
        endDate.attributeType = .dateAttributeType
        endDate.isOptional = true

        let payload = NSAttributeDescription()
        payload.name = "payload"
        payload.attributeType = .binaryDataAttributeType
        payload.isOptional = false

        sessionEntity.properties = [idAttribute, startDate, endDate, payload]
        model.entities = [sessionEntity]
        return model
    }
}

@objc(AltitudeSessionEntity)
final class AltitudeSessionEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var startDate: Date
    @NSManaged var endDate: Date?
    @NSManaged var payload: Data
}
