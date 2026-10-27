//
//  InspectionReportPDFRenderer.swift
//  RentWise
//
//  Created by Bo Wen Chan on 27/10/2026.
//

import Foundation
import UIKit

@MainActor
protocol InspectionReportPDFRendering {
    func render(_ report: InspectionConditionReport) throws -> URL
}

@MainActor
struct InspectionReportPDFRenderer: InspectionReportPDFRendering {
    func render(_ report: InspectionConditionReport) throws -> URL {
        // A4 paper size in PDF points
        let paper = CGRect(x: 0, y: 0, width: 595, height: 842)
        let margin: CGFloat = 48
        let usableWidth = paper.width - margin * 2
        let pageBottom = paper.height - 62

        // Fixed colours keep the printed report readable regardless of the app's Light/Dark Mode
        let ink = UIColor(red: 0.09, green: 0.16, blue: 0.23, alpha: 1)
        let secondaryInk = UIColor.darkGray
        let accent = UIColor(red: 0.02, green: 0.46, blue: 0.46, alpha: 1)

        let normalFont = UIFont.systemFont(ofSize: 11)
        let headingFont = UIFont.boldSystemFont(ofSize: 13)

        // Generate a unique temporary PDF file
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("RentWise-Condition-\(UUID().uuidString)").appendingPathExtension("pdf")
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: paper)
        try pdfRenderer.writePDF(to: fileURL) { context in
            var y: CGFloat = 0
            var pageNumber = 0

            // Page layout
            func newPage() {
                context.beginPage()
                pageNumber += 1
                y = margin

                let headerAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: accent]
                ("RENTWISE  /  CONDITION REPORT" as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttributes)

                // Header divider
                context.cgContext.setFillColor(accent.cgColor)
                context.cgContext.fill(
                    CGRect(
                        x: margin,
                        y: y + 27,
                        width: usableWidth,
                        height: 1
                    )
                )

                // Footer with page number
                let footerAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: secondaryInk]
                ("User-recorded observations  •  Page \(pageNumber)" as NSString).draw(at: CGPoint(x: margin, y: paper.height - 37), withAttributes: footerAttributes)
                y += 49
            }

            // Start another page when content reaches the footer
            func ensureSpace(_ height: CGFloat) {
                if y + height > pageBottom {
                    newPage()
                }
            }

            // Text wrapping
            func wrappedLines(_ text: String, font: UIFont, width: CGFloat) -> [String] {
                let attributes: [NSAttributedString.Key: Any] = [.font: font]
                func fits(_ candidate: String) -> Bool {
                    (candidate as NSString).size(withAttributes: attributes).width <= width
                }

                var lines: [String] = []

                for paragraph in text.components(separatedBy: .newlines) {
                    var current = ""

                    for part in paragraph.split(whereSeparator: { $0.isWhitespace }) {
                        let word = String(part)
                        let proposal = current.isEmpty ? word : current + " " + word

                        if fits(proposal) {
                            current = proposal
                            continue
                        }

                        if !current.isEmpty {
                            lines.append(current)
                            current = ""
                        }

                        // Handle unusually long unbroken text
                        for character in word {
                            let candidate = current + String(character)

                            if !fits(candidate) && !current.isEmpty {
                                lines.append(current)
                                current = ""
                            }

                            current.append(character)
                        }
                    }

                    lines.append(current)
                }

                return lines
            }

            // Drawing helper
            func write(_ text: String, font: UIFont? = nil, color: UIColor? = nil, indent: CGFloat = 0, gap: CGFloat = 6) {
                let drawingFont = font ?? normalFont
                let drawingColor = color ?? ink
                let attributes: [NSAttributedString.Key: Any] = [.font: drawingFont, .foregroundColor: drawingColor]
                let lineHeight = ceil(drawingFont.lineHeight + 3)

                // Wrap long text to fit inside the printable area
                for line in wrappedLines(text, font: drawingFont, width: usableWidth - indent) {
                    // Create another PDF page if necessary
                    ensureSpace(lineHeight)

                    if !line.isEmpty {
                        (line as NSString).draw(at: CGPoint(x: margin + indent, y: y), withAttributes: attributes)
                    }

                    y += lineHeight
                }

                // Add spacing after each text block
                y += gap
            }

            // Domain labels
            func criterionLabel(_ criterion: InspectionCriterion) -> String {
                switch criterion {
                case .noise: return "Noise"
                case .daylight: return "Daylight"
                case .storage: return "Storage"
                case .roomSpace: return "Room space"
                case .transport: return "Transport"
                }
            }

            func statusLabel(_ status: ObservationStatus) -> String {
                switch status {
                case .notChecked: return "Not checked"
                case .meetsNeeds: return "Meets needs"
                case .doesNotMeetNeeds: return "Does not meet needs"
                case .needsClarification: return "Needs clarification"
                }
            }

            // Generate report content
            newPage()
            write("Property condition report", font: UIFont.boldSystemFont(ofSize: 22), gap: 13)

            write(report.property.address, font: UIFont.boldSystemFont(ofSize: 16), gap: 10)

            write("Weekly rent: \(report.property.rentLabel)", color: secondaryInk)

            write("Inspection: \(report.inspection.startTime.formatted(date: .abbreviated, time: .shortened))", color: secondaryInk)

            write("Generated: \(report.generatedAt.formatted(date: .abbreviated, time: .shortened))", color: secondaryInk, gap: 20)

            write("INSPECTION FINDINGS", font: headingFont, color: accent, gap: 12)

            // Include all inspection criteria, even if not recorded
            for criterion in InspectionCriterion.allCases {
                let findings = report.observations.filter {$0.criterion == criterion}

                // Keep the heading with its first details
                ensureSpace(55)

                write(criterionLabel(criterion), font: headingFont, gap: 2)

                if findings.isEmpty {
                    write("Status: Not recorded", color: secondaryInk, indent: 12, gap: 12)
                    
                    continue
                }

                for finding in findings {
                    write("Status: \(statusLabel(finding.status))", color: secondaryInk, indent: 12, gap: 3)

                    let notes = finding.notes.trimmingCharacters(in: .whitespacesAndNewlines)

                    write("Notes: \(notes.isEmpty ? "No notes recorded" : notes)", indent: 12, gap: 12)
                }
            }

            // Important disclaimer
            ensureSpace(50)

            write("IMPORTANT", font: headingFont, color: accent)

            write(
                "This report contains observations entered by the renter. " +
                "It is not a professional building inspection or an official " +
                "entry condition report.",
                color: secondaryInk
            )
        }

        return fileURL
    }
}
