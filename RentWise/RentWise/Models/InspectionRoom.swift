import Foundation

/// The property's room checklist, matching the presentation demo.
struct InspectionRoom: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var checked = false

    static func standardRooms() -> [InspectionRoom] {
        ["Kitchen", "Bathroom", "Bedroom", "Living Area"].map { InspectionRoom(name: $0) }
    }
}
