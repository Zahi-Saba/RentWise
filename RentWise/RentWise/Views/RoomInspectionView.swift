import SwiftUI

struct RoomInspectionView: View {
    @ObservedObject var viewModel: RentWiseViewModel
    let propertyID: UUID
    let roomID: UUID

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
    }
}
