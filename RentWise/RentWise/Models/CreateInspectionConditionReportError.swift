//
//  CreateInspectionConditionReportError.swift
//  RentWise
//
//  Created by Bo Wen Chan on 27/10/2026.
//

import Foundation

enum CreateInspectionConditionReportError: LocalizedError {
    case propertyNotFound
    case inspectionNotFound
    case noObservations
    case mismatchedObservations

    var errorDescription: String? {
        switch self {
        case .propertyNotFound:
            return "The selected rental property is no longer available."

        case .inspectionNotFound:
            return "The selected inspection does not belong to this property or no longer exists."

        case .noObservations:
            return "Record at least one inspection observation before generating a condition report."

        case .mismatchedObservations:
            return "Some inspection observations do not belong to this inspection."
        }
    }
}
