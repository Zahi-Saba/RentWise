//
//  PDFDocumentView.swift
//  RentWise
//
//  Created by Bo Wen Chan on 28/10/2026.
//

import SwiftUI
import PDFKit

struct PDFDocumentView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()

        // Scale pages to fit the available display
        pdfView.autoScales = true

        // Enable continuous scrolling between PDF pages
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical

        // Add visible separation between PDF pages
        pdfView.displaysPageBreaks = true

        // Follow the system appearance
        pdfView.backgroundColor = .systemGroupedBackground

        // Load the document
        pdfView.document = PDFDocument(url: url)

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        // Reload only when the displayed document changes
        guard uiView.document?.documentURL != url else {
            return
        }

        uiView.document = PDFDocument(url: url)
    }
}

