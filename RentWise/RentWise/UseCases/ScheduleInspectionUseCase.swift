//
//  ScheduleInspectionUseCase.swift
//  RentWise
//
//  Created by Zahi Saba on 29/9/2026.
//

import Foundation

enum ScheduleInspectionError: Error {
    case invalidTime
}
//An inspection end time must be after its start time.
struct ScheduleInspectionUseCase {

    private let repository: RentalPropertyRepository

    init(repository: RentalPropertyRepository) {
        self.repository = repository
    }

    func execute(
        rentalPropertyID: UUID,
        startTime: Date,
        endTime: Date
    ) throws -> RentalInspection {

        if endTime <= startTime {
            throw ScheduleInspectionError.invalidTime
        }

        let inspection = RentalInspection(
            rentalPropertyID: rentalPropertyID,
            startTime: startTime,
            endTime: endTime
        )

        try repository.save(inspection)

        return inspection
    }
}
