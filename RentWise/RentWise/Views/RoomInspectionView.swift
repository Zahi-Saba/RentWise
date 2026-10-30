import SwiftUI

struct RoomInspectionView: View {
    @ObservedObject var viewModel: RentWiseViewModel
    let propertyID: UUID
    let roomID: UUID
    @State private var showDefect = false

    private var room: InspectionRoom? {
        viewModel.rentalProperties.first { $0.id == propertyID }?.rooms.first { $0.id == roomID }
    }

    var body: some View {
        List {
            if let room {
                Section {
                    Toggle("Room inspected", isOn: Binding(
                        get: { self.room?.checked ?? false },
                        set: { viewModel.setRoomInspected(propertyID: propertyID, roomID: roomID, checked: $0) }
                    ))
                } footer: {
                    Text("Check the room before marking it inspected.")
                }
                Section("Defects") {
                    if room.defects.isEmpty {
                        Text("No defects recorded. Check the room before marking it inspected.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(room.defects) { defect in
                        VStack(alignment: .leading, spacing: 10) {
                            Label(defect.severity.rawValue, systemImage: "exclamationmark.triangle")
                                .font(.headline)
                            Text(defect.description).fixedSize(horizontal: false, vertical: true)
                            if let data = defect.photo, let image = UIImage(data: data) {
                                Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 220)
                                    .accessibilityLabel("Defect photo: \(defect.description)")
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .swipeActions {
                            Button("Delete", role: .destructive) {
                                viewModel.deleteRoomDefect(propertyID: propertyID, roomID: roomID, defectID: defect.id)
                            }
                        }
                    }
                    Button("Record defect", systemImage: "plus.circle") { showDefect = true }
                }
            } else {
                Text("This room is no longer available.").foregroundStyle(.secondary)
            }
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage).foregroundStyle(.red)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(room?.name ?? "Room")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showDefect) {
            AddDefectView(viewModel: viewModel, propertyID: propertyID, roomID: roomID)
        }
    }
}
