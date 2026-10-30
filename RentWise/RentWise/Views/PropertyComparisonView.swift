import SwiftUI

struct PropertyComparisonView: View {
    @ObservedObject var viewModel: RentWiseViewModel
    @State private var firstID: UUID?
    @State private var secondID: UUID?
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Find the better fit", systemImage: "rectangle.split.2x1")
                        .font(.title2.bold())
                    Text("Choose two saved properties to compare rent and inspection observations.")
                        .foregroundStyle(.secondary)
                    if viewModel.rentalProperties.count < 2 {
                        Label("Save at least two properties to compare.", systemImage: "house")
                            .foregroundStyle(.secondary)
                    } else {
                        selector("Property A", selection: $firstID, excluding: secondID)
                        selector("Property B", selection: $secondID, excluding: firstID)
                        Button(action: compare) {
                            Label("Compare Properties", systemImage: "rectangle.split.2x1")
                                .font(.headline)
                                // Allow enlarged text to occupy multiple lines
                                .fixedSize(horizontal: false, vertical: true)
                                // Fill the available horizontal space
                                .frame(maxWidth: .infinity)
                                // Maintain a minimum 44-point interactive label height
                                .frame(minHeight: 44)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(firstID == nil || secondID == nil || firstID == secondID)
                        .accessibilityHint("Compares weekly rent and inspection findings " + "for the two selected properties.")
                    }
                }
                .padding().background(.background, in: RoundedRectangle(cornerRadius: 20))

                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                if !viewModel.comparisonError.isEmpty {
                    Label("Comparison error: \(viewModel.comparisonError)", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                if let result = viewModel.comparison {
                    Text(rentSummary(result))
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    
                    Text("Observations come from each property's latest inspection with saved notes. Dates may differ; unrecorded items are shown as Not Checked.")
                        .font(.footnote).foregroundStyle(.secondary)
                    
                    // Keep rows aligned while allowing large text to grow vertically
                    if typeSize.isAccessibilitySize {
                        accessibleComparison(result)
                    } else {
                        ScrollView(.horizontal) {
                            comparisonTable(result, width: 170)
                        }
                        .accessibilityHint(
                            "Scroll horizontally to compare both properties."
                        )
                    }
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .tint(Color.accentColor)
        .navigationTitle("Compare")
        .onAppear(perform: refresh)
        .onChange(of: scenePhase) { _, phase in if phase == .active { refresh() } }
        .onChange(of: firstID) { _, _ in viewModel.clearComparison() }
        .onChange(of: secondID) { _, _ in viewModel.clearComparison() }
        .refreshable { refresh() }
    }

    private func selector(_ title: String, selection: Binding<UUID?>, excluding: UUID?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption.bold()).foregroundStyle(.secondary)
            Picker(title, selection: selection) {
                Text("Choose a property").tag(nil as UUID?)
                ForEach(viewModel.rentalProperties.filter { $0.id != excluding }) {
                    Text($0.address).tag(Optional($0.id))
                }
            }.labelsHidden().pickerStyle(.menu).accessibilityLabel(title)
        }
    }

    private func comparisonTable(_ result: PropertyComparison, width: CGFloat) -> some View {
        Grid(alignment: .topLeading, horizontalSpacing: 16, verticalSpacing: 16) {
            GridRow {
                header(result.first, label: "Property A", width: width)
                header(result.second, label: "Property B", width: width)
            }
            ForEach(InspectionCriterion.allCases, id: \.self) { criterion in
                GridRow {
                    observationCell(result.first, criterion: criterion, width: width)
                    observationCell(result.second, criterion: criterion, width: width)
                }
            }
        }.padding().background(.background, in: RoundedRectangle(cornerRadius: 20))
    }

    
    // MARK: - Accessibility Comparison Layout

    /// Displays each property vertically when the user
    /// enables larger accessibility text sizes.
    private func accessibleComparison(
        _ result: PropertyComparison
    ) -> some View {

        VStack(alignment: .leading, spacing: 20) {

            accessiblePropertyCard(
                result.first,
                label: "Property A"
            )

            accessiblePropertyCard(
                result.second,
                label: "Property B"
            )
        }
    }

    private func accessiblePropertyCard(_ item: ComparedProperty, label: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Property information and weekly rent
            header(item, label: label, width: nil)

            Divider()

            // Display all comparison criteria vertically
            ForEach(InspectionCriterion.allCases, id: \.self) { criterion in
                observationCell(item, criterion: criterion, width: nil)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 20)
        )
    }
    
    private func header(_ item: ComparedProperty, label: String, width: CGFloat?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label).font(.caption.bold()).foregroundStyle(Color.accentColor)
            
            Text(item.property.address)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(item.property.rentLabel)
                .font(.title3.bold())
                .fixedSize(horizontal: false, vertical: true)
            
            if let inspection = item.inspection {
                Text("Inspection: \(inspection.startTime.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text("No recorded observations").font(.caption).foregroundStyle(.secondary)
            }
            
            NavigationLink {
                RentalPropertyDetailView(viewModel: viewModel, property: item.property)
            } label: {
                Label("Open property", systemImage: "arrow.up.right")
                    .font(.subheadline.weight(.semibold))
                    // Allow the label to wrap at larger Dynamic Type sizes
                    .fixedSize(horizontal: false, vertical: true)

                    // Ensure the interactive label has at least 44 pt height
                    .frame(maxWidth: .infinity, minHeight: 44)

                    // Make the full rectangular label area interactive
                    .contentShape(Rectangle())
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Open \(item.property.address)")
            .accessibilityHint("Opens the property's details and inspections.")
        }
        .frame(width: width, alignment: .leading)
    }

    private func observationCell(_ item: ComparedProperty, criterion: InspectionCriterion, width: CGFloat?) -> some View {
        let observation = item.observation(for: criterion)
        let status = observation?.status ?? .notChecked
        return VStack(alignment: .leading, spacing: 8) {
            Divider()
            Text(criterion.displayName).font(.headline)
            Label(status.displayName, systemImage: status.symbol)
                .foregroundStyle(status.color).font(.subheadline)
            
            if let observation, !observation.notes.isEmpty {
                Text(observation.notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(width: width, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.property.address), \(criterion.displayName), \(status.displayName). \(observation?.notes ?? "")")
    }

    private func rentSummary(_ result: PropertyComparison) -> String {
        guard let difference = result.weeklyRentDifference else { return "Rent difference unavailable until both rents are supplied." }
        if difference == 0 { return "Both properties have the same weekly rent." }
        let amount = String(format: "$%.2f", abs(difference))
        return "Property \(difference < 0 ? "A" : "B") costs \(amount) less per week."
    }

    private func compare() {
        guard let firstID, let secondID else { return }
        viewModel.compareProperties(firstID: firstID, secondID: secondID)
    }

    private func refresh() {
        viewModel.loadRentalProperties()
        let ids = Set(viewModel.rentalProperties.map(\.id))
        if let id = firstID, !ids.contains(id) { firstID = nil }
        if let id = secondID, !ids.contains(id) { secondID = nil }
        if firstID != nil && secondID != nil { compare() } else { viewModel.clearComparison() }
    }
}
