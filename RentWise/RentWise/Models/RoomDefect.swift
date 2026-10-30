import Foundation

enum DefectSeverity: String, Codable, CaseIterable, Identifiable {
    case minor = "Minor"
    case moderate = "Moderate"
    case major = "Major"
    var id: String { rawValue }
}

struct RoomDefect: Codable, Identifiable, Equatable {
    var id = UUID()
    var description: String
    var severity: DefectSeverity
    var photo: Data? = nil
}
