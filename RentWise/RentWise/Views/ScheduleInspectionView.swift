import SwiftUI

struct ScheduleInspectionView: View {
    @ObservedObject var viewModel: RentWiseViewModel
    let property: RentalProperty
    @Environment(\.dismiss) private var dismiss
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(30 * 60)
    @State private var showConfirmation = false
    
    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    var body: some View {
        Form {
            Section {
                Label("Your inspection", systemImage: "calendar.badge.plus")
                    .font(.headline).foregroundStyle(Color.accentColor)
                
                Text(property.address)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(property.rentLabel).foregroundStyle(.secondary)
            }
            
            Section {
                // Use adaptive layouts for both inspection times
                inspectionDatePicker("Starts", selection: $startTime)

                inspectionDatePicker("Ends", selection: $endTime)
            } header: {
                Text("Date & time")

            } footer: {
                Text(
                    "Choose the start and end of your visit. " +
                    "The end must be after the start."
                )
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
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(minHeight: 44)
                        .padding(.vertical, 6)
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
    
    @ViewBuilder
    private func inspectionDatePicker(_ title: String, selection: Binding<Date>) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)

                // Separate date control
                DatePicker("\(title) date", selection: selection, displayedComponents: .date)
                    .labelsHidden()

                // Separate time control
                DatePicker("\(title) time", selection: selection, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)

        } else {
            // Standard layout remains unchanged
            DatePicker(title, selection: selection)
        }
    }
}
