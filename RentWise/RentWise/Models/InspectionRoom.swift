import Foundation

/// The property's room checklist, matching the presentation demo.
struct InspectionRoom: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var checked = false
    var defects: [RoomDefect] = []

    // Earlier room checklists did not have defects yet.
    private enum CodingKeys: String, CodingKey { case id, name, checked, defects }
    init(id: UUID = UUID(), name: String, checked: Bool = false, defects: [RoomDefect] = []) {
        self.id = id; self.name = name; self.checked = checked; self.defects = defects
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        checked = try values.decode(Bool.self, forKey: .checked)
        defects = try values.decodeIfPresent([RoomDefect].self, forKey: .defects) ?? []
    }

    static let standardNames = ["Kitchen", "Bathroom", "Bedroom", "Living Area"]

    static func standardRooms() -> [InspectionRoom] {
        standardNames.map { InspectionRoom(name: $0) }
    }
}
