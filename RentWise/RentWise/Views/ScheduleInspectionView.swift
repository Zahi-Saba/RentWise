import SwiftUI

struct ScheduleInspectionView: View {
    @ObservedObject var viewModel: RentWiseViewModel
    let property: RentalProperty
    @Environment(\.dismiss) private var dismiss
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(30 * 60)
    @State private var showConfirmation = false

    var body: some View {
        Form {
            Section {
                Label("Your inspection", systemImage: "calendar.badge.plus")
                    .font(.headline).foregroundStyle(Color.accentColor)
                Text(property.address).font(.headline)
                Text(property.rentLabel).foregroundStyle(.secondary)
            }
            Section {
                DatePicker("Starts", selection: $startTime)
                DatePicker("Ends", selection: $endTime)
            } header: { Text("Date & time") } footer: {
                Text("Choose the start and end of your visit. The end must be after the start.")
            }
            if !viewModel.errorMessage.isEmpty {
                Section { Text(viewModel.errorMessage).foregroundStyle(.red) }
            }
            Section {
                Button {
                    viewModel.scheduleInspection(rentalPropertyID: property.id, startTime: startTime, endTime: endTime)
                    showConfirmation = viewModel.errorMessage.isEmpty
                } label: {
                    Label("Schedule Inspection", systemImage: "calendar.badge.plus")
                        .font(.headline).padding(.vertical, 6)
                }
            }
        }
        .tint(Color.accentColor)
        .navigationTitle("Schedule Inspection")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.errorMessage = "" }
        .alert("Inspection Scheduled", isPresented: $showConfirmation) {
            Button("Done") { dismiss() }
        } message: { Text("Your visit has been saved. Open it from the property page to record observations.") }
    }
}
