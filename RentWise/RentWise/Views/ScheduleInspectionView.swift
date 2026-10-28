
import SwiftUI

struct ScheduleInspectionView: View {

    @ObservedObject var viewModel: RentWiseViewModel
    let property: RentalProperty

    @Environment(\.dismiss) private var dismiss

    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(30 * 60)
    @State private var showConfirmation = false
    @State private var reminderMessage = ""
    @State private var isScheduling = false

    var body: some View {
        Form {
            Section {
                Label("Your inspection", systemImage: "calendar.badge.plus")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)

                Text(property.address)
                    .font(.headline)

                Text(property.rentLabel)
                    .foregroundStyle(.secondary)
            }

            Section {
                DatePicker("Starts", selection: $startTime)
                DatePicker("Ends", selection: $endTime)
            } header: {
                Text("Date & time")
            } footer: {
                Text("Choose the start and end of your visit. The end must be after the start.")
            }

            if !viewModel.errorMessage.isEmpty {
                Section {
                    Text(viewModel.errorMessage)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    scheduleInspection()
                } label: {
                    if isScheduling {
                        ProgressView("Setting reminder...")
                    } else {
                        Label(
                            "Schedule Inspection",
                            systemImage: "calendar.badge.plus"
                        )
                        .font(.headline)
                        .padding(.vertical, 6)
                    }
                }
                .disabled(isScheduling)
            }
        }
        .tint(Color.accentColor)
        .navigationTitle("Schedule Inspection")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.errorMessage = ""
        }
        .alert("Inspection Scheduled", isPresented: $showConfirmation) {
            Button("Done") {
                dismiss()
            }
        } message: {
            Text(reminderMessage)
        }
    }

    private func scheduleInspection() {

        guard let inspection = viewModel.scheduleInspection(
            rentalPropertyID: property.id,
            startTime: startTime,
            endTime: endTime
        ) else {
            return
        }

        isScheduling = true

        Task {
            var message = "Your inspection has been saved."

            let reminderDate = inspection.startTime.addingTimeInterval(-30 * 60)

            if reminderDate <= Date() {
                message += " No reminder was set because the inspection is less than 30 minutes away or has already started."
            } else {
                do {
                    let service = InspectionNotificationService()

                    let allowed = try await service.requestPermission()

                    if allowed {
                        try await service.scheduleReminder(
                            for: inspection,
                            propertyAddress: property.address
                        )

                        message += " You'll receive a reminder 30 minutes before it starts."
                    } else {
                        message += " Notifications are disabled, so no reminder was set."
                    }
                } catch {
                    message += " The notification reminder could not be scheduled."
                }
            }

            reminderMessage = message
            isScheduling = false
            showConfirmation = true
        }
    }
}
