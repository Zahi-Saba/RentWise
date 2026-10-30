//
//  InspectionReportRow.swift
//  RentWise
//
//  Created by Bo Wen Chan on 27/10/2026.
//

import SwiftUI

struct InspectionReportRow: View {
    let option: InspectionReportOption
    let isSelected: Bool
    let onSelect: () -> Void
    
    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    var body: some View {
        Button(action: onSelect) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 12) {

                        propertyDetails

                        Label(
                            isSelected ? "Selected" : "Not selected",
                            systemImage: isSelected ? "checkmark.circle.fill": "circle"
                        )
                        .font(.subheadline)
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    }
                } else {
                    HStack(spacing: 12) {

                        propertyDetails

                        Spacer(minLength: 8)

                        Image(systemName: isSelected ? "checkmark.circle.fill": "circle")
                            .font(.title2)
                            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        // VoiceOver treats the row as one accessible element
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint(option.canGenerateReport ? "Selects this inspection for PDF generation." : "Selects this inspection. Record an observation or room finding before generating a report.")
    }
    
    private var propertyDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Property address
            Text(option.property.address)
                .font(.headline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Inspection date and time
            Text(option.inspection.startTime.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Observation availability
            if option.canGenerateReport {
                Label(
                    option.findingsLabel,
                    systemImage: "checkmark.circle"
                )
                .font(.caption)
                .foregroundStyle(.green)
                .fixedSize(horizontal: false, vertical: true)
            } else {
                Label("No recorded findings", systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private var accessibilitySummary: String {
        let date = option.inspection.startTime.formatted(date: .abbreviated, time: .shortened)

        let availability: String

        if option.canGenerateReport {
            availability = option.findingsLabel
        } else {
            availability = "No recorded findings. Report unavailable."
        }

        return "\(option.property.address). " + "Inspection on \(date). " + availability
    }

}

