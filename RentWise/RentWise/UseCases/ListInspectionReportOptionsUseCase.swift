//
//  ListInspectionReportOptionsUseCase.swift
//  RentWise
//
//  Created by Bo Wen Chan on 27/10/2026.
//

import Foundation

struct InspectionReportOption: Identifiable {
    var id: UUID { inspection.id }

    let property: RentalProperty
    let inspection: RentalInspection
    let observationCount: Int

    // Only inspections containing recorded findings  are ready for report generation
    var canGenerateReport: Bool {observationCount > 0}
}

struct ListInspectionReportOptionsUseCase {
    private let repository: RentalPropertyRepository

    init(repository: RentalPropertyRepository) {
        self.repository = repository
    }

    func execute() throws -> [InspectionReportOption] {
        let properties = try repository.fetchRentalProperties()

        var options: [InspectionReportOption] = []

        for property in properties {
            // Fetch inspections associated with this property
            let inspections = try repository.fetchInspections(for: property.id)

            for inspection in inspections {
                // Check whether the inspection has recorded findings
                let observations = try repository.fetchObservations(for: inspection.id)

                let option = InspectionReportOption(property: property, inspection: inspection, observationCount: observations.count)

                options.append(option)
            }
        }

        // Show the most recent inspections first
        return options.sorted {$0.inspection.startTime > $1.inspection.startTime
}
    }
}
