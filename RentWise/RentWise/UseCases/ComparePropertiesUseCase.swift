import Foundation

enum ComparePropertiesError: LocalizedError {
    case sameProperty, propertyNotFound
    var errorDescription: String? {
        switch self {
        case .sameProperty: return "Choose two different properties."
        case .propertyNotFound: return "A selected property is no longer saved. Choose again."
        }
    }
}

struct ComparePropertiesUseCase {
    let repository: RentalPropertyRepository

    func execute(firstID: UUID, secondID: UUID) throws -> PropertyComparison {
        guard firstID != secondID else { throw ComparePropertiesError.sameProperty }
        let properties = try repository.fetchRentalProperties()
        guard let first = properties.first(where: { $0.id == firstID }),
              let second = properties.first(where: { $0.id == secondID }) else {
            throw ComparePropertiesError.propertyNotFound
        }
        return try PropertyComparison(first: snapshot(first), second: snapshot(second))
    }

    private func snapshot(_ property: RentalProperty) throws -> ComparedProperty {
        let inspections = try repository.fetchInspections(for: property.id).sorted {
            if $0.startTime == $1.startTime { return $0.id.uuidString < $1.id.uuidString }
            return $0.startTime > $1.startTime
        }
        // Compare one dated inspection per property; do not mix visits.
        // A new scheduled visit without observations does not hide earlier findings.
        for inspection in inspections {
            let observations = try repository.fetchObservations(for: inspection.id)
            if !observations.isEmpty {
                return ComparedProperty(property: property, inspection: inspection, observations: observations)
            }
        }
        return ComparedProperty(property: property, inspection: nil, observations: [])
    }
}
