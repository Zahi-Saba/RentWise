import Foundation
import CoreData
import Testing
@testable import RentWise

@MainActor
struct ImportSharedPropertyTests {
    @Test func savesSharedListing() throws {
        let repository = MockRentalPropertyRepository()
        let property = try ImportSharedPropertyUseCase(repository: repository).execute(link: "https://example.com/property", title: "15 George Street")
        #expect(property.address == "15 George Street")
        #expect(property.sourceURL == "https://example.com/property")
        #expect(property.weeklyRent == 0)
        #expect(repository.savedProperties.count == 1)
    }
    @Test func doesNotDuplicateSharedListing() throws {
        let repository = MockRentalPropertyRepository()
        let useCase = ImportSharedPropertyUseCase(repository: repository)
        let first = try useCase.execute(link: "https://example.com/property", title: "15 George Street")
        let second = try useCase.execute(link: "https://example.com/property#photos", title: "Same property")
        #expect(first.id == second.id)
        #expect(repository.savedProperties.count == 1)
    }
    @Test func rejectsInvalidURLsWithoutSaving() throws {
        let repository = MockRentalPropertyRepository()
        for link in ["", "not a URL", "file:///private/example", "javascript:alert(1)"] {
            #expect(throws: ImportSharedPropertyError.self) {
                try ImportSharedPropertyUseCase(repository: repository).execute(link: link, title: nil)
            }
        }
        #expect(repository.savedProperties.isEmpty)
    }
    @Test func usesFallbackWhenTitleIsMissingOrBlank() throws {
        for title in [nil, "  \n"] as [String?] {
            let repository = MockRentalPropertyRepository()
            let property = try ImportSharedPropertyUseCase(repository: repository).execute(link: "https://example.com/property", title: title)
            #expect(property.address == "Listing from example.com")
        }
    }
    @Test func preservesExistingPropertyWhenReshared() throws {
        let repository = MockRentalPropertyRepository()
        let existing = RentalProperty(address: "Existing title", weeklyRent: 610, sourceURL: "https://example.com/property")
        try repository.save(existing)
        let property = try ImportSharedPropertyUseCase(repository: repository).execute(link: "https://example.com/property", title: "Another title")
        #expect(property.id == existing.id)
        #expect(property.weeklyRent == 610)
        #expect(property.address == "Existing title")
    }
    @Test func sourceURLPersistsAcrossContexts() throws {
        let container = NSPersistentContainer(name: "RentWiseModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        var failure: Error?
        container.loadPersistentStores { _, error in failure = error }
        if let failure { throw failure }
        let repository = CoreDataRentalPropertyRepository(context: container.viewContext)
        let imported = try ImportSharedPropertyUseCase(repository: repository).execute(link: "https://example.com/property", title: "Apartment")
        container.viewContext.reset()
        let saved = try #require(repository.fetchRentalProperties().first)
        #expect(saved.id == imported.id)
        #expect(saved.sourceURL == imported.sourceURL)
        #expect(saved.weeklyRent == 0)
    }
    @Test func originalCoreDataStoreMigratesWithoutLosingProperty() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let storeURL = folder.appendingPathComponent("Migration.sqlite")
        let oldURL = Bundle.main.url(forResource: "RentWiseModel", withExtension: "momd")!.appendingPathComponent("RentWiseModel.mom")
        let oldModel = try #require(NSManagedObjectModel(contentsOf: oldURL))
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: oldModel)
        let oldStore = try coordinator.addPersistentStore(type: .sqlite, at: storeURL)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        let entity = NSEntityDescription.insertNewObject(forEntityName: "RentalPropertyEntity", into: context)
        let id = UUID()
        entity.setValue(id, forKey: "id")
        entity.setValue("Existing property", forKey: "address")
        entity.setValue(550, forKey: "weeklyRent")
        try context.save()
        context.reset()
        try coordinator.remove(oldStore)
        let container = NSPersistentContainer(name: "RentWiseModel")
        container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: storeURL)]
        var failure: Error?
        container.loadPersistentStores { _, error in failure = error }
        if let failure { throw failure }
        let saved = try #require(CoreDataRentalPropertyRepository(context: container.viewContext).fetchRentalProperties().first)
        #expect(saved.id == id)
        #expect(saved.weeklyRent == 550)
        #expect(saved.sourceURL == nil)
        for store in container.persistentStoreCoordinator.persistentStores { try container.persistentStoreCoordinator.remove(store) }
    }
}
