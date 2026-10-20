import SwiftUI

struct RentalPropertyDetailView: View {
    @ObservedObject var viewModel: RentWiseViewModel
    let property: RentalProperty

    private var currentProperty: RentalProperty {
        viewModel.rentalProperties.first { $0.id == property.id } ?? property
    }
    private var inspections: [RentalInspection] {
        viewModel.propertyInspections.filter { $0.rentalPropertyID == property.id }
    }
    private var latestObservations: [InspectionObservation] {
        guard viewModel.latestPropertyInspection?.rentalPropertyID == property.id else { return [] }
        return viewModel.latestPropertyObservations
    }

    var body: some View {
        List {
            Section {
                if let source = currentProperty.sourceURL, let url = URL(string: source) {
                    Link(destination: url) {
                        VStack(alignment: .leading, spacing: 14) {
                            ListingLinkPreview(url: url, service: viewModel.listingPreviewService)
                            rentHeading
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(currentProperty.rentLabel). Open original listing")
                    .accessibilityHint("Opens the property website in your browser")
                } else {
                    rentHeading
                }
                Label("Saved property", systemImage: "bookmark.fill")
                    .font(.caption.weight(.semibold)).foregroundStyle(.teal)
                Text(currentProperty.address).font(.title3.bold()).textSelection(.enabled)
                if currentProperty.weeklyRent <= 0, currentProperty.sourceURL != nil {
                    Text("To update the rent, open the listing in Safari and share it to Rentwise again after the weekly price loads.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }

            Section("Inspection") {
                NavigationLink {
                    ScheduleInspectionView(viewModel: viewModel, property: currentProperty)
                } label: {
                    Label("Schedule Inspection", systemImage: "calendar.badge.plus")
                        .font(.headline).foregroundStyle(.teal).padding(.vertical, 6)
                }
                if inspections.isEmpty {
                    Label("No inspections scheduled", systemImage: "calendar")
                        .foregroundStyle(.secondary)
                }
                ForEach(inspections) { inspection in
                    NavigationLink {
                        InspectionChecklistView(viewModel: viewModel, inspection: inspection)
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(inspection.startTime.formatted(date: .abbreviated, time: .shortened)).font(.headline)
                            Text(inspection.endTime < Date() ? "Past inspection • View or edit observations" : "Scheduled • Record observations")
                                .font(.caption).foregroundStyle(.secondary)
                        }.padding(.vertical, 4)
                    }
                }
            }

            Section {
                ForEach(InspectionCriterion.allCases, id: \.self) { criterion in
                    observationRow(criterion)
                }
            } header: {
                Text("Latest inspection observations")
            } footer: {
                if let inspection = viewModel.latestPropertyInspection,
                   inspection.rentalPropertyID == property.id {
                    Text("From the inspection on \(inspection.startTime.formatted(date: .abbreviated, time: .shortened)).")
                } else {
                    Text("Open a scheduled inspection above to record your observations.")
                }
            }
            if !viewModel.errorMessage.isEmpty {
                Section { Text(viewModel.errorMessage).foregroundStyle(.red) }
            }
        }
        .listStyle(.insetGrouped)
        .tint(.teal)
        .navigationTitle("Property")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.loadPropertyDetails(for: property.id) }
    }

    private var rentHeading: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(currentProperty.rentLabel).font(.title.bold()).foregroundStyle(.primary)
            Spacer(minLength: 8)
            if currentProperty.sourceURL != nil {
                Image(systemName: "arrow.up.right").foregroundStyle(.teal).accessibilityHidden(true)
            }
        }
    }

    private func observationRow(_ criterion: InspectionCriterion) -> some View {
        let observation = latestObservations.first { $0.criterion == criterion }
        let status = observation?.status ?? .notChecked
        return VStack(alignment: .leading, spacing: 7) {
            Text(criterion == .roomSpace ? "Room Space" : criterion.rawValue.capitalized).font(.headline)
            Label(statusLabel(status), systemImage: statusIcon(status))
                .font(.subheadline).foregroundStyle(statusColor(status))
            if let observation, !observation.notes.isEmpty {
                Text(observation.notes).font(.subheadline).foregroundStyle(.secondary)
            }
        }.padding(.vertical, 5)
    }
    private func statusLabel(_ status: ObservationStatus) -> String {
        switch status {
        case .notChecked: return "Not Checked"
        case .meetsNeeds: return "Meets Needs"
        case .doesNotMeetNeeds: return "Doesn't Meet Needs"
        case .needsClarification: return "Needs Clarification"
        }
    }
    private func statusIcon(_ status: ObservationStatus) -> String {
        switch status {
        case .notChecked: return "circle.dashed"
        case .meetsNeeds: return "checkmark.circle"
        case .doesNotMeetNeeds: return "xmark.circle"
        case .needsClarification: return "questionmark.circle"
        }
    }
    private func statusColor(_ status: ObservationStatus) -> Color {
        switch status {
        case .notChecked: return .secondary
        case .meetsNeeds: return .teal
        case .doesNotMeetNeeds: return .red
        case .needsClarification: return .orange
        }
    }
}
