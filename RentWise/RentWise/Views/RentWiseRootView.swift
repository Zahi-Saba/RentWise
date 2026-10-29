import SwiftUI

struct RentWiseRootView: View {
    @ObservedObject var viewModel: RentWiseViewModel
    @ObservedObject var reportsViewModel: InspectionReportsViewModel
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        TabView {
            NavigationStack { RentalPropertyListView(viewModel: viewModel) }
                .tabItem { Label("Shortlist", systemImage: "house.fill") }
            NavigationStack { Color(uiColor: .systemGroupedBackground).ignoresSafeArea().navigationTitle("Map") }
                .tabItem { Label("Map", systemImage: "map") }
            NavigationStack { PropertyComparisonView(viewModel: viewModel) }
                .tabItem { Label("Compare", systemImage: "rectangle.split.2x1") }
            NavigationStack { InspectionReportsView(viewModel: reportsViewModel)}
                .tabItem { Label("Reports", systemImage: "doc.text")}}
        .tint(Color.accentColor)
        .task { await viewModel.refreshShortlist() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await viewModel.refreshShortlist() } }
        }
    }
}
