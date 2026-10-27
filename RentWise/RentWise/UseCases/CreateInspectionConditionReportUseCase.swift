//
//  CreateInspectionConditionReportUseCase.swift
//  RentWise
//
//  Created by Bo Wen Chan on 27/10/2026.
//

import Foundation

struct CreateInspectionConditionReportUseCase {
    private let repository: RentalPropertyRepository

    init(repository: RentalPropertyRepository) {
        self.repository = repository
    }

    func execute(propertyID: UUID, inspectionID: UUID, generatedAt: Date = Date()) throws -> InspectionConditionReport {
        // Find the selected property
        guard let property = try repository.fetchRentalProperties().first(where: { $0.id == propertyID }) else {
            throw CreateInspectionConditionReportError.propertyNotFound
        }

        // Verify that the selected inspection belongs to this property
        guard let inspection = try repository.fetchInspections(for: propertyID).first(where: {$0.id == inspectionID && $0.rentalPropertyID == propertyID}) else {
            throw CreateInspectionConditionReportError.inspectionNotFound
        }

        // Retrieve the saved inspection observations
        let observations = try repository.fetchObservations(for: inspection.id)

        // A condition report should contain recorded findings
        guard !observations.isEmpty else {
            throw CreateInspectionConditionReportError.noObservations
        }

        // Protect against accidentally mixing observations from different inspections
        guard observations.allSatisfy({$0.inspectionID == inspection.id}) else {
            throw CreateInspectionConditionReportError.mismatchedObservations
        }

        // Arrange findings in the same order as the inspection checklist
        let criteria = InspectionCriterion.allCases

        let sortedObservations = observations.sorted {
            let leftIndex = criteria.firstIndex(of: $0.criterion) ?? Int.max

            let rightIndex = criteria.firstIndex(of: $1.criterion) ?? Int.max

            if leftIndex == rightIndex {return $0.id.uuidString < $1.id.uuidString}

            return leftIndex < rightIndex
        }

        // Return the complete report domain model
        return InspectionConditionReport(property: property, inspection: inspection, observations: sortedObservations, generatedAt: generatedAt)
    }
}

