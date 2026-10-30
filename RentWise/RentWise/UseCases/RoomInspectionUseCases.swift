import Foundation

enum RoomInspectionError: LocalizedError {
    case propertyNotFound, roomNotFound
    var errorDescription: String? {
        switch self {
        case .propertyNotFound: return "This saved property could not be found."
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
