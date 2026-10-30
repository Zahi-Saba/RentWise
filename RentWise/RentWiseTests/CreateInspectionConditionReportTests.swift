//
//  CreateInspectionConditionReportTests.swift
//  RentWise
//
//  Created by Bo Wen Chan on 27/10/2026.
//

import Foundation
import Testing
@testable import RentWise

@MainActor
struct CreateInspectionConditionReportUseCaseTests {
    // Test to check a valid property and inspection should produce a report containing the saved data
    @Test func createsReportWithCorrectData() throws {
        let repository = MockRentalPropertyRepository()

        let property = RentalProperty(address: "12 George Street, Sydney", weeklyRent: 650)

        let inspection = RentalInspection(rentalPropertyID: property.id, startTime: Date(timeIntervalSince1970: 1000), endTime: Date(timeIntervalSince1970: 2000))

        let observation = InspectionObservation(inspectionID: inspection.id, criterion: .noise, status: .doesNotMeetNeeds, notes: "Traffic noise from outside")

        repository.savedProperties = [property]
        repository.savedInspections = [inspection]
        repository.savedObservations = [observation]

        let useCase = CreateInspectionConditionReportUseCase(repository: repository)

        let timestamp = Date(timeIntervalSince1970: 3000)

        let report = try useCase.execute(propertyID: property.id, inspectionID: inspection.id, generatedAt: timestamp)

        #expect(report.property.id == property.id)
        #expect(report.property.weeklyRent == 650)
        #expect(report.inspection.id == inspection.id)
        #expect(report.observations.count == 1)
        #expect(report.observations[0].notes == "Traffic noise from outside")
        #expect(report.generatedAt == timestamp)
    }

    // Test to reject a property that does not exist
    @Test func rejectsMissingProperty() throws {
        let repository = MockRentalPropertyRepository()

        let useCase = CreateInspectionConditionReportUseCase(repository: repository)

        #expect(throws: CreateInspectionConditionReportError.propertyNotFound) {
            try useCase.execute(propertyID: UUID(), inspectionID: UUID())
        }
    }

    // Test to prevent a report from using an inspection belonging to another property
    @Test func rejectsInspectionFromAnotherProperty() throws {
        let repository = MockRentalPropertyRepository()

        let firstProperty = RentalProperty(address: "Property A", weeklyRent: 500)

        let secondProperty = RentalProperty(address: "Property B", weeklyRent: 700)

        let inspection = RentalInspection(rentalPropertyID: secondProperty.id, startTime: Date(), endTime: Date().addingTimeInterval(3600))

        repository.savedProperties = [firstProperty, secondProperty]

        repository.savedInspections = [inspection]

        let useCase = CreateInspectionConditionReportUseCase(repository: repository)

        #expect(throws: CreateInspectionConditionReportError.inspectionNotFound) {
            try useCase.execute(propertyID: firstProperty.id, inspectionID: inspection.id)
        }
    }

    // Test to reject a report when no inspection observations have been recorded
    @Test func rejectsInspectionWithoutObservations() throws {
        let repository = MockRentalPropertyRepository()

        let property = RentalProperty(address: "45 Pitt Street, Sydney", weeklyRent: 600)

        let inspection = RentalInspection(rentalPropertyID: property.id, startTime: Date(), endTime: Date().addingTimeInterval(3600))

        repository.savedProperties = [property]
        repository.savedInspections = [inspection]

        let useCase = CreateInspectionConditionReportUseCase(repository: repository)

        #expect(throws: CreateInspectionConditionReportError.noFindings) {
            try useCase.execute(propertyID: property.id, inspectionID: inspection.id)
        }
    }

    // Test to check findings must be ordered consistently
    @Test func sortsObservationsByChecklistOrder() throws {
        let repository = MockRentalPropertyRepository()

        let property = RentalProperty(address: "10 King Street", weeklyRent: 550)

        let inspection = RentalInspection(rentalPropertyID: property.id, startTime: Date(), endTime: Date().addingTimeInterval(3600))

        let storage = InspectionObservation(inspectionID: inspection.id, criterion: .storage, status: .meetsNeeds, notes: "Enough storage")

        let noise = InspectionObservation(inspectionID: inspection.id, criterion: .noise, status: .needsClarification, notes: "Check evening noise")

        repository.savedProperties = [property]
        repository.savedInspections = [inspection]

        // Deliberately put storage before noise
        repository.savedObservations = [storage, noise]

        let report = try CreateInspectionConditionReportUseCase(repository: repository).execute(propertyID: property.id, inspectionID: inspection.id)

        #expect(report.observations.map(\.criterion) == [InspectionCriterion.noise, .storage])
    }

    // Test for checking no observations cannot generate reports
    @Test func preventsReportGenerationWithoutObservations() throws {
        let repository = MockRentalPropertyRepository()
        let property = RentalProperty(address: "45 Pitt Street", weeklyRent: 600)
        let inspection = RentalInspection(rentalPropertyID: property.id, startTime: Date(), endTime: Date().addingTimeInterval(3600))
        
        repository.savedProperties = [property]
        repository.savedInspections = [inspection]
        
        let options = try ListInspectionReportOptionsUseCase(repository: repository).execute()
        
        let option = try #require(options.first)
        
        #expect(option.observationCount == 0)
        #expect(!option.canGenerateReport)
    }
    
    // Test to check no properties produces an empty report list
    @Test func returnsEmptyListWhenNoPropertiesExist() throws {
        let repository = MockRentalPropertyRepository()
        let useCase = ListInspectionReportOptionsUseCase(repository: repository)
        let options = try useCase.execute()

        #expect(options.isEmpty)
    }
    
}
