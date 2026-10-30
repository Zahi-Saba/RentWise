import Foundation

enum RoomInspectionError: LocalizedError {
    case propertyNotFound, roomNotFound, missingDescription, defectNotFound, photoTooLarge
    var errorDescription: String? {
        switch self {
        case .propertyNotFound: return "This saved property could not be found."
        case .photoTooLarge: return "This photo is too large. Choose a smaller image."
        case .missingDescription: return "Add a description of the defect."
        case .defectNotFound: return "This defect could not be found."
        case .roomNotFound: return "This room could not be found."
        }
    }
}

struct PrepareRoomsUseCase {
    let repository: RentalPropertyRepository
    func execute(propertyID: UUID) throws -> RentalProperty {
        guard var property = try repository.fetchRentalProperties().first(where: { $0.id == propertyID }) else {
            throw RoomInspectionError.propertyNotFound
        }
        if property.rooms.isEmpty {
            property.rooms = InspectionRoom.standardRooms()
            try repository.update(property)
        }
        return property
    }
}

struct SetRoomInspectedUseCase {
    let repository: RentalPropertyRepository
    func execute(propertyID: UUID, roomID: UUID, checked: Bool) throws -> RentalProperty {
        guard var property = try repository.fetchRentalProperties().first(where: { $0.id == propertyID }) else {
            throw RoomInspectionError.propertyNotFound
        }
        guard let index = property.rooms.firstIndex(where: { $0.id == roomID }) else {
            throw RoomInspectionError.roomNotFound
        }
        property.rooms[index].checked = checked
        try repository.update(property)
        return property
    }
}

struct RecordRoomDefectUseCase {
    let repository: RentalPropertyRepository
    func execute(propertyID: UUID, roomID: UUID, description: String, severity: DefectSeverity, photo: Data? = nil) throws -> RentalProperty {
        let description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !description.isEmpty else { throw RoomInspectionError.missingDescription }
        if let photo, photo.count > 5_000_000 { throw RoomInspectionError.photoTooLarge }
        guard var property = try repository.fetchRentalProperties().first(where: { $0.id == propertyID }) else {
            throw RoomInspectionError.propertyNotFound
        }
        guard let index = property.rooms.firstIndex(where: { $0.id == roomID }) else {
            throw RoomInspectionError.roomNotFound
        }
        property.rooms[index].defects.append(RoomDefect(description: description, severity: severity, photo: photo))
        try repository.update(property)
        return property
    }
}

struct DeleteRoomDefectUseCase {
    let repository: RentalPropertyRepository
    func execute(propertyID: UUID, roomID: UUID, defectID: UUID) throws -> RentalProperty {
        guard var property = try repository.fetchRentalProperties().first(where: { $0.id == propertyID }) else {
            throw RoomInspectionError.propertyNotFound
        }
        guard let index = property.rooms.firstIndex(where: { $0.id == roomID }) else {
            throw RoomInspectionError.roomNotFound
        }
        guard property.rooms[index].defects.contains(where: { $0.id == defectID }) else {
            throw RoomInspectionError.defectNotFound
        }
        property.rooms[index].defects.removeAll { $0.id == defectID }
        try repository.update(property)
        return property
    }
}
