//
//  DeleteRentalPropertyUseCase.swift
//  RentWise
//
//  Created by Zahi Saba on 4/10/2026.
//

import Foundation

enum DeleteRentalPropertyError: Error {
    case rentalPropertyNotFound
}
//Only a property that actually exists in the shortlist can be deleted
struct DeleteRentalPropertyUseCase {

    let repository: RentalPropertyRepository

    func execute(property: RentalProperty) throws {

        let properties = try repository.fetchRentalProperties()

        var propertyExists = false

        for savedProperty in properties {

            if savedProperty.id == property.id {

                propertyExists = true
            }
        }

        if propertyExists == false {

            throw DeleteRentalPropertyError
                .rentalPropertyNotFound
        }

        try repository.delete(
            property
        )
    }
}
