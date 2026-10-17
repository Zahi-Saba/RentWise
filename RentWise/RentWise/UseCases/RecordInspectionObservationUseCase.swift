//
//  RecordInspectionObservationUseCase.swift
//  RentWise
//
//  Created by Zahi Saba on 29/9/2026.
//

import Foundation

enum RecordInspectionObservationError: Error {
    case missingNotes
    case criterionAlreadyRecorded
}
// an observation must have a note 
struct RecordInspectionObservationUseCase {

    let repository: RentalPropertyRepository

    func execute(
        inspectionID: UUID,
        criterion: InspectionCriterion,
        status: ObservationStatus,
        notes: String
    ) throws -> InspectionObservation {

        if notes.isEmpty {
            throw RecordInspectionObservationError.missingNotes
        }

        let savedObservations =
            try repository.fetchObservations(
                for: inspectionID
            )

        for observation in savedObservations {

            if observation.criterion == criterion {

                throw RecordInspectionObservationError
                    .criterionAlreadyRecorded
            }
        }

        let observation = InspectionObservation(
            inspectionID: inspectionID,
            criterion: criterion,
            status: status,
            notes: notes
        )

        try repository.save(
            observation
        )

        return observation
    }
}
