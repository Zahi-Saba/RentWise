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

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(option.property.address)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(
                        option.inspection.startTime.formatted(date: .abbreviated, time: .shortened)
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    if option.canGenerateReport {
                        Label(
                            "\(option.observationCount) recorded observations",
                            systemImage: "checkmark.circle"
                        )
                        .font(.caption)
                        .foregroundStyle(.green)

                    } else {
                        Label("No recorded observations", systemImage: "exclamationmark.circle"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 8)

                Image(
                    systemName: isSelected ? "checkmark.circle.fill": "circle"
                )
                .font(.title2)
                .foregroundStyle(isSelected ? Color.teal : Color.secondary)
            }
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
}

