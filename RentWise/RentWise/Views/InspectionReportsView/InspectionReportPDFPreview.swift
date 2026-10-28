//
//  InspectionReportPDFPreview.swift
//  RentWise
//
//  Created by Bo Wen Chan on 27/10/2026.
//

import SwiftUI
import PDFKit

struct InspectionReportPDFPreview: View {
    // URL returned by InspectionReportPDFRenderer
    let url: URL

    // Allows the user to close the preview
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            // PDFKit handles PDF rendering, scrolling and zooming.
            PDFDocumentView(url: url)
                .navigationTitle("Condition Report")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}
