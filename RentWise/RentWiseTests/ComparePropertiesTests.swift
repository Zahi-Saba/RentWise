import Foundation
import Testing
@testable import RentWise

@MainActor
struct ComparePropertiesTests {
    private func fixture() -> (MockRentalPropertyRepository, RentalProperty, RentalProperty) {
        let repository = MockRentalPropertyRepository()
        let a = RentalProperty(address: "Property A", weeklyRent: 600)
        let b = RentalProperty(address: "Property B", weeklyRent: 750)
        repository.savedProperties = [a, b]
        return (repository, a, b)
    }

    @Test func requiresTwoDistinctSavedProperties() throws {
        let (repository, a, _) = fixture()
        let useCase = ComparePropertiesUseCase(repository: repository)
        #expect(throws: ComparePropertiesError.sameProperty) {
            try useCase.execute(firstID: a.id, secondID: a.id)
        }
        #expect(throws: ComparePropertiesError.propertyNotFound) {
            try useCase.execute(firstID: a.id, secondID: UUID())
        }
    }

    @Test func preservesSelectionOrderAndCalculatesRentDifference() throws {
        let (repository, a, b) = fixture()
        let useCase = ComparePropertiesUseCase(repository: repository)
        let result = try useCase.execute(firstID: a.id, secondID: b.id)
        #expect(result.first.property.id == a.id)
        #expect(result.second.property.id == b.id)
        #expect(result.weeklyRentDifference == -150)
        #expect(try useCase.execute(firstID: b.id, secondID: a.id).weeklyRentDifference == 150)
        #expect(result.first.inspection == nil)
        #expect(result.first.observation(for: .noise) == nil)
    }

    @Test func missingOrInvalidRentDoesNotBecomeZeroCost() throws {
        let (repository, a, b) = fixture()
        let useCase = ComparePropertiesUseCase(repository: repository)
        for rent in [0, -10, Double.infinity, Double.nan] {
            repository.savedProperties[0].weeklyRent = rent
            #expect(try useCase.execute(firstID: a.id, secondID: b.id).weeklyRentDifference == nil)
        }
        repository.savedProperties[0].weeklyRent = b.weeklyRent
        #expect(try useCase.execute(firstID: a.id, secondID: b.id).weeklyRentDifference == 0)
    }

    @Test func usesLatestRecordedVisitWithoutMixingOlderOrOtherPropertyNotes() throws {
        let (repository, a, b) = fixture()
        let old = RentalInspection(rentalPropertyID: a.id, startTime: Date(timeIntervalSince1970: 100), endTime: Date(timeIntervalSince1970: 200))
        let latest = RentalInspection(rentalPropertyID: a.id, startTime: Date(timeIntervalSince1970: 300), endTime: Date(timeIntervalSince1970: 400))
        let empty = RentalInspection(rentalPropertyID: a.id, startTime: Date(timeIntervalSince1970: 500), endTime: Date(timeIntervalSince1970: 600))
        let other = RentalInspection(rentalPropertyID: b.id, startTime: Date(timeIntervalSince1970: 700), endTime: Date(timeIntervalSince1970: 800))
        repository.savedInspections = [empty, old, other, latest]
        repository.savedObservations = [
            InspectionObservation(inspectionID: old.id, criterion: .storage, status: .meetsNeeds, notes: "Older visit"),
            InspectionObservation(inspectionID: latest.id, criterion: .noise, status: .doesNotMeetNeeds, notes: "Traffic audible"),
            InspectionObservation(inspectionID: other.id, criterion: .noise, status: .meetsNeeds, notes: "Quiet")
        ]
        let result = try ComparePropertiesUseCase(repository: repository).execute(firstID: a.id, secondID: b.id)
        #expect(result.first.inspection?.id == latest.id)
        #expect(result.first.observation(for: .noise)?.notes == "Traffic audible")
        #expect(result.first.observation(for: .storage) == nil)
        #expect(result.second.observation(for: .noise)?.notes == "Quiet")
    }

    @Test func viewModelRefreshesEditsAndClearsStaleComparisonOnDeletion() throws {
        let (repository, a, b) = fixture()
        let model = RentWiseViewModel(repository: repository)
        model.compareProperties(firstID: a.id, secondID: b.id)
        #expect(model.comparison != nil)
        repository.savedProperties[0].weeklyRent = 800
        model.compareProperties(firstID: a.id, secondID: b.id)
        #expect(model.comparison?.weeklyRentDifference == 50)
        try repository.delete(b)
        model.compareProperties(firstID: a.id, secondID: b.id)
        #expect(model.comparison == nil)
        #expect(!model.comparisonError.isEmpty)
    }

    @Test func repositoryFailureIsSurfacedWithoutStaleResults() {
        let repository = FailingComparisonRepository()
        let a = RentalProperty(address: "A", weeklyRent: 600)
        let b = RentalProperty(address: "B", weeklyRent: 700)
        repository.savedProperties = [a, b]
        let model = RentWiseViewModel(repository: repository)
        model.compareProperties(firstID: a.id, secondID: b.id)
        #expect(model.comparison != nil)
        repository.shouldFail = true
        model.compareProperties(firstID: a.id, secondID: b.id)
        #expect(model.comparison == nil)
        #expect(!model.comparisonError.isEmpty)
    }
}

@MainActor
private final class FailingComparisonRepository: MockRentalPropertyRepository {
    var shouldFail = false
    override func fetchInspections(for rentalPropertyID: UUID) throws -> [RentalInspection] {
        if shouldFail { throw NSError(domain: "ComparisonTest", code: 1) }
        return try super.fetchInspections(for: rentalPropertyID)
    }
}
