//
//  InspectionReportsView.swift
//  RentWise
//
//  Created by Bo Wen Chan on 27/10/2026.
//

import SwiftUI

struct InspectionReportsView: View {
    @ObservedObject var viewModel: InspectionReportsViewModel
    
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
                        .foregroundStyle(.teal)
                    
                    Text(
                        "Select a saved inspection to generate " +
                        "a PDF report containing property details, " +
                        "inspection findings and notes."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            // Available inspections
            Section("Available Inspections") {
                if viewModel.reportOptions.isEmpty {
                    ContentUnavailableView("No inspections available", systemImage: "clipboard",
                                           description: Text(
                                            "Save a property and schedule an " +
                                            "inspection to get started."
                                           )
                    )
                } else {
                    ForEach(viewModel.reportOptions) { option in
                        InspectionReportRow(option: option, isSelected: viewModel.selectedInspectionID == option.id
                        ) {
                            viewModel.selectedInspectionID = option.id
                        }
                    }
                }
            }
            
            // Generate report
            Section {
                Button {
                    viewModel.generateReport()
                } label: {
                    HStack(spacing: 10) {
                        
                        Spacer()
                        
                        if viewModel.isGenerating {
                            ProgressView()
                        } else {
                            Image(systemName: "doc.badge.plus")
                        }
                        
                        Text(
                            viewModel.isGenerating
                            ? "Generating Report..."
                            : "Generate PDF Report"
                        )
                        .font(.headline)
                        
                        Spacer()
                    }
                    .frame(minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .disabled(!viewModel.canGenerateReport)
                
                if let selectedOption = viewModel.selectedOption, !selectedOption.canGenerateReport {
                    Label(
                        "Record at least one inspection " +
                        "observation before generating a report.",
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
            InspectionReportPDFPreview(
                url: report.url
            )
        }
        
        // Error handling
        .alert(
            "Unable to Generate Report",
            isPresented: showingError
        ) {
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
