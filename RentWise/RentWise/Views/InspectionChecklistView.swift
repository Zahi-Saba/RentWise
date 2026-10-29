import SwiftUI

struct InspectionChecklistView: View {
    @ObservedObject var viewModel: RentWiseViewModel
    let inspection: RentalInspection
    @State private var criterion: InspectionCriterion = .noise
    @State private var status: ObservationStatus = .notChecked
    @State private var notes = ""
    @State private var saved = false
    
    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    private var observations: [InspectionObservation] {
        viewModel.observations.filter { $0.inspectionID == inspection.id }
    }

    var body: some View {
        Form {
            Section {
                Label(viewModel.propertyAddress(for: inspection.rentalPropertyID), systemImage: "house")
                    .font(.headline)
                Text(inspection.startTime.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(.secondary)
            }
            
            Section("New observation") {
                // Adaptive inspection criterion picker
                inspectionItemPicker

                // Adaptive result/status picker
                observationResultPicker

                TextField("What did you notice?", text: $notes, axis: .vertical)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 5...12 : 3...8)
                    .accessibilityLabel("Observation notes")
            }

            Section {
                Button {
                    viewModel.recordObservation(inspectionID: inspection.id, criterion: criterion,
                                                status: status, notes: notes.trimmingCharacters(in: .whitespacesAndNewlines))
                    if viewModel.errorMessage.isEmpty { notes = ""; saved = true }
                } label: { Label("Save Observation", systemImage: "checkmark.circle").font(.headline).padding(.vertical, 6) }
            } footer: { Text("Add notes for each result. To change a recorded item, tap its saved observation below.") }
            if !viewModel.errorMessage.isEmpty {
                Section { Text(viewModel.errorMessage).foregroundStyle(.red) }
            }
            Section("Saved observations • \(observations.count) of 5") {
                if observations.isEmpty {
                    Label("No observations recorded yet", systemImage: "list.bullet.clipboard")
                        .foregroundStyle(.secondary)
                }
                ForEach(observations) { observation in
                    NavigationLink {
                        EditObservationView(viewModel: viewModel, observation: observation)
                    } label: { InspectionObservationSummary(observation: observation) }
                }
            }
        }
        .tint(Color.accentColor)
        .navigationTitle("Inspection Observations")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadRentalProperties()
            viewModel.loadObservations(for: inspection.id)
        }
        .alert("Observation Saved", isPresented: $saved) { Button("Done", role: .cancel) {} }
    }
    
    //Shows the inspection criteria as an inline list  when accessibility text sizes are enabled
    @ViewBuilder
    private var inspectionItemPicker: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Picker("Inspection item", selection: $criterion) {
                ForEach(InspectionCriterion.allCases, id: \.self) {
                    Text($0.displayName).tag($0)
                }
            }
            .pickerStyle(.inline)

        } else {
            // Preserve the existing compact picker layout
            Picker("Inspection item", selection: $criterion) {
                ForEach(InspectionCriterion.allCases, id: \.self) {
                    Text($0.displayName).tag($0)
                }
            }
        }
    }

    /// Displays results in an expanded list for users  with larger accessibility text settings
    @ViewBuilder
    private var observationResultPicker: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Picker("Result", selection: $status) {
                ForEach(ObservationStatus.allCases, id: \.self) {
                    Text($0.displayName).tag($0)
                }
            }
            .pickerStyle(.inline)

        } else {
            Picker("Result", selection: $status) {
                ForEach(ObservationStatus.allCases, id: \.self) {
                    Text($0.displayName).tag($0)
                }
            }
        }
    }
}
