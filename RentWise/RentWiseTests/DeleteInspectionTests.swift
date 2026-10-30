import Foundation
import CoreData
import Testing
@testable import RentWise

@MainActor
struct DeleteInspectionTests {
    private func inspection(for property: RentalProperty) -> RentalInspection {
        RentalInspection(rentalPropertyID: property.id, startTime: Date().addingTimeInterval(3600),
                         endTime: Date().addingTimeInterval(5400))
    }

    @Test func missingInspectionIsRejected() throws {
        let repository = MockRentalPropertyRepository()
        let property = RentalProperty(address: "Test", weeklyRent: 600)
        #expect(throws: DeleteInspectionError.self) {
            try DeleteInspectionUseCase(repository: repository).execute(inspection: inspection(for: property))
        }
    }

    @Test func deletionCascadesOnlyToSelectedInspectionsObservations() throws {
        let container = NSPersistentContainer(name: "RentWiseModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError { throw loadError }
        let repository = CoreDataRentalPropertyRepository(context: container.viewContext)
        var property = RentalProperty(address: "Test", weeklyRent: 600)
        property.rooms = InspectionRoom.standardRooms()
        try repository.save(property)
        let deleted = inspection(for: property)
        let retained = inspection(for: property)
        try repository.save(deleted)
        try repository.save(retained)
        for visit in [deleted, retained] {
            try repository.save(InspectionObservation(inspectionID: visit.id, criterion: .noise,
                status: .meetsNeeds, notes: "Quiet"))
        }
        try DeleteInspectionUseCase(repository: repository).execute(inspection: deleted)
        container.viewContext.reset()
        #expect(try repository.fetchInspections(for: property.id).map(\.id) == [retained.id])
        #expect(try repository.fetchObservations(for: deleted.id).isEmpty)
        #expect(try repository.fetchObservations(for: retained.id).count == 1)
        #expect(try repository.fetchRentalProperties().first?.rooms == property.rooms)
    }

    @Test func viewModelRefreshesListsAndLatestObservations() throws {
        let repository = MockRentalPropertyRepository()
        let property = RentalProperty(address: "Test", weeklyRent: 600)
        try repository.save(property)
        let visit = inspection(for: property)
        try repository.save(visit)
        try repository.save(InspectionObservation(inspectionID: visit.id, criterion: .noise,
            status: .meetsNeeds, notes: "Quiet"))
        let viewModel = RentWiseViewModel(repository: repository)
        viewModel.loadUpcomingInspections()
        viewModel.loadPropertyDetails(for: property.id)
        viewModel.loadObservations(for: visit.id)
        viewModel.deleteInspection(visit)
        #expect(viewModel.inspections.isEmpty)
        #expect(viewModel.propertyInspections.isEmpty)
        #expect(viewModel.observations.isEmpty)
        #expect(viewModel.latestPropertyInspection == nil)
        #expect(viewModel.latestPropertyObservations.isEmpty)
        #expect(viewModel.errorMessage.isEmpty)
        #expect(repository.savedProperties.count == 1)
    }

    @Test func failedDeletionPreservesVisibleInspection() throws {
        class FailingRepository: MockRentalPropertyRepository {
            override func delete(_ inspection: RentalInspection) throws {
                throw CocoaError(.fileWriteUnknown)
            }
        }
        let repository = FailingRepository()
        let property = RentalProperty(address: "Test", weeklyRent: 600)
        try repository.save(property)
        let visit = inspection(for: property)
        try repository.save(visit)
        let viewModel = RentWiseViewModel(repository: repository)
        viewModel.loadUpcomingInspections()
        viewModel.deleteInspection(visit)
        #expect(viewModel.inspections.map(\.id) == [visit.id])
        #expect(!viewModel.errorMessage.isEmpty)
    }
}
