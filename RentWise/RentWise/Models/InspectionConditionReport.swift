//
//  InspectionConditionReport.swift
//  RentWise
//
//  Created by Bo Wen Chan on 27/10/2026.
//

import Foundation

struct InspectionConditionReport {
    // The property being inspected
    let property: RentalProperty

    // The inspection associated with the property
    let inspection: RentalInspection

    // Recorded inspection findings, including status and notes
    let observations: [InspectionObservation]

    // The date and time the report was generated
    let generatedAt: Date
}
