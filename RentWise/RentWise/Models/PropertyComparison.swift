import Foundation

struct ComparedProperty {
    let property: RentalProperty
    let inspection: RentalInspection?
    let observations: [InspectionObservation]

    func observation(for criterion: InspectionCriterion) -> InspectionObservation? {
        observations.first { $0.criterion == criterion }
    }
}

struct PropertyComparison {
    let first: ComparedProperty
    let second: ComparedProperty

    var roomNames: [String] {
        var names = InspectionRoom.standardNames
        for room in first.property.rooms + second.property.rooms where !names.contains(room.name) {
            names.append(room.name)
        }
        return names
    }

    // Signed difference: positive means the first property costs more.
    // Unknown rent is never treated as free rent.
    var weeklyRentDifference: Double? {
        let a = first.property.weeklyRent, b = second.property.weeklyRent
        guard a.isFinite, b.isFinite, a > 0, b > 0 else { return nil }
        return a - b
    }
}
