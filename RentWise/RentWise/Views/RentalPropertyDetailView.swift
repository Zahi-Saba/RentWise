import SwiftUI

struct RentalPropertyDetailView: View {
    @ObservedObject var viewModel: RentWiseViewModel
    let property: RentalProperty
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
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
                    .accessibilityLabel("\(currentProperty.address). " + "\(currentProperty.rentLabel). Open original listing.")
                    .accessibilityHint("Opens the property website in your browser")
                } else {
                    rentHeading
                }
                Label("Saved property", systemImage: "bookmark.fill")
                    .font(.caption.weight(.semibold)).foregroundStyle(Color.accentColor)
                Text(currentProperty.address)
                    .font(.title3.bold())
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                
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
                        .font(.headline).foregroundStyle(Color.accentColor).padding(.vertical, 6)
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
                    // Announce the inspection's date and current status
                    .accessibilityLabel(
                        "Inspection on " +
                        "\(inspection.startTime.formatted(date: .abbreviated, time: .shortened)). " +
                        (inspection.endTime < Date() ? "Past inspection.": "Scheduled inspection.")
                    )
                    .accessibilityHint(
                        "Opens the inspection checklist to review or record observations."
                    )
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
        .tint(Color.accentColor)
        .navigationTitle("Property")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.loadPropertyDetails(for: property.id) }
    }


    // Displays the weekly rent using a layout that adapts to the user's preferred Dynamic Type size
    private var rentHeading: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    rentAmountText

                    if currentProperty.sourceURL != nil {
                        Label(
                            "Open original listing",
                            systemImage: "arrow.up.right"
                        )
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)
                    }
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    rentAmountText

                    Spacer(minLength: 8)

                    if currentProperty.sourceURL != nil {
                        Image(systemName: "arrow.up.right")
                            .foregroundStyle(Color.accentColor)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
    }

    private var rentAmountText: some View {
        Text(currentProperty.rentLabel)
            .font(.title.bold())
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func observationRow(_ criterion: InspectionCriterion) -> some View {
        let observation = latestObservations.first { $0.criterion == criterion }
        let status = observation?.status ?? .notChecked
        return VStack(alignment: .leading, spacing: 7) {
            Text(criterion == .roomSpace ? "Room Space" : criterion.rawValue.capitalized).font(.headline)
            InspectionStatusLabel(status: status)
            if let observation, !observation.notes.isEmpty {
                Text(observation.notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .combine)
    }
}
