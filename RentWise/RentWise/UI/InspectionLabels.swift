import SwiftUI

extension InspectionCriterion {
    var displayName: String { self == .roomSpace ? "Room Space" : rawValue.capitalized }
}

extension ObservationStatus {
    var displayName: String {
        switch self {
        case .notChecked: return "Not Checked"
        case .meetsNeeds: return "Meets Needs"
        case .doesNotMeetNeeds: return "Doesn't Meet Needs"
        case .needsClarification: return "Needs Clarification"
        }
    }
    var symbol: String {
        switch self {
        case .notChecked: return "circle.dashed"
        case .meetsNeeds: return "checkmark.circle"
        case .doesNotMeetNeeds: return "xmark.circle"
        case .needsClarification: return "questionmark.circle"
        }
    }
    var color: Color {
        switch self {
        case .notChecked: return .secondary
        case .meetsNeeds: return .teal
        case .doesNotMeetNeeds: return .red
        case .needsClarification: return .orange
        }
    }
}

struct InspectionObservationSummary: View {
    let observation: InspectionObservation
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(observation.criterion.displayName).font(.headline)
            Label(observation.status.displayName, systemImage: observation.status.symbol)
                .font(.subheadline).foregroundStyle(observation.status.color)
            Text(observation.notes).font(.subheadline).foregroundStyle(.secondary)
        }.padding(.vertical, 5)
    }
}
