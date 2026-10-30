import Foundation
import Testing
import CoreData
@testable import RentWise

@MainActor
struct RoomInspectionTests {
    @Test func preparesExistingPropertyOnceAndKeepsRoomStatus() throws {
        let repository = MockRentalPropertyRepository()
        let property = RentalProperty(address: "Test", weeklyRent: 610)
        try repository.save(property)
        let prepared = try PrepareRoomsUseCase(repository: repository).execute(propertyID: property.id)
        #expect(prepared.rooms.map(\.name) == ["Kitchen", "Bathroom", "Bedroom", "Living Area"])
        let room = try #require(prepared.rooms.first)
        _ = try SetRoomInspectedUseCase(repository: repository).execute(propertyID: property.id, roomID: room.id, checked: true)
        let reloaded = try PrepareRoomsUseCase(repository: repository).execute(propertyID: property.id)
        #expect(reloaded.rooms.first?.id == room.id)
        #expect(reloaded.rooms.first?.checked == true)
        #expect(reloaded.weeklyRent == 610)
    }

    @Test func defectsValidateDescriptionsAndStayInTheirRoom() throws {
        let repository = MockRentalPropertyRepository()
        let property = RentalProperty(address: "Test", weeklyRent: 610)
        try repository.save(property)
        let prepared = try PrepareRoomsUseCase(repository: repository).execute(propertyID: property.id)
        let room = try #require(prepared.rooms.first)
        let useCase = RecordRoomDefectUseCase(repository: repository)
        #expect(throws: RoomInspectionError.self) {
            try useCase.execute(propertyID: property.id, roomID: room.id, description: " \n ", severity: .major)
        }
        for severity in DefectSeverity.allCases {
            _ = try useCase.execute(propertyID: property.id, roomID: room.id, description: "  Cracked tile  ", severity: severity)
        }
        let saved = try #require(repository.savedProperties.first)
        #expect(saved.rooms[0].defects.map(\.severity) == DefectSeverity.allCases)
        #expect(saved.rooms[0].defects.allSatisfy { $0.description == "Cracked tile" })
        #expect(saved.rooms[1].defects.isEmpty)
        let defect = try #require(saved.rooms[0].defects.first)
        let updated = try DeleteRoomDefectUseCase(repository: repository).execute(propertyID: property.id, roomID: room.id, defectID: defect.id)
        #expect(updated.rooms[0].defects.count == 2)
        #expect(updated.rooms[0].checked == false)
    }

    @Test func olderRoomPayloadStillDecodes() throws {
        let json = "{\"id\":\"\(UUID().uuidString)\",\"name\":\"Kitchen\",\"checked\":true}"
        let room = try JSONDecoder().decode(InspectionRoom.self, from: Data(json.utf8))
        #expect(room.checked)
        #expect(room.defects.isEmpty)
    }

    @Test func missingRoomDoesNotChangeProperty() throws {
        let repository = MockRentalPropertyRepository()
        let property = RentalProperty(address: "Test", weeklyRent: 610)
        try repository.save(property)
        #expect(throws: RoomInspectionError.self) {
            try SetRoomInspectedUseCase(repository: repository).execute(propertyID: property.id, roomID: UUID(), checked: true)
        }
        #expect(repository.savedProperties.first?.rooms.isEmpty == true)
    }

    @Test func previousStoreMigratesWithoutLosingPropertyOrInspection() throws {
        let bundle = Bundle(for: CoreDataRentalPropertyRepository.self)
        let modelDirectory = try #require(bundle.url(forResource: "RentWiseModel", withExtension: "momd"))
        let oldModel = try #require(NSManagedObjectModel(contentsOf: modelDirectory.appendingPathComponent("RentWiseModelV2.mom")))
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("migration.sqlite")
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: oldModel)
        let store = try coordinator.addPersistentStore(type: .sqlite, at: url)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        let propertyID = UUID()
        let property = NSEntityDescription.insertNewObject(forEntityName: "RentalPropertyEntity", into: context)
        property.setValue(propertyID, forKey: "id")
        property.setValue("Existing home", forKey: "address")
        property.setValue(610, forKey: "weeklyRent")
        property.setValue("https://example.com/listing", forKey: "sourceURL")
        let inspection = NSEntityDescription.insertNewObject(forEntityName: "RentalInspectionEntity", into: context)
        inspection.setValue(UUID(), forKey: "id")
        inspection.setValue(Date(), forKey: "startTime")
        inspection.setValue(Date().addingTimeInterval(3600), forKey: "endTime")
        inspection.setValue(property, forKey: "rentalProperty")
        try context.save()
        context.reset()
        try coordinator.remove(store)
        let container = NSPersistentContainer(name: "RentWiseModel")
        let description = NSPersistentStoreDescription(url: url)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]
        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError { throw loadError }
        let repository = CoreDataRentalPropertyRepository(context: container.viewContext)
        let restored = try PrepareRoomsUseCase(repository: repository).execute(propertyID: propertyID)
        #expect(restored.rooms.count == 4)
        #expect(restored.sourceURL == "https://example.com/listing")
        #expect(restored.weeklyRent == 610)
        #expect(try repository.fetchInspections(for: propertyID).count == 1)
        for store in container.persistentStoreCoordinator.persistentStores {
            try container.persistentStoreCoordinator.remove(store)
        }
    }

    @Test func roomsPersistThroughCoreDataReload() throws {
        let container = NSPersistentContainer(name: "RentWiseModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError { throw loadError }
        let repository = CoreDataRentalPropertyRepository(context: container.viewContext)
        let property = RentalProperty(address: "Test", weeklyRent: 610)
        try repository.save(property)
        let prepared = try PrepareRoomsUseCase(repository: repository).execute(propertyID: property.id)
        let room = try #require(prepared.rooms.first)
        _ = try SetRoomInspectedUseCase(repository: repository).execute(propertyID: property.id, roomID: room.id, checked: true)
        _ = try RecordRoomDefectUseCase(repository: repository).execute(propertyID: property.id, roomID: room.id, description: "Cracked tile", severity: .moderate)
        container.viewContext.reset()
        let restored = try #require(repository.fetchRentalProperties().first)
        #expect(restored.rooms.first?.id == room.id)
        #expect(restored.rooms.first?.checked == true)
        #expect(restored.rooms.first?.defects.first?.description == "Cracked tile")
        #expect(restored.rooms.first?.defects.first?.severity == .moderate)
    }
}
