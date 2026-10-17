//
//  SaveRentalPropertyUseCase.swift
//  RentWise
//
//  Created by Zahi Saba on 29/9/2026.
//

import Foundation

enum SaveRentalPropertyError: Error {
    case missingAddress
    case invalidWeeklyRent
}
//A rental property must have an address.
//Weekly rent must be greater than $0.
struct SaveRentalPropertyUseCase {

    private let repository: RentalPropertyRepository

    init(repository: RentalPropertyRepository) {
        self.repository = repository
    }

    func execute(address: String, weeklyRent: Double) throws -> RentalProperty {

        if address.isEmpty {
            throw SaveRentalPropertyError.missingAddress
        }

        if weeklyRent <= 0 {
            throw SaveRentalPropertyError.invalidWeeklyRent
        }

        let property = RentalProperty(
            address: address,
            weeklyRent: weeklyRent
        )

        try repository.save(property)

        return property
    }
}
