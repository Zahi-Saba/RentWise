//
//  InspectionReportsView.swift
//  RentWise
//
//  Created by Bo Wen Chan on 27/10/2026.
//

import SwiftUI

struct InspectionReportsView: View {
    @ObservedObject var viewModel: InspectionReportsViewModel
    
    @ScaledMetric(relativeTo: .body)
    private var minimumButtonHeight: CGFloat = 44
    
    // Controls whether an error alert should be displayed
    private var showingError: Binding<Bool> {
        Binding(
            get: {viewModel.errorMessage != nil},
            set: { isPresented in
                if !isPresented {
                    viewModel.clearError()
                }
            }
        )
    }
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Property Condition Reports", systemImage: "doc.text")
                        .font(.title2.bold())
                        .foregroundStyle(Color.accentColor)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(
                        "Select a saved inspection to generate " +
                        "a PDF report containing property details, " +
                        "inspection observations, current room findings, defects and photos."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 8)
            }
            
            // Available inspections
            Section("Available Inspections") {
                if viewModel.reportOptions.isEmpty {
                    ContentUnavailableView("No inspections available",
                                           systemImage: "clipboard",
                                           description: Text(
                                            "Save a property and schedule an " +
                                            "inspection to get started."
                                           )
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    
                } else {
                    ForEach(viewModel.reportOptions) { option in
                        InspectionReportRow(option: option, isSelected: viewModel.selectedInspectionID == option.id
                        ) {
                            viewModel.selectedInspectionID = option.id
                        }
                    }
                }
            }
            
            if let selectedOption = viewModel.selectedOption {
                Section {
                    Text("These are the property's current room findings, not a historical snapshot of the selected inspection.")
                        .font(.footnote).foregroundStyle(.secondary)
                    if selectedOption.property.rooms.isEmpty {
                        Text("No room checklist recorded yet.").foregroundStyle(.secondary)
                    }
                    ForEach(selectedOption.property.rooms) { room in
                        RoomFindingsView(name: room.name, room: room)
                    }
                } header: { Text("Current room findings") }
            }

            // Generate report
            Section {
                // Generate PDF button
                Button {
                    viewModel.generateReport()
                } label: {
                    HStack(spacing: 12) {
                        if viewModel.isGenerating {
                            ProgressView()
                                .accessibilityHidden(true)
                        } else {
                            Image(systemName: "doc.badge.plus")
                                .accessibilityHidden(true)
                        }

                        Text(viewModel.isGenerating ? "Generating Report...": "Generate PDF Report")
                            .font(.headline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: minimumButtonHeight)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)
                .disabled(!viewModel.canGenerateReport)
                
                if let selectedOption = viewModel.selectedOption, !selectedOption.canGenerateReport {
                    Label(
                        "Record an observation, mark a room inspected or add a defect before generating a report.",
                        systemImage: "info.circle"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Reports")
        
        .onAppear {
            viewModel.loadReportOptions()
        }
        
        // Allows users to refresh their inspection list
        .refreshable {
            viewModel.loadReportOptions()
        }
        
        // PDF preview
        .sheet(item: $viewModel.generatedReport) { report in
            InspectionReportPDFPreview(url: report.url)
        }
        
        // Error handling
        .alert("Unable to Generate Report", isPresented: showingError) {
            Button("OK", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            Text(
                viewModel.errorMessage ??
                "An unexpected error occurred."
            )
        }
    }
}
