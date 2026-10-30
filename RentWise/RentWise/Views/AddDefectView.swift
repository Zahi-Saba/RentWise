import SwiftUI

struct AddDefectView: View {
    @ObservedObject var viewModel: RentWiseViewModel
    let propertyID: UUID
    let roomID: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var description = ""
    @State private var severity: DefectSeverity = .minor

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Describe the defect", text: $description, axis: .vertical)
                        .lineLimit(3...8).accessibilityLabel("Defect description")
                    Picker("Severity", selection: $severity) {
                        ForEach(DefectSeverity.allCases) { Text($0.rawValue).tag($0) }
                    }
                }
                Section {
                    Button("Save defect") {
                        if viewModel.recordRoomDefect(propertyID: propertyID, roomID: roomID,
                                                      description: description, severity: severity) { dismiss() }
                    }
                    .disabled(description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("Record defect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}
