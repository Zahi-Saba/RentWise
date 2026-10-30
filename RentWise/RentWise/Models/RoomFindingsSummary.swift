import Foundation

/// Current property-level findings, separate from dated inspection observations.
struct RoomFindingsSummary {
    let rooms: [InspectionRoom]
    var checkedCount: Int { rooms.filter(\.checked).count }
    var defects: [RoomDefect] { rooms.flatMap(\.defects) }
    var hasFindings: Bool { checkedCount > 0 || !defects.isEmpty }
    func count(for severity: DefectSeverity) -> Int {
        defects.filter { $0.severity == severity }.count
    }
}

extension RentalProperty {
    var roomFindings: RoomFindingsSummary { RoomFindingsSummary(rooms: rooms) }
}
