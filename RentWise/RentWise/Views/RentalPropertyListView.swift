import SwiftUI

struct RentalPropertyListView: View {
    @ObservedObject var viewModel: RentWiseViewModel
    @AppStorage("appAppearance") private var appearance = "System"
    @Environment(\.colorScheme) private var colorScheme
    @State private var showImport = false
    var body: some View {
        List {
            Section {
                Text("Find your next place").font(.title2.bold())
                Text("Share a listing from Safari to Rentwise, then return here to find it in your shortlist.").foregroundStyle(.secondary)
                Button { showImport = true } label: {
                    Label("Import listing URL", systemImage: "square.and.arrow.down")
                }
                .accessibilityHint("Opens a form to add a rental listing from its web address.")
            }
            if viewModel.isImportingListings {
                Section { ProgressView("Importing shared listings…") }
            }
            if !viewModel.importMessage.isEmpty {
                Section { Text(viewModel.importMessage).foregroundStyle(.red) }
            }
            if !viewModel.inspections.isEmpty {
                Section("Upcoming inspections") {
                    ForEach(viewModel.inspections) { inspection in
                        if let property = viewModel.rentalProperties.first(where: { $0.id == inspection.rentalPropertyID }) {
                            NavigationLink { RentalPropertyDetailView(viewModel: viewModel, property: property) } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(property.address).font(.headline)
                                    Text(inspection.startTime.formatted()).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .accessibilityLabel("Upcoming inspection at \(property.address), " + "\(inspection.startTime.formatted(date: .abbreviated, time: .shortened))")
                            .accessibilityHint("Opens the property details and inspection options.")
                        }
                    }
                }
            }
            Section("Your shortlist • \(viewModel.rentalProperties.count)") {
                if viewModel.rentalProperties.isEmpty {
                    ContentUnavailableView("No saved properties", systemImage: "house", description: Text("Share a listing or import its URL to get started."))
                }
                ForEach(viewModel.rentalProperties) { property in
                    NavigationLink { RentalPropertyDetailView(viewModel: viewModel, property: property) } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            if let source = property.sourceURL, let url = URL(string: source) {
                                ListingLinkPreview(url: url, service: viewModel.listingPreviewService)
                            }
                            Label("Saved listing", systemImage: "house.fill").font(.caption).foregroundStyle(Color.accentColor)
                            Text(property.address).font(.headline)
                            Text(property.rentLabel).font(.subheadline)
                        }.padding(.vertical, 8)
                    }
                    .accessibilityLabel("\(property.address). \(property.rentLabel). Saved property.")
                    .accessibilityHint("Opens property details and inspection history.")
                    .swipeActions { Button("Delete", role: .destructive) { viewModel.deleteRentalProperty(property) } }
                }
            }
            if !viewModel.errorMessage.isEmpty { Text(viewModel.errorMessage).foregroundStyle(.red) }
            Section {
                HStack {
                    Spacer()
                    Button {
                        appearance = colorScheme == .dark ? "Light" : "Dark"
                    } label: {
                        Image(systemName: colorScheme == .dark ? "sun.max.fill" : "moon.fill")
                            .font(.title2)
                            .frame(width: 48, height: 48)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.teal)
                    .accessibilityLabel(colorScheme == .dark ? "Switch to light mode" : "Switch to dark mode")
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .navigationTitle("Rentwise")
        .sheet(isPresented: $showImport) { ImportListingView(viewModel: viewModel) }
        .refreshable { await viewModel.retrySharedImports() }
    }
}

struct ImportListingView: View {
    @ObservedObject var viewModel: RentWiseViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var link = ""
    @State private var isSaving = false
    var body: some View {
        NavigationStack {
            Form {
                TextField("https://…", text: $link).keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled().accessibilityLabel("Listing URL")
                Button("Save to Shortlist") {
                    isSaving = true
                    Task { @MainActor in
                        let saved = await viewModel.importListingURL(link)
                        isSaving = false
                        if saved { dismiss() }
                    }
                }.disabled(isSaving || link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if isSaving { ProgressView("Importing listing…") }
                if !viewModel.importMessage.isEmpty { Text(viewModel.importMessage).foregroundStyle(.red) }
            }
            .navigationTitle("Import listing")
            .toolbar { Button("Cancel") { dismiss() }.disabled(isSaving) }
            .interactiveDismissDisabled(isSaving)
        }
    }
}
