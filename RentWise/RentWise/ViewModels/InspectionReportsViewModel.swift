//
//  InspectionReportsViewModel.swift
//  RentWise
//
//  Created by Bo Wen Chan on 27/10/2026.
//

import Foundation
import Combine

struct GeneratedConditionReport: Identifiable {
    let id = UUID()
    let url: URL
}

@MainActor
final class InspectionReportsViewModel: ObservableObject {
    @Published private(set) var reportOptions: [InspectionReportOption] = []
    @Published var selectedInspectionID: UUID?
    @Published var generatedReport: GeneratedConditionReport?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isGenerating = false

    //Returns the inspection currently selected by the user
    var selectedOption: InspectionReportOption? {
        guard let selectedInspectionID else {
            return nil
        }
        return reportOptions.first {$0.id == selectedInspectionID}
    }
    
    // Determines whether the selected inspection is ready for report generation
    var canGenerateReport: Bool {selectedOption?.canGenerateReport == true && !isGenerating}

    private let listReportsUseCase: ListInspectionReportOptionsUseCase
    private let createReportUseCase: CreateInspectionConditionReportUseCase
    private let pdfRenderer: any InspectionReportPDFRendering

    init(repository: RentalPropertyRepository, pdfRenderer: (any InspectionReportPDFRendering)? = nil) {
        self.listReportsUseCase = ListInspectionReportOptionsUseCase(repository: repository)
        self.createReportUseCase = CreateInspectionConditionReportUseCase(repository: repository)
        self.pdfRenderer = pdfRenderer ?? InspectionReportPDFRenderer()
    }

    // Load available inspections
    func loadReportOptions() {
        do {
            reportOptions = try listReportsUseCase.execute()

            // Preserve the previous selection if it still exists
            if let selectedInspectionID, reportOptions.contains(where: {$0.id == selectedInspectionID}) {
                // Keep the current selection
            } else {
                // Otherwise select the first inspection with findings
                selectedInspectionID = reportOptions.first(where: { $0.canGenerateReport })?.id
            }

            errorMessage = nil

        } catch {
            reportOptions = []
            selectedInspectionID = nil
            errorMessage = "Unable to load inspections. Please try again."
        }
    }

    // Generate PDF
    func generateReport() {
        // Ensure the user has selected an inspection
        guard let selectedInspectionID else {
            errorMessage = "Please select an inspection."
            return
        }

        // Find its associated property and recorded findings
        guard let option = reportOptions.first(where: {$0.id == selectedInspectionID}) else {
            errorMessage = "The selected inspection is unavailable."
            return
        }

        guard option.canGenerateReport else {
            errorMessage = "Record at least one inspection observation before generating a report."
            return
        }

        isGenerating = true
        errorMessage = nil

        defer {
            isGenerating = false
        }

        do {
            // Validate and prepare the report data
            let report = try createReportUseCase.execute(propertyID: option.property.id, inspectionID: option.inspection.id)

            // Convert the report into a PDF file
            let pdfURL = try pdfRenderer.render(report)

            // Store the result for the SwiftUI preview
            generatedReport = GeneratedConditionReport(url: pdfURL)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Error handling
    func clearError() {
        errorMessage = nil
    }
}

