import SwiftUI

struct RoomFindingsView: View {
    let name: String
    let room: InspectionRoom?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(name).font(.headline).accessibilityAddTraits(.isHeader)
            Label(room?.checked == true ? "Inspected" : "Not checked",
                  systemImage: room?.checked == true ? "checkmark.circle" : "circle")
                .font(.subheadline)
            if let room, !room.defects.isEmpty {
                Text("\(room.defects.count) recorded defects").font(.caption).foregroundStyle(.secondary)
                ForEach(room.defects) { defect in
                    VStack(alignment: .leading, spacing: 8) {
                        Label(defect.severity.rawValue, systemImage: "exclamationmark.triangle")
                            .font(.subheadline.bold())
                        Text(defect.description).font(.subheadline)
                        if let data = defect.photo, let image = UIImage(data: data) {
                            Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 180)
                                .accessibilityLabel("Defect photo: \(defect.description)")
                        }
                    }
                    .accessibilityElement(children: .combine)
                    Divider()
                }
            } else {
                Text(room?.checked == true ? "No defects recorded" : "No defects recorded; room has not been checked")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
