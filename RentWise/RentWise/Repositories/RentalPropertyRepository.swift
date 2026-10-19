//
//  RentalPropertyRepository.swift
// RentWise
//
//  Created by Zahi Saba on 29/9/2026.
//

import Foundation

protocol RentalPropertyRepository {

    func save(_ property: RentalProperty) throws

    func update(_ property: RentalProperty) throws

    func save(_ inspection: RentalInspection) throws

    func save(_ observation: InspectionObservation) throws
    
    func delete(_ property: RentalProperty) throws
    
    func update(_ observation: InspectionObservation) throws

    func fetchRentalProperties() throws -> [RentalProperty]

    func fetchUpcomingInspections() throws -> [RentalInspection]

    func fetchInspections(
        for rentalPropertyID: UUID
    ) throws -> [RentalInspection]

    func fetchObservations(
        for inspectionID: UUID
    ) throws -> [InspectionObservation]
}
