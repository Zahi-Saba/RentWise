import Foundation
import Testing
@testable import RentWise

@MainActor
struct PropertyDetailsTests {
    @Test func fetchesOnlyThisPropertyInspectionsNewestFirst() throws {
        let repository = MockRentalPropertyRepository()
        let propertyID = UUID()
        let old = RentalInspection(rentalPropertyID: propertyID, startTime: Date(timeIntervalSince1970: 100), endTime: Date(timeIntervalSince1970: 200))
        let recent = RentalInspection(rentalPropertyID: propertyID, startTime: Date(timeIntervalSince1970: 300), endTime: Date(timeIntervalSince1970: 400))
        let unrelated = RentalInspection(rentalPropertyID: UUID(), startTime: Date(), endTime: Date().addingTimeInterval(100))
        repository.savedInspections = [old, unrelated, recent]
        let results = try FetchPropertyInspectionsUseCase(repository: repository).execute(propertyID: propertyID)
        #expect(results.map(\.id) == [recent.id, old.id])
    }
    @Test func switchingPropertiesClearsPreviousInspectionState() throws {
        let repository = MockRentalPropertyRepository()
        let propertyID = UUID()
        let inspection = RentalInspection(rentalPropertyID: propertyID, startTime: Date(), endTime: Date().addingTimeInterval(600))
        repository.savedInspections = [inspection]
        repository.savedObservations = [InspectionObservation(inspectionID: inspection.id, criterion: .noise, status: .meetsNeeds, notes: "Quiet")]
        let viewModel = RentWiseViewModel(repository: repository)
        viewModel.loadPropertyDetails(for: propertyID)
        #expect(viewModel.propertyInspections.count == 1)
        #expect(viewModel.latestPropertyObservations.count == 1)
        viewModel.loadPropertyDetails(for: UUID())
        #expect(viewModel.propertyInspections.isEmpty)
        #expect(viewModel.latestPropertyObservations.isEmpty)
        #expect(viewModel.latestPropertyInspection == nil)
    }
}
