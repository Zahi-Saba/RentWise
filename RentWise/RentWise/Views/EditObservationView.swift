import SwiftUI

struct EditObservationView: View {
    @ObservedObject var viewModel: RentWiseViewModel
    let observation: InspectionObservation
    @State private var status: ObservationStatus
    @State private var notes: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

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
                    .font(.title3.bold()).foregroundStyle(Color.accentColor)
            }
            
            Section("Result") {
                observationStatusPicker
            }
            
            Section("Your notes") {
                TextField("What did you notice?", text: $notes, axis: .vertical)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 6...14 : 4...10)
                    .accessibilityLabel("Observation notes")
                
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
            .tint(Color.accentColor)
            .navigationTitle("Edit Observation")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { viewModel.errorMessage = "" }
        }
    }
    
    // Uses a vertical list at accessibility text sizes to avoid truncating long status labels.
    @ViewBuilder
    private var observationStatusPicker: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Picker("Status", selection: $status) {
                ForEach(ObservationStatus.allCases, id: \.self) {
                    Text($0.displayName).tag($0)
                }
            }
            .pickerStyle(.inline)

        } else {
            Picker("Status", selection: $status) {
                ForEach(ObservationStatus.allCases, id: \.self) {
                    Text($0.displayName).tag($0)
                }
            }
        }
    }
}
