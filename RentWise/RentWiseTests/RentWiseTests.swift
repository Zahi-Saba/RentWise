//
// RentWiseTests.swift
//  RentWiseTests
//
//  Created by Zahi Saba on 29/9/2026.
//
import Foundation
import Testing
@testable import RentWise

@MainActor
struct RentWiseTests {
    
    @Test
    func savesValidRentalProperty() throws {
        
        let repository = MockRentalPropertyRepository()
        
        let useCase = SaveRentalPropertyUseCase(
            repository: repository
        )
        
        let property = try useCase.execute(
            address: "15 George Street",
            weeklyRent: 650
        )
        
        #expect(property.address == "15 George Street")
        #expect(property.weeklyRent == 650)
        #expect(repository.savedProperties.count == 1)
    }
    
    @Test
    func rejectsMissingAddress() {
        
        let repository = MockRentalPropertyRepository()
        
        let useCase = SaveRentalPropertyUseCase(
            repository: repository
        )
        
        #expect(throws: SaveRentalPropertyError.self) {
            try useCase.execute(
                address: "",
                weeklyRent: 650
            )
        }
        
        #expect(repository.savedProperties.count == 0)
    }
    
    @Test
    func rejectsZeroWeeklyRent() {
        
        let repository = MockRentalPropertyRepository()
        
        let useCase = SaveRentalPropertyUseCase(
            repository: repository
        )
        
        #expect(throws: SaveRentalPropertyError.self) {
            try useCase.execute(
                address: "15 George Street",
                weeklyRent: 0
            )
        }
        
        #expect(repository.savedProperties.count == 0)
    }
    
    @Test
    func rejectsInspectionWithSameStartAndEndTime() {
        
        let repository = MockRentalPropertyRepository()
        
        let useCase = ScheduleInspectionUseCase(
            repository: repository
        )
        
        let propertyID = UUID()
        let inspectionTime = Date()
        
        #expect(throws: ScheduleInspectionError.self) {
            try useCase.execute(
                rentalPropertyID: propertyID,
                startTime: inspectionTime,
                endTime: inspectionTime
            )
        }
        
        #expect(repository.savedInspections.count == 0)
    }
    @Test
    func rejectsObservationWithMissingNotes() {
        
        let repository = MockRentalPropertyRepository()
        
        let useCase = RecordInspectionObservationUseCase(
            repository: repository
        )
        
        #expect(throws: RecordInspectionObservationError.self) {
            try useCase.execute(
                inspectionID: UUID(),
                criterion: .storage,
                status: .needsClarification,
                notes: ""
            )
        }
        
        #expect(repository.savedObservations.count == 0)
    }
    @Test
    func rejectsDuplicateInspectionCriterion() throws {

        let repository =
            MockRentalPropertyRepository()

        let useCase =
            RecordInspectionObservationUseCase(
                repository: repository
            )

        let inspectionID = UUID()

        _ = try useCase.execute(
            inspectionID: inspectionID,
            criterion: .noise,
            status: .meetsNeeds,
            notes: "Noise level is acceptable."
        )

        var duplicateWasRejected = false

        do {

            _ = try useCase.execute(
                inspectionID: inspectionID,
                criterion: .noise,
                status: .doesNotMeetNeeds,
                notes: "Traffic is loud."
            )

        } catch RecordInspectionObservationError
            .criterionAlreadyRecorded {

            duplicateWasRejected = true
        }

        #expect(
            duplicateWasRejected == true
        )
    }
    @Test
    func deletesSavedRentalProperty() throws {

        let repository =
            MockRentalPropertyRepository()

        let useCase =
            DeleteRentalPropertyUseCase(
                repository: repository
            )

        let property = RentalProperty(
            address: "10 George Street",
            weeklyRent: 600
        )

        try repository.save(property)

        try useCase.execute(
            property: property
        )

        #expect(
            repository.savedProperties.isEmpty
        )
    }
    //happy path
    @Test
    func savesValidInspectionObservation() throws {

        let repository = MockRentalPropertyRepository()

        let useCase = RecordInspectionObservationUseCase(
            repository: repository
        )

        let observation = try useCase.execute(
            inspectionID: UUID(),
            criterion: .storage,
            status: .meetsNeeds,
            notes: "Plenty of wardrobe space"
        )

        #expect(observation.notes == "Plenty of wardrobe space")
        #expect(repository.savedObservations.count == 1)
    }
    
    @Test
    func updatesSavedInspectionObservation() throws {

        let repository =
            MockRentalPropertyRepository()

        let inspectionID = UUID()

        let observation =
            InspectionObservation(
                inspectionID: inspectionID,
                criterion: .storage,
                status: .needsClarification,
                notes: "Need to check storage"
            )

        repository.savedObservations.append(
            observation
        )

        let useCase =
            UpdateInspectionObservationUseCase(
                repository: repository
            )

        let updatedObservation =
            try useCase.execute(
                observation: observation,
                status: .meetsNeeds,
                notes: "Large built-in wardrobe"
            )

        #expect(
            updatedObservation.status ==
                .meetsNeeds
        )

        #expect(
            updatedObservation.notes ==
                "Large built-in wardrobe"
        )

        #expect(
            repository.savedObservations[0].notes ==
                "Large built-in wardrobe"
        )
    }
}

    
