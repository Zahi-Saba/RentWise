import SwiftUI

struct EditObservationView: View {
    @ObservedObject var viewModel: RentWiseViewModel
    let observation: InspectionObservation
    @State private var status: ObservationStatus
    @State private var notes: String
    @Environment(\.dismiss) private var dismiss

    init(viewModel: RentWiseViewModel, observation: InspectionObservation) {
        self.viewModel = viewModel
        self.observation = observation
        _status = State(initialValue: observation.status)
        _notes = State(initialValue: observation.notes)
    }

    var body: some View {
        Form {
            Section {
                Label(observation.criterion.displayName, systemImage: "pencil.circle")
                    .font(.title3.bold()).foregroundStyle(.teal)
            }
            Section("Result") {
                Picker("Status", selection: $status) {
                    ForEach(ObservationStatus.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
            }
            Section("Your notes") {
                TextField("What did you notice?", text: $notes, axis: .vertical)
                    .lineLimit(4...10).accessibilityLabel("Observation notes")
            }
            if !viewModel.errorMessage.isEmpty {
                Section { Text(viewModel.errorMessage).foregroundStyle(.red) }
            }
            Section {
                Button {
                    viewModel.updateObservation(observation: observation, status: status,
                                                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines))
                    if viewModel.errorMessage.isEmpty { dismiss() }
                } label: { Label("Save Changes", systemImage: "checkmark.circle").font(.headline).padding(.vertical, 6) }
            }
        }
        .tint(.teal)
        .navigationTitle("Edit Observation")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.errorMessage = "" }
    }
}
