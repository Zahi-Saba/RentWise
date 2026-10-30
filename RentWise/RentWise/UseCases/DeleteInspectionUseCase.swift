import Foundation

enum DeleteInspectionError: LocalizedError {
    case inspectionNotFound
    var errorDescription: String? { "This inspection could not be found." }
}

struct DeleteInspectionUseCase {
    let repository: RentalPropertyRepository

    func execute(inspection: RentalInspection) throws {
        let saved = try repository.fetchInspections(for: inspection.rentalPropertyID)
        guard saved.contains(where: { $0.id == inspection.id }) else {
            throw DeleteInspectionError.inspectionNotFound
        }
        try repository.delete(inspection)
    }
}
