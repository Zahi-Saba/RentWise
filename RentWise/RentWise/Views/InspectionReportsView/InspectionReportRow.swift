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
        .accessibilityLabel(
            "\(option.property.address), " +
            "\(option.inspection.startTime.formatted()), " +
            "\(option.observationCount) recorded observations"
        )
        .accessibilityValue(
            isSelected ? "Selected" : "Not selected"
        )
        .accessibilityHint("Double tap to select this inspection")
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
                    "\(option.observationCount) recorded observations",
                    systemImage: "checkmark.circle"
                )
                .font(.caption)
                .foregroundStyle(.green)
                .fixedSize(horizontal: false, vertical: true)
            } else {
                Label("No recorded observations", systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

