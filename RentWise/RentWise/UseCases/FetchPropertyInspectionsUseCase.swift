import Foundation

struct FetchPropertyInspectionsUseCase {
    let repository: RentalPropertyRepository
    func execute(propertyID: UUID) throws -> [RentalInspection] {
        try repository.fetchInspections(for: propertyID).sorted { $0.startTime > $1.startTime }
    }
}
